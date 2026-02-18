import 'dart:math';
import 'dart:typed_data';

Future<Uint8List> secureRandomBytes(int length) async {
  final rng = Random.secure();
  final out = Uint8List(length);
  for (var i = 0; i < length; i++) {
    out[i] = rng.nextInt(256);
  }
  return out;
}
