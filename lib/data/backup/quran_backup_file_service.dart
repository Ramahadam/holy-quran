import 'dart:typed_data';

import 'quran_backup_file_operations.dart';
import 'quran_backup_service.dart';

class QuranBackupFileService {
  final QuranBackupService backupService;
  final BackupFileOperations fileOperations;

  const QuranBackupFileService({
    required this.backupService,
    required this.fileOperations,
  });

  Future<BackupFileOperationResult> saveBackup(
    String passphrase, {
    required String confirmButtonText,
  }) async {
    return fileOperations.save(
      bytes: Uint8List.fromList(await backupService.exportBackup(passphrase)),
      confirmButtonText: confirmButtonText,
    );
  }

  Future<BackupFileOperationResult> shareBackup(
    String passphrase, {
    required String subject,
    required String title,
  }) async {
    return fileOperations.share(
      bytes: Uint8List.fromList(await backupService.exportBackup(passphrase)),
      subject: subject,
      title: title,
    );
  }

  Future<BackupFileOperationResult> restoreBackup(
    String passphrase, {
    required String confirmButtonText,
  }) async {
    final bytes = await fileOperations.pick(
      confirmButtonText: confirmButtonText,
    );
    if (bytes == null) return BackupFileOperationResult.canceled;
    await backupService.importBackup(bytes, passphrase);
    return BackupFileOperationResult.completed;
  }
}
