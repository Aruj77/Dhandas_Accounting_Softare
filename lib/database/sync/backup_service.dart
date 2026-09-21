import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Local file-level backup of the SQLite database (fast, no query layer
/// involved) + a pluggable hook for pushing that file to cloud storage.
class BackupService {
  Future<File> backupLocal() async {
    final dir = await getApplicationDocumentsDirectory();
    final source = File(p.join(dir.path, 'dhandas.sqlite'));
    final backupDir = Directory(p.join(dir.path, 'backups'));
    if (!await backupDir.exists()) await backupDir.create(recursive: true);
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final dest = File(p.join(backupDir.path, 'dhandas_$stamp.sqlite'));
    return source.copy(dest.path);
  }

  Future<void> uploadToCloud(File backupFile, Future<void> Function(File) uploader) {
    return uploader(backupFile);
  }

  Future<void> restoreFrom(File backupFile) async {
    final dir = await getApplicationDocumentsDirectory();
    final target = File(p.join(dir.path, 'dhandas.sqlite'));
    await backupFile.copy(target.path);
  }
}
