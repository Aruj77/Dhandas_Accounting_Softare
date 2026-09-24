// lib/provider/company_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company_model.dart';
import '../repositories/company_repository.dart';
import '../services/storage_service.dart';

final companyRepositoryProvider = Provider((ref) => CompanyRepository());

/// Holds the currently active company domain model across the application.
/// Replaces StateProvider<Map<String, dynamic>?> with strongly-typed CompanyModel?.
final activeCompanyProvider = StateProvider<CompanyModel?>((ref) => null);

/// Manages the local root database directory on the desktop filesystem.
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

/// Discovers and parses all company workspaces located in the selected directory.
/// Deserializes raw JSON configurations directly into immutable CompanyModel instances.
final companiesProvider = FutureProvider.autoDispose<List<CompanyModel>>((ref) async {
  final dir = ref.watch(dataDirectoryProvider);
  if (dir == null || dir.isEmpty) return [];

  final repo = ref.read(companyRepositoryProvider);
  final rawCompanies = await repo.loadCompanies(dir);

  return rawCompanies.map((raw) => CompanyModel.fromJson(raw)).toList();
});