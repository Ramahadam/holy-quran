import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';

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
    final bytes = await backupService.exportBackup(passphrase);
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(bytes),
            mimeType: 'application/octet-stream',
            name: _backupFileName,
          ),
        ],
        fileNameOverrides: const [_backupFileName],
        subject: 'Holy Quran backup',
        title: 'Export Holy Quran backup',
      ),
    );
    return result.status != ShareResultStatus.dismissed;
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
