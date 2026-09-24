import 'package:flutter/material.dart';
import '../../../models/item_master_model.dart';
import '../../../models/party_master_model.dart';
import '../../../services/storage_service.dart';
import '../../../utils/gst_party_utils.dart';
import '../../../services/notification_service.dart';
import './../widgets/voucher/popup/add_item_dialog.dart';
import './../widgets/voucher/popup/add_party_dialog.dart';
import './../widgets/voucher/voucher_item_row.dart';

class VoucherMasterActions {
  static bool handleAltE({
    required BuildContext context,
    required Map<String, dynamic> company,
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
    final folderPath = company['folderPath']?.toString();

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
              final originalName = matchedParty.name.trim().toLowerCase();

              // Save directly to masters.json on disk
              if (folderPath != null && folderPath.isNotEmpty) {
                try {
                  final raw = await StorageService.loadCompanyMasters(folderPath: folderPath);
                  final isCreditor = (partyData['group'] ?? '').toString().toLowerCase().contains('creditor');
                  final listKey = isCreditor ? 'creditors' : 'debtors';
                  final oppKey = isCreditor ? 'debtors' : 'creditors';

                  // Remove from opposite list if group changed
                  (raw[oppKey] as List?)?.removeWhere((p) =>
                      (p['name'] ?? '').toString().trim().toLowerCase() == originalName);

                  final list = (raw[listKey] as List? ?? [])
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList();

                  final idx = list.indexWhere((p) =>
                      (p['name'] ?? '').toString().trim().toLowerCase() == originalName);

                  if (idx != -1) {
                    list[idx] = partyData;
                  } else {
                    list.add(partyData);
                  }

                  raw[listKey] = list;
                  await StorageService.saveCompanyMasters(folderPath: folderPath, mastersData: raw);
                } catch (e) {
                  debugPrint('Error saving party master: $e');
                }
              }

              final updated = PartyMasterModel(
                name: partyData['name'] ?? '',
                gstin: partyData['gstin'] ?? '',
                group: partyData['group'] ?? matchedParty.group,
              );

              onPartyUpdated(updated);
              await onSyncMasters();

              if (context.mounted) {
                NotificationService.show(
                  context,
                  message: 'Party Master "${updated.displayName}" updated and saved permanently.',
                  type: NotificationType.success,
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
              company: company,
              folderPath: folderPath,
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
                  NotificationService.show(
                    context,
                    message: 'Item Master "${updated.name}" updated and saved permanently.',
                    type: NotificationType.success,
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