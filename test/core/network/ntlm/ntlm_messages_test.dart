import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:httpbot_api/core/network/ntlm/md4.dart';
import 'package:httpbot_api/core/network/ntlm/ntlm_messages.dart';

void main() {
  group('MD4', () {
    test('hashes the empty string to the known RFC 1320 vector', () {
      final digest = md4(const <int>[]);
      final hex =
          digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      expect(hex, '31d6cfe0d16ae931b73c59d7e0c089c0');
    });

    test('hashes "abc" to the known RFC 1320 vector', () {
      final digest = md4('abc'.codeUnits);
      final hex =
          digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      expect(hex, 'a448017aaf21d8525fc10ae87aa6729d');
    });
  });

  group('NTLM Type-1', () {
    test('starts with the NTLMSSP signature and message type 1', () {
      final type1 = createType1Message();
      final bytes = base64Decode(type1);
      expect(utf8.decode(bytes.sublist(0, 7)), 'NTLMSSP');
      expect(bytes[8], 1);
      expect(bytes[9], 0);
      expect(bytes[10], 0);
      expect(bytes[11], 0);
    });
  });

  group('NTLM Type-2 parsing', () {
    test('extracts the 8-byte server challenge and target info', () {
      final parsed = parseType2Message(_minimalType2());
      expect(parsed.serverChallenge, Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]));
      expect(parsed.targetInfo, isEmpty);
    });
  });

  group('NTLM Type-3', () {
    test('produces a base64 message with the NTLMSSP signature and type 3', () {
      final type3 = createType3Message(
        type2: parseType2Message(_minimalType2()),
        username: 'user',
        password: 'SecRET01',
        domain: 'DOMAIN',
        workstation: 'WORKSTATION',
      );
      final bytes = base64Decode(type3);
      expect(utf8.decode(bytes.sublist(0, 7)), 'NTLMSSP');
      expect(bytes[8], 3);
      // NtChallengeResponse length is the security buffer at offset 20 (uint16 LE).
      final ntLen = bytes[20] | (bytes[21] << 8);
      expect(ntLen, greaterThan(24));
      // lmResponse is empty, so the NT response starts right after the 64-byte fixed header.
      final ntOffset =
          bytes[24] | (bytes[25] << 8) | (bytes[26] << 16) | (bytes[27] << 24);
      expect(ntOffset, 64);
    });
  });
}

List<int> _uint16le(int value) => [value & 0xFF, (value >> 8) & 0xFF];
List<int> _uint32le(int value) =>
    [value & 0xFF, (value >> 8) & 0xFF, (value >> 16) & 0xFF, (value >> 24) & 0xFF];

String _minimalType2() {
  final builder = BytesBuilder();
  builder.add(utf8.encode('NTLMSSP'));
  builder.addByte(0); // 8-byte signature
  builder.add(_uint32le(2)); // message type 2
  builder.add(_uint16le(0)); // target name len
  builder.add(_uint16le(0)); // target name max len
  builder.add(_uint32le(48)); // target name offset
  builder.add(_uint32le(0)); // flags  (offset 20)
  builder.add([1, 2, 3, 4, 5, 6, 7, 8]); // server challenge (offset 24)
  builder.add(_uint32le(0)); // reserved
  builder.add(_uint32le(0)); // reserved
  builder.add(_uint16le(0)); // target info len
  builder.add(_uint16le(0)); // target info max len
  builder.add(_uint32le(48)); // target info offset
  return base64Encode(builder.toBytes());
}
