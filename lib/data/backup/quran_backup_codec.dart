import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../../domain/models/bookmark.dart';
import '../../domain/models/reading_position.dart';

const _backupAppId = 'holy_quran_app';
const _backupEnvelopeVersion = 1;
const _backupPayloadVersion = 1;
const _kdfIterations = 210000;

class QuranBackupData {
  final List<Bookmark> bookmarks;
  final ReadingPosition? lastRead;
  final DateTime exportedAt;

  const QuranBackupData({
    required this.bookmarks,
    required this.lastRead,
    required this.exportedAt,
  });
}

class QuranBackupCodec {
  final Random _random;
  final Cipher _cipher;
  final Pbkdf2 _kdf;

  QuranBackupCodec({Random? random, Cipher? cipher, Pbkdf2? kdf})
    : _random = random ?? Random.secure(),
      _cipher = cipher ?? AesGcm.with256bits(),
      _kdf =
          kdf ??
          Pbkdf2(
            macAlgorithm: Hmac.sha256(),
            iterations: _kdfIterations,
            bits: 256,
          );

  Future<List<int>> encode(QuranBackupData data, String passphrase) async {
    _validatePassphrase(passphrase);
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final key = await _deriveKey(passphrase, salt);
    final payload = utf8.encode(jsonEncode(_payloadToJson(data)));
    final box = await _cipher.encrypt(payload, secretKey: key, nonce: nonce);

    return utf8.encode(
      jsonEncode({
        'app': _backupAppId,
        'version': _backupEnvelopeVersion,
        'kdf': {
          'algorithm': 'pbkdf2-hmac-sha256',
          'iterations': _kdfIterations,
          'salt': base64Encode(salt),
        },
        'cipher': {
          'algorithm': 'aes-256-gcm',
          'nonce': base64Encode(box.nonce),
          'cipherText': base64Encode(box.cipherText),
          'mac': base64Encode(box.mac.bytes),
        },
      }),
    );
  }

  Future<QuranBackupData> decode(List<int> bytes, String passphrase) async {
    _validatePassphrase(passphrase);
    final envelope = _asJsonObject(utf8.decode(bytes), 'backup file');
    _expect(envelope['app'] == _backupAppId, 'Unsupported backup file.');
    _expect(
      envelope['version'] == _backupEnvelopeVersion,
      'Unsupported backup version.',
    );

    final kdf = _asMap(envelope['kdf'], 'kdf');
    _expect(
      kdf['algorithm'] == 'pbkdf2-hmac-sha256',
      'Unsupported backup key format.',
    );
    _expect(kdf['iterations'] == _kdfIterations, 'Unsupported backup key.');

    final cipher = _asMap(envelope['cipher'], 'cipher');
    _expect(
      cipher['algorithm'] == 'aes-256-gcm',
      'Unsupported backup encryption.',
    );

    final salt = _base64Bytes(kdf['salt'], 'salt');
    final nonce = _base64Bytes(cipher['nonce'], 'nonce');
    final cipherText = _base64Bytes(cipher['cipherText'], 'cipherText');
    final mac = _base64Bytes(cipher['mac'], 'mac');
    final key = await _deriveKey(passphrase, salt);

    final clearBytes = await _cipher.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
      secretKey: key,
    );
    return _payloadFromJson(_asJsonObject(utf8.decode(clearBytes), 'payload'));
  }

  Future<SecretKey> _deriveKey(String passphrase, List<int> salt) {
    return _kdf.deriveKeyFromPassword(password: passphrase, nonce: salt);
  }

  List<int> _randomBytes(int length) =>
      List<int>.generate(length, (_) => _random.nextInt(256));

  Map<String, Object?> _payloadToJson(QuranBackupData data) {
    return {
      'app': _backupAppId,
      'schemaVersion': _backupPayloadVersion,
      'exportedAt': data.exportedAt.toUtc().toIso8601String(),
      'bookmarks': data.bookmarks.map(_bookmarkToJson).toList(),
      'lastRead': data.lastRead == null
          ? null
          : {
              'verseId': data.lastRead!.verseId,
              'lastReadAt': data.lastRead!.lastReadAt.toUtc().toIso8601String(),
            },
    };
  }

  QuranBackupData _payloadFromJson(Map<String, Object?> json) {
    _expect(json['app'] == _backupAppId, 'Invalid backup payload.');
    _expect(
      json['schemaVersion'] == _backupPayloadVersion,
      'Unsupported payload version.',
    );
    final exportedAt = _dateTime(json['exportedAt'], 'exportedAt');
    final bookmarkItems = _asList(json['bookmarks'], 'bookmarks');
    final bookmarks = bookmarkItems
        .map((item) => _bookmarkFromJson(_asMap(item, 'bookmark')))
        .toList();

    final lastReadJson = json['lastRead'];
    ReadingPosition? lastRead;
    if (lastReadJson != null) {
      final map = _asMap(lastReadJson, 'lastRead');
      lastRead = ReadingPosition(
        verseId: _verseId(map['verseId'], 'lastRead.verseId'),
        lastReadAt: _dateTime(map['lastReadAt'], 'lastRead.lastReadAt'),
      );
    }

    return QuranBackupData(
      bookmarks: bookmarks,
      lastRead: lastRead,
      exportedAt: exportedAt,
    );
  }

  Map<String, Object?> _bookmarkToJson(Bookmark bookmark) {
    return {
      'verseId': bookmark.verseId,
      'timestamp': bookmark.timestamp.toUtc().toIso8601String(),
      'note': bookmark.note,
    };
  }

  Bookmark _bookmarkFromJson(Map<String, Object?> json) {
    final note = json['note'];
    _expect(note == null || note is String, 'Invalid bookmark note.');
    return Bookmark(
      verseId: _verseId(json['verseId'], 'bookmark.verseId'),
      timestamp: _dateTime(json['timestamp'], 'bookmark.timestamp'),
      note: note as String?,
    );
  }

  Map<String, Object?> _asJsonObject(String input, String label) {
    final decoded = jsonDecode(input);
    return _asMap(decoded, label);
  }

  Map<String, Object?> _asMap(Object? value, String label) {
    _expect(value is Map, 'Invalid $label.');
    return (value as Map).cast<String, Object?>();
  }

  List<Object?> _asList(Object? value, String label) {
    _expect(value is List, 'Invalid $label.');
    return (value as List).cast<Object?>();
  }

  List<int> _base64Bytes(Object? value, String label) {
    _expect(value is String, 'Invalid $label.');
    return base64Decode(value as String);
  }

  DateTime _dateTime(Object? value, String label) {
    _expect(value is String, 'Invalid $label.');
    final parsed = DateTime.tryParse(value as String);
    _expect(parsed != null, 'Invalid $label.');
    return parsed!.toUtc();
  }

  String _verseId(Object? value, String label) {
    _expect(value is String, 'Invalid $label.');
    final verseId = value as String;
    _expect(
      RegExp(r'^[1-9]\d{0,2}:[1-9]\d{0,2}$').hasMatch(verseId),
      'Invalid $label.',
    );
    return verseId;
  }

  void _validatePassphrase(String passphrase) {
    _expect(passphrase.trim().isNotEmpty, 'Backup passphrase is required.');
  }

  void _expect(bool condition, String message) {
    if (!condition) {
      throw FormatException(message);
    }
  }
}
