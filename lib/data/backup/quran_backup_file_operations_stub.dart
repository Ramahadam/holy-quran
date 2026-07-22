import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';

import 'quran_backup_file_operations.dart';

const _backupFileName = 'holy-quran-backup.quran';
const _backupMimeType = 'application/octet-stream';
const _backupTypeGroup = XTypeGroup(
  label: 'Holy Quran backup',
  extensions: ['quran'],
);

class PlatformBackupFileOperations implements BackupFileOperations {
  @override
  Future<BackupFileOperationResult> save({
    required Uint8List bytes,
    required String confirmButtonText,
  }) async => BackupFileOperationResult.unavailable;

  @override
  Future<BackupFileOperationResult> share({
    required Uint8List bytes,
    required String subject,
    required String title,
  }) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            mimeType: _backupMimeType,
            name: _backupFileName,
          ),
        ],
        fileNameOverrides: const [_backupFileName],
        subject: subject,
        title: title,
      ),
    );
    return switch (result.status) {
      ShareResultStatus.success => BackupFileOperationResult.completed,
      ShareResultStatus.dismissed => BackupFileOperationResult.canceled,
      ShareResultStatus.unavailable => BackupFileOperationResult.unavailable,
    };
  }

  @override
  Future<Uint8List?> pick({required String confirmButtonText}) async {
    final file = await openFile(
      acceptedTypeGroups: const [_backupTypeGroup],
      confirmButtonText: confirmButtonText,
    );
    return file?.readAsBytes();
  }
}
