// desktop/lib/widgets/common/register_header_bar.dart
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/register_summary.dart';
import '../../widgets/common/quick_metric_badge.dart';

class RegisterHeaderBar extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final RegisterSummary summary;
  final String hintText;
  final ValueChanged<String>? onSubmitted;
  final bool isManageMode;

  const RegisterHeaderBar({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.summary,
    this.hintText = 'Search by Voucher, Party, GSTIN, HSN...',
    this.onSubmitted,
    this.isManageMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: searchController,
                focusNode: searchFocusNode,
                onSubmitted: onSubmitted,
                decoration: InputDecoration(
                  hintText: hintText,
                  prefixIcon: const Icon(Icons.search_rounded, size: 17, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.3)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          QuickMetricBadge(
            label: isManageMode ? 'Vouchers' : 'Total Invoices',
            value: '${summary.totalInvoices}',
            color: AppColors.primaryDark,
          ),
          const SizedBox(width: 8),
          QuickMetricBadge(label: 'Total Qty', value: summary.totalQuantity.toStringAsFixed(2), color: AppColors.info),
          const SizedBox(width: 8),
          QuickMetricBadge(label: 'Taxable Val', value: '₹${summary.totalTaxable.toStringAsFixed(2)}', color: AppColors.purple),
          const SizedBox(width: 8),
          QuickMetricBadge(label: 'Invoice Total', value: '₹${summary.totalInvoiceValue.toStringAsFixed(2)}', color: AppColors.primary),
        ],
      ),
    );
  }
}