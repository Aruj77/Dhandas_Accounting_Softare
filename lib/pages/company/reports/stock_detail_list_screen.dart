import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/number_parsing_utils.dart';

class StockDetailListScreen extends StatelessWidget {
  final String title;
  final double totalAmount;
  final List<Map<String, dynamic>> items;

  const StockDetailListScreen({
    super.key,
    required this.title,
    required this.totalAmount,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 16)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Inventory Ledger Value', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
                  Text('₹${totalAmount.toCurrency()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Itemized Stock Records', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                Text('${items.length} items found', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text('No inventory stock records available.', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final name = item['name']?.toString() ?? 'Item';
                        final qty = double.tryParse(item['qty']?.toString() ?? '0') ?? 0.0;
                        final rate = double.tryParse(item['rate']?.toString() ?? '0') ?? 0.0;
                        final val = double.tryParse(item['val']?.toString() ?? '0') ?? 0.0;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                    const SizedBox(height: 4),
                                    Text('Quantity: $qty units @ ₹${rate.toCurrency()}', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Text('₹${val.toCurrency()}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}