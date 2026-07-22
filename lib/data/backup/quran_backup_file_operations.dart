import 'dart:typed_data';

enum BackupFileOperationResult { completed, canceled, unavailable }

abstract interface class BackupFileOperations {
  Future<BackupFileOperationResult> save({
    required Uint8List bytes,
    required String confirmButtonText,
  });

  Future<BackupFileOperationResult> share({
    required Uint8List bytes,
    required String subject,
    required String title,
  });

  Future<Uint8List?> pick({required String confirmButtonText});
}
