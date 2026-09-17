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
}