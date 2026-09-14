import 'package:flutter/material.dart';

class VoucherSundryRow {
  final TextEditingController name = TextEditingController(text: '');
  final FocusNode nameFocus = FocusNode();
  final TextEditingController amount = TextEditingController(text: '');
  final FocusNode amountFocus = FocusNode();
  bool isNegative = false;

  void dispose() {
    name.dispose();
    nameFocus.dispose();
    amount.dispose();
    amountFocus.dispose();
  }
}