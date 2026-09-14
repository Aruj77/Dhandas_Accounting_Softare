import 'package:flutter/material.dart';

class VoucherItemRow {
  final TextEditingController item = TextEditingController();
  final FocusNode itemFocus = FocusNode();

  final TextEditingController qty = TextEditingController(text: '1.00');
  final FocusNode qtyFocus = FocusNode();

  final TextEditingController unit = TextEditingController(text: 'PCS');
  final FocusNode unitFocus = FocusNode();

  final TextEditingController price = TextEditingController(text: '0.00');
  final FocusNode priceFocus = FocusNode();

  final TextEditingController taxable = TextEditingController(text: '0.00');
  final FocusNode taxableFocus = FocusNode();

  final TextEditingController cgst = TextEditingController(text: '0.00');
  final FocusNode cgstFocus = FocusNode();

  final TextEditingController sgst = TextEditingController(text: '0.00');
  final FocusNode sgstFocus = FocusNode();

  final TextEditingController igst = TextEditingController(text: '0.00');
  final FocusNode igstFocus = FocusNode();

  double amount = 0.0;

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
  }
}