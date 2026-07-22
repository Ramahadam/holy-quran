import 'quran_backup_file_operations.dart';
import 'quran_backup_file_operations_stub.dart'
    if (dart.library.io) 'quran_backup_file_operations_io.dart';

BackupFileOperations createBackupFileOperations() =>
    PlatformBackupFileOperations();
