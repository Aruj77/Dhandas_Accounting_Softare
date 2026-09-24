import '../utils/number_parsing_utils.dart';

class ItemMasterModel {
  final String name;
  final String hsn;
  final String unit;
  final String taxCategory;
  final double taxRate;
  final double salesPrice;
  final double purchasePrice;
  final double mrp;

  const ItemMasterModel({
    required this.name,
    required this.hsn,
    required this.unit,
    required this.taxCategory,
    required this.taxRate,
    required this.salesPrice,
    required this.purchasePrice,
    required this.mrp,
  });

  factory ItemMasterModel.empty() => const ItemMasterModel(
        name: '',
        hsn: '',
        unit: 'PCS',
        taxCategory: 'GST 18%',
        taxRate: 18.0,
        salesPrice: 0.0,
        purchasePrice: 0.0,
        mrp: 0.0,
      );

  factory ItemMasterModel.fromJson(Map<String, dynamic> json) {
    return ItemMasterModel(
      name: json['name']?.toString() ?? '',
      hsn: json['hsn']?.toString() ?? '',
      unit: (json['unit']?.toString().trim().isNotEmpty ?? false)
          ? json['unit'].toString().trim()
          : 'PCS',
      taxCategory: json['taxCategory']?.toString() ?? 'GST 18%',
      taxRate: NumberParsing.toDouble(json['taxRate'], 18.0),
      salesPrice: NumberParsing.toDouble(json['salesPrice'], 0.0),
      purchasePrice: NumberParsing.toDouble(json['purchasePrice'], 0.0),
      mrp: NumberParsing.toDouble(json['mrp'], 0.0),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'hsn': hsn,
        'unit': unit,
        'taxCategory': taxCategory,
        'taxRate': taxRate,
        'salesPrice': salesPrice,
        'purchasePrice': purchasePrice,
        'mrp': mrp,
      };

  Map<String, dynamic> toMap() => toJson();

  ItemMasterModel copyWith({
    String? name,
    String? hsn,
    String? unit,
    String? taxCategory,
    double? taxRate,
    double? salesPrice,
    double? purchasePrice,
    double? mrp,
  }) {
    return ItemMasterModel(
      name: name ?? this.name,
      hsn: hsn ?? this.hsn,
      unit: unit ?? this.unit,
      taxCategory: taxCategory ?? this.taxCategory,
      taxRate: taxRate ?? this.taxRate,
      salesPrice: salesPrice ?? this.salesPrice,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      mrp: mrp ?? this.mrp,
    );
  }
}