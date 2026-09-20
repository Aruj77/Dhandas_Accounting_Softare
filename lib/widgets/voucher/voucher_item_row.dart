import 'package:flutter/material.dart';

class VoucherItemRow {
  final TextEditingController item = TextEditingController();
  final FocusNode itemFocus = FocusNode();

  String hsn = '';

  final TextEditingController qty = TextEditingController(text: '');
  final FocusNode qtyFocus = FocusNode();

  final TextEditingController unit = TextEditingController(text: '');
  final FocusNode unitFocus = FocusNode();

  final TextEditingController price = TextEditingController(text: '');
  final FocusNode priceFocus = FocusNode();

  final TextEditingController taxable = TextEditingController(text: '');
  final FocusNode taxableFocus = FocusNode();

  final TextEditingController cgst = TextEditingController(text: '');
  final FocusNode cgstFocus = FocusNode();

  final TextEditingController sgst = TextEditingController(text: '');
  final FocusNode sgstFocus = FocusNode();

  final TextEditingController igst = TextEditingController(text: '');
  final FocusNode igstFocus = FocusNode();

  final TextEditingController amount = TextEditingController(text: '');
  final FocusNode amountFocus = FocusNode();

  // Dynamic tax rate assigned from the selected Item Master
  double gstRate = 18.0;

  void dispose() {
    item.dispose();
    itemFocus.dispose();
    qty.dispose();
    qtyFocus.dispose();
    unit.dispose();
    unitFocus.dispose();
    price.dispose();
    priceFocus.dispose();
    taxable.dispose();
    taxableFocus.dispose();
    cgst.dispose();
    cgstFocus.dispose();
    sgst.dispose();
    sgstFocus.dispose();
    igst.dispose();
    igstFocus.dispose();
    amount.dispose();
    amountFocus.dispose();
  }
}