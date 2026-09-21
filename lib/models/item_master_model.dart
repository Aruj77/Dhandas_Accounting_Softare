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
  
  factory ItemMasterModel.empty() => ItemMasterModel(
    name: '',
    hsn: '',
    unit: 'Pcs',
    taxCategory: 'GST 18%',
    taxRate: 18.0,
    salesPrice: 0.0,
    purchasePrice: 0.0,
    mrp: 0.0,
  );
}