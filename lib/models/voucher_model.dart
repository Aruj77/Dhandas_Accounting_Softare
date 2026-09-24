import '../utils/app_date_utils.dart';
import '../utils/gst_party_utils.dart';

class VoucherItemModel {
  final String item;
  final String hsn;
  final double qty;
  final String unit;
  final double price;
  final double taxable;
  final double cgst;
  final double sgst;
  final double igst;
  final double amount;
  final double gstRate;

  const VoucherItemModel({
    required this.item,
    this.hsn = '',
    this.qty = 0.0,
    this.unit = 'PCS',
    this.price = 0.0,
    this.taxable = 0.0,
    this.cgst = 0.0,
    this.sgst = 0.0,
    this.igst = 0.0,
    this.amount = 0.0,
    this.gstRate = 18.0,
  });

  factory VoucherItemModel.fromJson(Map<String, dynamic> json) {
    double parse(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;

    return VoucherItemModel(
      item: (json['item'] ?? '').toString().trim(),
      hsn: (json['hsn'] ?? '').toString().trim(),
      qty: parse(json['qty']),
      unit: (json['unit'] ?? 'PCS').toString().trim(),
      price: parse(json['price']),
      taxable: parse(json['taxable']),
      cgst: parse(json['cgst']),
      sgst: parse(json['sgst']),
      igst: parse(json['igst']),
      amount: parse(json['amount']),
      gstRate: parse(json['gstRate'] ?? '18'),
    );
  }

  Map<String, dynamic> toJson() => {
        'item': item,
        'hsn': hsn,
        'qty': qty % 1 == 0 ? qty.toInt().toString() : qty.toString(),
        'unit': unit,
        'price': price.toStringAsFixed(2),
        'taxable': taxable.toStringAsFixed(2),
        'cgst': cgst.toStringAsFixed(2),
        'sgst': sgst.toStringAsFixed(2),
        'igst': igst.toStringAsFixed(2),
        'amount': amount.toStringAsFixed(2),
        'gstRate': gstRate,
      };
}

class VoucherSundryModel {
  final String name;
  final String percent;
  final double amount;
  final bool isNegative;

  const VoucherSundryModel({
    required this.name,
    this.percent = '',
    this.amount = 0.0,
    this.isNegative = false,
  });

  factory VoucherSundryModel.fromJson(Map<String, dynamic> json) {
    return VoucherSundryModel(
      name: (json['name'] ?? '').toString().trim(),
      percent: (json['percent'] ?? '').toString().trim(),
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      isNegative: json['isNegative'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'percent': percent,
        'amount': amount.toStringAsFixed(2),
        'isNegative': isNegative,
      };
}

class VoucherModel {
  final String id;
  final String voucherType;
  final String voucherNumber;
  final String date;
  final String series;
  final String saleType;
  final String party;
  final String partyGstin;
  final String partyStateCode;
  final bool isInterState;
  final String materialCenter;
  final String narration;
  final String financialYear;
  final List<VoucherItemModel> items;
  final List<VoucherSundryModel> sundries;
  final double subTotal;
  final double cgst;
  final double sgst;
  final double igst;
  final double totalTax;
  final double sundryTotal;
  final double roundOff;
  final double grandTotal;
  final String createdAt;

  const VoucherModel({
    required this.id,
    required this.voucherType,
    required this.voucherNumber,
    required this.date,
    this.series = 'Main',
    this.saleType = 'Local Itemwise',
    required this.party,
    this.partyGstin = '',
    this.partyStateCode = '',
    this.isInterState = false,
    this.materialCenter = 'Main Store',
    this.narration = '',
    required this.financialYear,
    this.items = const [],
    this.sundries = const [],
    this.subTotal = 0.0,
    this.cgst = 0.0,
    this.sgst = 0.0,
    this.igst = 0.0,
    this.totalTax = 0.0,
    this.sundryTotal = 0.0,
    this.roundOff = 0.0,
    required this.grandTotal,
    required this.createdAt,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    double parse(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;

    final rawParty = (json['party'] ?? '').toString();
    final cleanParty = GstPartyUtils.extractPartyName(rawParty).trim();
    final partyGstin = (json['partyGstin'] ?? GstPartyUtils.extractPartyGstin(rawParty)).toString().trim();

    return VoucherModel(
      id: (json['id'] ?? 'vch_${DateTime.now().millisecondsSinceEpoch}').toString(),
      voucherType: (json['voucherType'] ?? '').toString(),
      voucherNumber: (json['voucherNumber'] ?? json['vchNo'] ?? '').toString().trim(),
      date: (json['date'] ?? '').toString(),
      series: (json['series'] ?? json['seriesName'] ?? 'Main').toString().trim(),
      saleType: (json['saleType'] ?? 'Local Itemwise').toString(),
      party: cleanParty.isNotEmpty ? cleanParty : rawParty,
      partyGstin: partyGstin,
      partyStateCode: (json['partyStateCode'] ?? (partyGstin.length >= 2 ? partyGstin.substring(0, 2) : '')).toString(),
      isInterState: json['isInterState'] == true,
      materialCenter: (json['materialCenter'] ?? 'Main Store').toString(),
      narration: (json['narration'] ?? '').toString(),
      financialYear: (json['financialYear'] ?? AppDateUtils.defaultFinancialYear).toString(),
      items: (json['items'] as List? ?? []).map((i) => VoucherItemModel.fromJson(i as Map<String, dynamic>)).toList(),
      sundries: (json['sundries'] as List? ?? []).map((s) => VoucherSundryModel.fromJson(s as Map<String, dynamic>)).toList(),
      subTotal: parse(json['subTotal']),
      cgst: parse(json['cgst']),
      sgst: parse(json['sgst']),
      igst: parse(json['igst']),
      totalTax: parse(json['totalTax']),
      sundryTotal: parse(json['sundryTotal']),
      roundOff: parse(json['roundOff']),
      grandTotal: parse(json['grandTotal']),
      createdAt: (json['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'voucherType': voucherType,
        'voucherNumber': voucherNumber,
        'date': date,
        'series': series,
        'saleType': saleType,
        'party': party,
        'partyGstin': partyGstin,
        'partyStateCode': partyStateCode,
        'isInterState': isInterState,
        'materialCenter': materialCenter,
        'narration': narration,
        'financialYear': financialYear,
        'items': items.map((i) => i.toJson()).toList(),
        'sundries': sundries.map((s) => s.toJson()).toList(),
        'subTotal': subTotal,
        'cgst': cgst,
        'sgst': sgst,
        'igst': igst,
        'totalTax': totalTax,
        'sundryTotal': sundryTotal,
        'roundOff': roundOff,
        'grandTotal': grandTotal,
        'createdAt': createdAt,
      };

  bool get isSale => voucherType.toLowerCase().contains('sale');
  bool get isPurchase => voucherType.toLowerCase().contains('purchase');
  bool get isReceipt => voucherType.toLowerCase().contains('receipt') || voucherType.toLowerCase().contains('payment in');
  bool get isPayment => voucherType.toLowerCase().contains('payment') || voucherType.toLowerCase().contains('payment out');
  DateTime? get parsedDate => AppDateUtils.parseDate(date);
}