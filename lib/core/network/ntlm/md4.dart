import 'dart:typed_data';

/// Computes the MD4 digest (RFC 1320) of [input].
/// Returns exactly 16 bytes.
List<int> md4(List<int> input) {
  var a = 0x67452301;
  var b = 0xefcdab89;
  var c = 0x98badcfe;
  var d = 0x10325476;

  final message = _pad(input);
  for (var i = 0; i < message.length; i += 64) {
    final x = List<int>.generate(
      16,
      (j) =>
          message[i + j * 4] |
          (message[i + j * 4 + 1] << 8) |
          (message[i + j * 4 + 2] << 16) |
          (message[i + j * 4 + 3] << 24),
    );

    final aa = a, bb = b, cc = c, dd = d;

    int f(int x, int y, int z) => (x & y) | (~x & z);
    int g(int x, int y, int z) => (x & y) | (x & z) | (y & z);
    int h(int x, int y, int z) => x ^ y ^ z;
    int rotl(int v, int s) =>
        ((v << s) | ((v & 0xFFFFFFFF) >> (32 - s))) & 0xFFFFFFFF;

    int round1(int p, int q, int r, int s, int k, int shift) =>
        rotl((p + f(q, r, s) + x[k]) & 0xFFFFFFFF, shift);
    int round2(int p, int q, int r, int s, int k, int shift) =>
        rotl((p + g(q, r, s) + x[k] + 0x5a827999) & 0xFFFFFFFF, shift);
    int round3(int p, int q, int r, int s, int k, int shift) =>
        rotl((p + h(q, r, s) + x[k] + 0x6ed9eba1) & 0xFFFFFFFF, shift);

    for (final k in const [0, 4, 8, 12]) {
      a = round1(a, b, c, d, k, 3);
      d = round1(d, a, b, c, k + 1, 7);
      c = round1(c, d, a, b, k + 2, 11);
      b = round1(b, c, d, a, k + 3, 19);
    }
    for (final k in const [0, 1, 2, 3]) {
      a = round2(a, b, c, d, k, 3);
      d = round2(d, a, b, c, k + 4, 5);
      c = round2(c, d, a, b, k + 8, 9);
      b = round2(b, c, d, a, k + 12, 13);
    }
    for (final k in const [0, 2, 1, 3]) {
      a = round3(a, b, c, d, k, 3);
      d = round3(d, a, b, c, k + 8, 9);
      c = round3(c, d, a, b, k + 4, 11);
      b = round3(b, c, d, a, k + 12, 15);
    }

    a = (a + aa) & 0xFFFFFFFF;
    b = (b + bb) & 0xFFFFFFFF;
    c = (c + cc) & 0xFFFFFFFF;
    d = (d + dd) & 0xFFFFFFFF;
  }

  final out = Uint8List(16);
  final words = [a, b, c, d];
  for (var i = 0; i < 4; i++) {
    final word = words[i];
    out[i * 4] = word & 0xFF;
    out[i * 4 + 1] = (word >> 8) & 0xFF;
    out[i * 4 + 2] = (word >> 16) & 0xFF;
    out[i * 4 + 3] = (word >> 24) & 0xFF;
  }
  return out;
}

Uint8List _pad(List<int> input) {
  final bitLength = input.length * 8;
  final padded = <int>[...input, 0x80];
  while (padded.length % 64 != 56) {
    padded.add(0);
  }
  for (var i = 0; i < 8; i++) {
    padded.add((bitLength >> (8 * i)) & 0xFF);
  }
  return Uint8List.fromList(padded);
}
