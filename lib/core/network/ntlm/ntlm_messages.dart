import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'md4.dart';

const String _ntlmSignature = 'NTLMSSP\x00';

const int _negotiateFlags = 0x00000001 | // Unicode
    0x00000002 | // OEM
    0x00000004 | // Request Target
    0x00000200 | // NTLM
    0x00008000 | // Always Sign
    0x00080000 | // Extended Session Security
    0x20000000 | // 128-bit encryption (NTLMSSP_NEGOTIATE_128)
    0x80000000; // 56-bit encryption (NTLMSSP_NEGOTIATE_56)

/// Parsed fields from a server Type-2 (challenge) message.
class NtlmType2Message {
  const NtlmType2Message({
    required this.serverChallenge,
    required this.targetInfo,
    required this.flags,
  });

  final Uint8List serverChallenge; // 8 bytes
  final Uint8List targetInfo;
  final int flags;
}

/// Builds the base64 NTLM Type-1 (negotiate) token.
String createType1Message() {
  final builder = BytesBuilder();
  builder.add(ascii.encode(_ntlmSignature));
  builder.add(_uint32le(1));
  builder.add(_uint32le(_negotiateFlags));
  builder.add(_securityBufferRef(0, 32)); // domain (empty)
  builder.add(_securityBufferRef(0, 32)); // workstation (empty)
  return base64Encode(builder.toBytes());
}

/// Parses a base64 NTLM Type-2 (challenge) token from `WWW-Authenticate`.
NtlmType2Message parseType2Message(String token) {
  final bytes = Uint8List.fromList(base64Decode(token.trim()));
  final flags = _readUint32le(bytes, 20);
  final serverChallenge = Uint8List.fromList(bytes.sublist(24, 32));

  Uint8List targetInfo = Uint8List(0);
  if (bytes.length >= 48) {
    final targetInfoLen = _readUint16le(bytes, 40);
    final targetInfoOffset = _readUint32le(bytes, 44);
    if (targetInfoLen > 0 &&
        targetInfoOffset + targetInfoLen <= bytes.length) {
      targetInfo = Uint8List.fromList(
        bytes.sublist(targetInfoOffset, targetInfoOffset + targetInfoLen),
      );
    }
  }

  return NtlmType2Message(
    serverChallenge: serverChallenge,
    targetInfo: targetInfo,
    flags: flags,
  );
}

/// Builds the base64 NTLM Type-3 (authenticate) token using an NTLMv2 response.
String createType3Message({
  required NtlmType2Message type2,
  required String username,
  required String password,
  String domain = '',
  String workstation = '',
}) {
  final ntlmV2Hash = _ntlmV2Hash(
    password: password,
    username: username,
    domain: domain,
  );

  final clientChallenge = _randomBytes(8);
  final timestamp = _windowsTimestamp();

  final blob = BytesBuilder()
    ..add([0x01, 0x01, 0x00, 0x00])
    ..add([0x00, 0x00, 0x00, 0x00])
    ..add(timestamp)
    ..add(clientChallenge)
    ..add([0x00, 0x00, 0x00, 0x00])
    ..add(type2.targetInfo)
    ..add([0x00, 0x00, 0x00, 0x00]);
  final blobBytes = blob.toBytes();

  final proofInput = BytesBuilder()
    ..add(type2.serverChallenge)
    ..add(blobBytes);
  final ntProof = Hmac(md5, ntlmV2Hash).convert(proofInput.toBytes()).bytes;

  final ntResponse = (BytesBuilder()
        ..add(ntProof)
        ..add(blobBytes))
      .toBytes();

  final domainBytes = _toUnicode(domain);
  final userBytes = _toUnicode(username);
  final workstationBytes = _toUnicode(workstation);
  const lmResponse = <int>[];
  const sessionKey = <int>[];

  var offset = 64;
  final lmOffset = offset;
  offset += lmResponse.length;
  final ntOffset = offset;
  offset += ntResponse.length;
  final domainOffset = offset;
  offset += domainBytes.length;
  final userOffset = offset;
  offset += userBytes.length;
  final workstationOffset = offset;
  offset += workstationBytes.length;
  final sessionKeyOffset = offset;

  final builder = BytesBuilder()
    ..add(ascii.encode(_ntlmSignature))
    ..add(_uint32le(3))
    ..add(_securityBufferRef(lmResponse.length, lmOffset))
    ..add(_securityBufferRef(ntResponse.length, ntOffset))
    ..add(_securityBufferRef(domainBytes.length, domainOffset))
    ..add(_securityBufferRef(userBytes.length, userOffset))
    ..add(_securityBufferRef(workstationBytes.length, workstationOffset))
    ..add(_securityBufferRef(sessionKey.length, sessionKeyOffset))
    ..add(_uint32le(type2.flags))
    ..add(lmResponse)
    ..add(ntResponse)
    ..add(domainBytes)
    ..add(userBytes)
    ..add(workstationBytes)
    ..add(sessionKey);

  return base64Encode(builder.toBytes());
}

List<int> _ntlmV2Hash({
  required String password,
  required String username,
  required String domain,
}) {
  final ntlmHash = md4(_toUnicode(password)); // NTLM hash = MD4(UTF-16LE password)
  final identity = _toUnicode(username.toUpperCase() + domain);
  return Hmac(md5, ntlmHash).convert(identity).bytes;
}

List<int> _toUnicode(String value) {
  final bytes = <int>[];
  for (final unit in value.codeUnits) {
    bytes.add(unit & 0xFF);
    bytes.add((unit >> 8) & 0xFF);
  }
  return bytes;
}

List<int> _securityBufferRef(int length, int offset) => [
      ..._uint16le(length),
      ..._uint16le(length),
      ..._uint32le(offset),
    ];

List<int> _uint16le(int value) => [value & 0xFF, (value >> 8) & 0xFF];

List<int> _uint32le(int value) => [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];

int _readUint16le(Uint8List bytes, int offset) =>
    bytes[offset] | (bytes[offset + 1] << 8);

int _readUint32le(Uint8List bytes, int offset) =>
    (bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24)) &
    0xFFFFFFFF;

Uint8List _randomBytes(int length) {
  final random = Random.secure();
  return Uint8List.fromList(
    List<int>.generate(length, (_) => random.nextInt(256)),
  );
}

/// Windows FILETIME: 100-ns intervals since 1601-01-01, little-endian 8 bytes.
List<int> _windowsTimestamp() {
  final epochOffset = BigInt.from(11644473600) * BigInt.from(10000000);
  final nowMs = BigInt.from(DateTime.now().toUtc().millisecondsSinceEpoch);
  final filetime = nowMs * BigInt.from(10000) + epochOffset;
  final bytes = <int>[];
  var value = filetime;
  final mask = BigInt.from(0xFF);
  for (var i = 0; i < 8; i++) {
    bytes.add((value & mask).toInt());
    value = value >> 8;
  }
  return bytes;
}
