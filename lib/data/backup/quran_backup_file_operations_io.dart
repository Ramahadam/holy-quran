import 'dart:io';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';

import 'quran_backup_file_operations.dart';

const _backupBaseName = 'holy-quran-backup';
const _backupExtension = 'quran';
const _backupFileName = '$_backupBaseName.$_backupExtension';
const _backupMimeType = 'application/octet-stream';
const _backupTypeGroup = XTypeGroup(
  label: 'Holy Quran backup',
  extensions: [_backupExtension],
);

class PlatformBackupFileOperations implements BackupFileOperations {
  @override
  Future<BackupFileOperationResult> save({
    required Uint8List bytes,
    required String confirmButtonText,
  }) async {
    if (Platform.isAndroid || Platform.isIOS) {
      final path = await FileSaver.instance.saveAs(
        name: _backupBaseName,
        bytes: bytes,
        fileExtension: _backupExtension,
        mimeType: MimeType.custom,
        customMimeType: _backupMimeType,
      );
      return path == null
          ? BackupFileOperationResult.canceled
          : BackupFileOperationResult.completed;
    }

    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      final location = await getSaveLocation(
        suggestedName: _backupFileName,
        acceptedTypeGroups: const [_backupTypeGroup],
        confirmButtonText: confirmButtonText,
      );
      if (location == null) return BackupFileOperationResult.canceled;
      await XFile.fromData(
        bytes,
        mimeType: _backupMimeType,
        name: _backupFileName,
      ).saveTo(location.path);
      return BackupFileOperationResult.completed;
    }

    return BackupFileOperationResult.unavailable;
  }

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
