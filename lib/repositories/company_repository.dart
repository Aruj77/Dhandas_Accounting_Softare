import '../services/storage_service.dart';

class CompanyRepository {
  Future<List<Map<String, dynamic>>> loadCompanies(String directoryPath) async {
    return await StorageService.loadCompanies(directoryPath);
  }

  Future<String> createCompany({
    required String directoryPath,
    required Map<String, dynamic> companyData,
  }) async {
    return await StorageService.saveCompanyLocally(
      directoryPath: directoryPath,
      companyData: companyData,
    );
  }

  Future<void> updateCompany({
    required Map<String, dynamic> companyData,
  }) async {
    await StorageService.updateCompanyLocally(companyData: companyData);
  }

  Future<void> deleteCompany({
    required Map<String, dynamic> companyData,
  }) async {
    await StorageService.deleteCompanyLocally(companyData: companyData);
  }
}