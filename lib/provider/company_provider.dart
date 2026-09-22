import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/company_repository.dart';
import '../services/storage_service.dart';

final companyRepositoryProvider = Provider((ref) => CompanyRepository());

/// Holds the currently opened company details across the application
final activeCompanyProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

final dataDirectoryProvider = StateNotifierProvider<DataDirectoryNotifier, String?>((ref) {
  return DataDirectoryNotifier();
});

class DataDirectoryNotifier extends StateNotifier<String?> {
  DataDirectoryNotifier() : super(null) {
    _initDirectory();
  }

  Future<void> _initDirectory() async {
    final savedPath = await StorageService.getSavedDirectory();
    state = savedPath;
  }

  Future<void> setDirectory(String path) async {
    await StorageService.saveDirectory(path);
    state = path;
  }
}

final companiesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dir = ref.watch(dataDirectoryProvider);
  if (dir == null || dir.isEmpty) return [];

  final repo = ref.read(companyRepositoryProvider);
  return await repo.loadCompanies(dir);
});