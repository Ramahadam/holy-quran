import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

import 'quran_backup_service.dart';

const _backupFileName = 'holy-quran-backup.quran';
const _backupTypeGroup = XTypeGroup(
  label: 'Holy Quran backup',
  extensions: ['quran'],
);

class QuranBackupFileService {
  final QuranBackupService backupService;

  const QuranBackupFileService({required this.backupService});

  Future<bool> exportBackup(String passphrase) async {
    final location = await getSaveLocation(
      acceptedTypeGroups: const [_backupTypeGroup],
      suggestedName: _backupFileName,
    );
    if (location == null) return false;

    final bytes = await backupService.exportBackup(passphrase);
    final file = XFile.fromData(
      Uint8List.fromList(bytes),
      mimeType: 'application/octet-stream',
      name: _backupFileName,
    );
    await file.saveTo(location.path);
    return true;
  }

  Future<bool> importBackup(String passphrase) async {
    final file = await openFile(
      acceptedTypeGroups: const [_backupTypeGroup],
      confirmButtonText: 'Import',
    );
    if (file == null) return false;

    await backupService.importBackup(await file.readAsBytes(), passphrase);
    return true;
  }
}
