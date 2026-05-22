import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class ChecksumValidator {
  static String calculateSHA256(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static String calculateSHA256FromBytes(Uint8List bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool verify(String content, String expectedChecksum) {
    final actualChecksum = calculateSHA256(content);
    return actualChecksum.toLowerCase() == expectedChecksum.toLowerCase();
  }

  static bool verifyBytes(Uint8List bytes, String expectedChecksum) {
    final actualChecksum = calculateSHA256FromBytes(bytes);
    return actualChecksum.toLowerCase() == expectedChecksum.toLowerCase();
  }
}
