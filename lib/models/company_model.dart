import '../constants/gst_constants.dart';
import '../utils/app_date_utils.dart';

class CompanyModel {
  final String id;
  final String companyName;
  final String folderPath;
  final String gstin;
  final String state;
  final String activeFinancialYear;
  final List<String> financialYears;
  final Map<String, dynamic> rawExtras;

  const CompanyModel({
    required this.id,
    required this.companyName,
    required this.folderPath,
    required this.gstin,
    required this.state,
    required this.activeFinancialYear,
    this.financialYears = const [],
    this.rawExtras = const {},
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    final rawGstin = (json['gstin'] ?? json['gstNumber'] ?? '').toString().trim();
    final rawState = (json['state'] ?? json['stateName'] ?? '').toString().trim();
    final activeFy = (json['activeFinancialYear'] ?? AppDateUtils.defaultFinancialYear).toString();

    return CompanyModel(
      id: (json['id'] ?? json['folderPath'] ?? '').toString(),
      companyName: (json['companyName'] ?? 'Workspace').toString().trim(),
      folderPath: (json['folderPath'] ?? '').toString(),
      gstin: rawGstin,
      state: rawState,
      activeFinancialYear: activeFy,
      financialYears: List<String>.from(json['financialYears'] ?? [activeFy]),
      rawExtras: json,
    );
  }

  Map<String, dynamic> toJson() => {
        ...rawExtras,
        'id': id,
        'companyName': companyName,
        'folderPath': folderPath,
        'gstin': gstin,
        'state': state,
        'activeFinancialYear': activeFinancialYear,
        'financialYears': financialYears,
      };

  /// Computes the 2-digit GST state code from GSTIN or state name
  String get stateCode {
    if (gstin.length >= 2 && int.tryParse(gstin.substring(0, 2)) != null) {
      return gstin.substring(0, 2);
    }
    return GstConstants.getStateCodeByName(state) ?? '07';
  }

  /// Calculates FY date bounds
  ({DateTime startDate, DateTime endDate}) get fyBounds {
    final bounds = AppDateUtils.parseFinancialYearBounds(activeFinancialYear);
    return (startDate: bounds.startDate, endDate: bounds.endDate);
  }
}