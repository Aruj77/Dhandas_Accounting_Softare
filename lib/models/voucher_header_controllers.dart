import 'package:flutter/material.dart';
import '../../../services/focus_policy_service.dart';

/// Bundles all header text controllers and focus nodes to eliminate 
/// repetitive initialization, disposal, and screen-level clutter.
class VoucherHeaderControllers {
  final series = TextEditingController(text: 'Main');
  final date = TextEditingController();
  final vchNo = TextEditingController();
  final party = TextEditingController();
  final saleType = TextEditingController(text: 'Local Itemwise');
  final matCenter = TextEditingController(text: 'Main Store');
  final narration = TextEditingController();

  final seriesFocus = FocusNode();
  final dateFocus = FocusNode();
  final vchNoFocus = FocusNode();
  final partyFocus = FocusNode();
  final saleTypeFocus = FocusNode();
  final matCenterFocus = FocusNode();
  final narrationFocus = FocusNode();
  final saveButtonFocus = FocusNode();

  List<TextEditingController> get allControllers => [
        series,
        date,
        vchNo,
        party,
        saleType,
        matCenter,
        narration,
      ];

  List<FocusNode> get allFocusNodes => [
        seriesFocus,
        dateFocus,
        vchNoFocus,
        partyFocus,
        saleTypeFocus,
        matCenterFocus,
        narrationFocus,
        saveButtonFocus,
      ];

  Map<FocusFieldNode, FocusNode> get focusNodeMap => {
        FocusFieldNode.seriesField: seriesFocus,
        FocusFieldNode.dateField: dateFocus,
        FocusFieldNode.voucherNumberField: vchNoFocus,
        FocusFieldNode.partyField: partyFocus,
        FocusFieldNode.saleTypeField: saleTypeFocus,
        FocusFieldNode.materialCenterField: matCenterFocus,
        FocusFieldNode.narrationField: narrationFocus,
      };

  void clearVoucherSpecifics({required String defaultSaleType, required String defaultMatCenter}) {
    vchNo.clear();
    party.clear();
    narration.clear();
    saleType.text = defaultSaleType;
    matCenter.text = defaultMatCenter;
  }

  void dispose() {
    for (final c in allControllers) {
      c.dispose();
    }
    for (final f in allFocusNodes) {
      f.dispose();
    }
  }
}