import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns the on-disk layout for company-wise local databases:
///
///   <root>/
///     registry.json                <- fast index, no DB opens needed to list companies
///     <folderId>/
///       company.sqlite              <- this company's entire DB (Drift/SQLite)
///       backups/
///
/// One SQLite file per company (Busy-style): isolated, fast to open/switch,
/// cheap to back up/restore, and never grows unbounded across companies.
class CompanyDirectoryService {
  static const _prefKey = 'dhandas_data_directory_path';
  static const _registryFile = 'registry.json';
  static const _dbFileName = 'company.sqlite';

  /// Default location when the user hasn't picked one: inside the app's own
  /// documents folder, never bare "C:\" / OS root.
  static Future<String> defaultRootDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    return p.join(docs.path, 'Dhandas', 'Data');
  }

  /// Returns the saved root directory, or the default — and ensures it exists.
  static Future<String> getRootDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    final root = (saved != null && saved.trim().isNotEmpty)
        ? saved
        : await defaultRootDirectory();
    await Directory(root).create(recursive: true);
    return root;
  }

  static Future<void> _savePref(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, path);
  }

  static File companyDbFile(String root, String folderId) =>
      File(p.join(root, folderId, _dbFileName));

  static Directory companyBackupDir(String root, String folderId) =>
      Directory(p.join(root, folderId, 'backups'));

  static Future<Directory> ensureCompanyFolder(String root, String folderId) async {
    final dir = Directory(p.join(root, folderId));
    await dir.create(recursive: true);
    await companyBackupDir(root, folderId).create(recursive: true);
    return dir;
  }

  // ---------------- registry (index.json) ----------------

  static File _registry(String root) => File(p.join(root, _registryFile));

  static Future<Map<String, dynamic>> _readRegistry(String root) async {
    final f = _registry(root);
    if (!await f.exists()) return {'nextId': 1, 'companies': <dynamic>[]};
    try {
      final data = jsonDecode(await f.readAsString());
      return {
        'nextId': data['nextId'] ?? 1,
        'companies': (data['companies'] as List?) ?? <dynamic>[],
      };
    } catch (_) {
      // Corrupt registry should never take the app down — rebuild empty;
      // existing company folders are untouched on disk.
      return {'nextId': 1, 'companies': <dynamic>[]};
    }
  }

  static Future<void> _writeRegistry(String root, Map<String, dynamic> data) async {
    final f = _registry(root);
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(jsonEncode(data));
    await tmp.rename(f.path); // atomic swap, avoids a half-written registry
  }

  static Future<List<Map<String, dynamic>>> listCompanies(String root) async {
    final reg = await _readRegistry(root);
    return (reg['companies'] as List)
        .cast<Map<String, dynamic>>()
        .where((c) => c['deletedAt'] == null)
        .toList();
  }

  static Future<String> nextFolderId(String root) async {
    final reg = await _readRegistry(root);
    final id = reg['nextId'] as int;
    reg['nextId'] = id + 1;
    await _writeRegistry(root, reg);
    return 'C-${id.toString().padLeft(4, '0')}';
  }

  static Future<void> upsertRegistryEntry(
    String root,
    Map<String, dynamic> entry,
  ) async {
    final reg = await _readRegistry(root);
    final list = (reg['companies'] as List).cast<Map<String, dynamic>>();
    final idx = list.indexWhere((c) => c['folder'] == entry['folder']);
    if (idx == -1) {
      list.add(entry);
    } else {
      list[idx] = {...list[idx], ...entry};
    }
    reg['companies'] = list;
    await _writeRegistry(root, reg);
  }

  static Future<void> markDeleted(String root, String folderId) async {
    final reg = await _readRegistry(root);
    final list = (reg['companies'] as List).cast<Map<String, dynamic>>();
    final idx = list.indexWhere((c) => c['folder'] == folderId);
    if (idx != -1) {
      list[idx] = {...list[idx], 'deletedAt': DateTime.now().toIso8601String()};
    }
    reg['companies'] = list;
    await _writeRegistry(root, reg);
  }

  // ---------------- directory migration ----------------

  /// Moves every company folder + the registry from [oldRoot] to [newRoot],
  /// then persists [newRoot] as the saved directory. Caller must ensure all
  /// SQLite connections under [oldRoot] are closed first (file locks).
  static Future<void> migrateRoot(String oldRoot, String newRoot) async {
    final oldDir = Directory(oldRoot);
    final newDir = Directory(newRoot);
    await newDir.create(recursive: true);

    if (await oldDir.exists() && p.normalize(oldRoot) != p.normalize(newRoot)) {
      // Safety: only migrate if the old path is actually a Dhandas data
      // folder (has our registry.json). Prevents ever moving an unrelated
      // folder (SDK install, Downloads, etc.) if a bad path got saved.
      final looksLikeOurData = await File(p.join(oldRoot, _registryFile)).exists();
      if (looksLikeOurData) {
        await for (final entity in oldDir.list(recursive: false)) {
          final name = p.basename(entity.path);
          final dest = p.join(newRoot, name);
          try {
            await entity.rename(dest);
          } catch (_) {
            if (entity is Directory) {
              await _copyDir(entity, Directory(dest));
              await entity.delete(recursive: true);
            } else if (entity is File) {
              final destFile = File(dest);
              if (await destFile.exists()) await destFile.delete();
              await entity.copy(dest);
              await entity.delete();
            }
          }
        }
      }
    }
    await _savePref(newRoot);
  }

  static Future<void> _copyDir(Directory src, Directory dest) async {
    await dest.create(recursive: true);
    await for (final entity in src.list(recursive: false)) {
      final name = p.basename(entity.path);
      if (entity is Directory) {
        await _copyDir(entity, Directory(p.join(dest.path, name)));
      } else if (entity is File) {
        final destFile = File(p.join(dest.path, name));
        if (await destFile.exists()) await destFile.delete(); // fixes errno 183
        await entity.copy(destFile.path);
      }
    }
  }
}
