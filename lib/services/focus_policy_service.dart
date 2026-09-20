// lib/services/focus_policy_service.dart
import 'package:flutter/material.dart';

enum FocusTargetScreen {
  homeDashboard,
  voucherEntry,
  voucherList,
  voucherManageList,
  mastersDashboard,
  masterActionsSheet,
  administration,
  reportsDashboard,
  settings,
  openCompanyDialog,
  createCompanyDialog,
  setDirectoryDialog,
  addItemDialog,
  addPartyDialog,
  addSeriesDialog,
  calculatorDialog,
  itemTaxDetailsDialog,
  salesInvoicePrintDialog,
  voucherModifyDialog,
  voucherSaveConfirmDialog,
  dateRangeDialog,
  missingVchNoWarningDialog,
  masterNotFoundDialog,
  taxMismatchWarningDialog,
  unsavedChangesDialog,
}

enum FocusFieldNode {
  primaryAction,
  secondaryAction,
  searchField,
  firstField,
  seriesField,
  dateField,
  voucherNumberField,
  partyField,
  saleTypeField,
  materialCenterField,
  narrationField,
  firstItemRow,
  hsnField,
  itemNameField,
  unitField,
  taxCategoryField,
  salesPriceField,
  partyGstinField,
  partyNameField,
  partyAddressField,
  seriesNameField,
  numberingTypeField,
  startNumberField,
  directoryPathField,
  directoryBrowseButton,
  calculatorKeypad,
  confirmYesButton,
  confirmNoButton,
}

class FocusPolicyService {
  static final Map<FocusTargetScreen, FocusFieldNode> _defaultPolicies = {
    FocusTargetScreen.homeDashboard: FocusFieldNode.firstField,
    FocusTargetScreen.voucherEntry: FocusFieldNode.seriesField,
    FocusTargetScreen.voucherList: FocusFieldNode.searchField,
    FocusTargetScreen.voucherManageList: FocusFieldNode.searchField,
    FocusTargetScreen.mastersDashboard: FocusFieldNode.firstField,
    FocusTargetScreen.masterActionsSheet: FocusFieldNode.secondaryAction,

    FocusTargetScreen.administration: FocusFieldNode.firstField,
    FocusTargetScreen.reportsDashboard: FocusFieldNode.firstField,
    FocusTargetScreen.settings: FocusFieldNode.firstField,
    FocusTargetScreen.openCompanyDialog: FocusFieldNode.searchField,
    FocusTargetScreen.createCompanyDialog: FocusFieldNode.firstField,
    FocusTargetScreen.setDirectoryDialog: FocusFieldNode.directoryPathField,
    FocusTargetScreen.addItemDialog: FocusFieldNode.hsnField,
    FocusTargetScreen.addPartyDialog: FocusFieldNode.partyGstinField,
    FocusTargetScreen.addSeriesDialog: FocusFieldNode.seriesNameField,
    FocusTargetScreen.calculatorDialog: FocusFieldNode.calculatorKeypad,
    FocusTargetScreen.itemTaxDetailsDialog: FocusFieldNode.firstField,
    FocusTargetScreen.salesInvoicePrintDialog: FocusFieldNode.primaryAction,
    FocusTargetScreen.voucherModifyDialog: FocusFieldNode.voucherNumberField,
    FocusTargetScreen.voucherSaveConfirmDialog: FocusFieldNode.confirmYesButton,
    FocusTargetScreen.dateRangeDialog: FocusFieldNode.firstField,
    FocusTargetScreen.missingVchNoWarningDialog: FocusFieldNode.confirmNoButton,
    FocusTargetScreen.masterNotFoundDialog: FocusFieldNode.confirmYesButton,
    FocusTargetScreen.taxMismatchWarningDialog: FocusFieldNode.confirmYesButton,
    FocusTargetScreen.unsavedChangesDialog: FocusFieldNode.confirmNoButton,
  };

  static FocusFieldNode getTargetFor(FocusTargetScreen screen) {
    return _defaultPolicies[screen] ?? FocusFieldNode.firstField;
  }

  static void setOverrideTarget({
    required FocusTargetScreen screen,
    required FocusFieldNode target,
  }) {
    _defaultPolicies[screen] = target;
  }

  static void requestScreenFocus({
    required FocusTargetScreen screen,
    required Map<FocusFieldNode, FocusNode> nodeMap,
  }) {
    final targetNodeKey = getTargetFor(screen);
    final focusNode = nodeMap[targetNodeKey] ?? nodeMap[FocusFieldNode.firstField];

    if (focusNode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (focusNode.canRequestFocus) {
          focusNode.requestFocus();
        }
      });
    }
  }
}

class AutoScreenFocus extends StatefulWidget {
  final FocusTargetScreen screen;
  final Map<FocusFieldNode, FocusNode> nodeMap;
  final Widget child;

  const AutoScreenFocus({
    super.key,
    required this.screen,
    required this.nodeMap,
    required this.child,
  });

  @override
  State<AutoScreenFocus> createState() => _AutoScreenFocusState();
}

class _AutoScreenFocusState extends State<AutoScreenFocus> {
  @override
  void initState() {
    super.initState();
    FocusPolicyService.requestScreenFocus(
      screen: widget.screen,
      nodeMap: widget.nodeMap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}