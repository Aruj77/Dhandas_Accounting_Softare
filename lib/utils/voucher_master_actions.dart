import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/item_master_model.dart';
import '../../../models/party_master_model.dart';
import '../../../utils/gst_party_utils.dart';
import './../widgets/voucher/popup/add_item_dialog.dart';
import './../widgets/voucher/popup/add_party_dialog.dart';
import './../widgets/voucher/voucher_item_row.dart';

class VoucherMasterActions {
  static bool handleAltE({
    required BuildContext context,
    required FocusNode partyFocus,
    required TextEditingController partyController,
    required List<PartyMasterModel> availableParties,
    required String voucherType,
    required List<VoucherItemRow> items,
    required List<ItemMasterModel> itemsMasterList,
    required Function(PartyMasterModel updated) onPartyUpdated,
    required Function(int index, ItemMasterModel updated) onItemUpdated,
    required Future<void> Function() onSyncMasters,
  }) {
    // 1. Party Field Check
    if (partyFocus.hasFocus) {
      final text = partyController.text.trim();
      if (text.isEmpty) return false;

      final clean = text.toLowerCase();
      final cleanName = GstPartyUtils.extractPartyName(text).toLowerCase();

      final matchedParty = availableParties.where((p) =>
          p.displayName.trim().toLowerCase() == clean ||
          p.name.trim().toLowerCase() == clean ||
          p.displayName.trim().toLowerCase() == cleanName ||
          p.name.trim().toLowerCase() == cleanName).firstOrNull;

      if (matchedParty != null) {
        showDialog(
          context: context,
          builder: (_) => AddPartyDialog(
            voucherType: voucherType,
            initialParty: matchedParty,
            isEdit: true,
            onPartyCreated: (partyData) async {
              final updated = PartyMasterModel(
                name: partyData['name'] ?? '',
                gstin: partyData['gstin'] ?? '',
                group: partyData['group'] ?? matchedParty.group,
              );
              onPartyUpdated(updated);
              await onSyncMasters();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Party Master "${updated.displayName}" updated and saved permanently.'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        );
        return true;
      }
      return false;
    }

    // 2. Table Items Check
    for (int i = 0; i < items.length; i++) {
      final row = items[i];
      final isRowFocused = row.itemFocus.hasFocus ||
          row.qtyFocus.hasFocus ||
          row.priceFocus.hasFocus ||
          row.taxableFocus.hasFocus ||
          row.amountFocus.hasFocus;

      if (isRowFocused) {
        final text = row.item.text.trim();
        if (text.isEmpty) return false;

        final matchedItem = itemsMasterList.where((m) =>
            m.name.trim().toLowerCase() == text.toLowerCase()).firstOrNull;

        if (matchedItem != null) {
          showDialog(
            context: context,
            builder: (_) => AddItemDialog(
              initialItem: matchedItem,
              isEdit: true,
              onItemCreated: (itemData) async {
                final updated = ItemMasterModel(
                  name: itemData['name'],
                  hsn: itemData['hsn'],
                  unit: itemData['unit'],
                  taxCategory: itemData['taxCategory'],
                  taxRate: itemData['taxRate'],
                  salesPrice: itemData['salesPrice'],
                  purchasePrice: itemData['purchasePrice'],
                  mrp: itemData['mrp'],
                );
                onItemUpdated(i, updated);
                await onSyncMasters();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Item Master "${updated.name}" updated and saved permanently.'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          );
          return true;
        }
        return false;
      }
    }

    return false;
  }
}