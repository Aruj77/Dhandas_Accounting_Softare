import 'package:flutter/material.dart';

class VoucherSundryRow {
  final TextEditingController name = TextEditingController();
  final FocusNode nameFocus = FocusNode();

  final TextEditingController percent = TextEditingController();
  final FocusNode percentFocus = FocusNode();

  final TextEditingController amount = TextEditingController();
  final FocusNode amountFocus = FocusNode();

  bool isNegative = false;

  void dispose() {
    name.dispose();
    nameFocus.dispose();
    percent.dispose();
    percentFocus.dispose();
    amount.dispose();
    amountFocus.dispose();
  }
}