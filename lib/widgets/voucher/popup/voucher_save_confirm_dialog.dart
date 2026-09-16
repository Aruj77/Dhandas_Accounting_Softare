import 'package:flutter/material.dart';

class VoucherSaveConfirmDialog extends StatefulWidget {
  final Map<String, dynamic> summaryData;
  final VoidCallback onConfirm;

  const VoucherSaveConfirmDialog({
    super.key,
    required this.summaryData,
    required this.onConfirm,
  });

  @override
  State<VoucherSaveConfirmDialog> createState() => _VoucherSaveConfirmDialogState();
}

class _VoucherSaveConfirmDialogState extends State<VoucherSaveConfirmDialog> {
  final FocusNode _saveFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus the save button as soon as dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _saveFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summaryData;
    final isInterState = s['isInterState'] == true;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.verified_outlined, color: Color(0xFF0F62FE), size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirm ${s['voucherType']}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF101B3A)),
                    ),
                    Text(
                      'Verify summary details before persisting',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7B9B)),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF90A1BA)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Metadata Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2EAF5)),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Voucher No.', s['voucherNumber']),
                  const SizedBox(height: 6),
                  _buildSummaryRow('Date', s['date']),
                  const SizedBox(height: 6),
                  _buildSummaryRow('Party', s['party']),
                  const SizedBox(height: 6),
                  _buildSummaryRow(
                    'GST Nature',
                    isInterState ? 'Inter-State (IGST)' : 'Intra-State (CGST+SGST)',
                    valueColor: isInterState ? const Color(0xFF7E22CE) : const Color(0xFF15803D),
                  ),
                  const SizedBox(height: 6),
                  _buildSummaryRow('Total Items / Qty', '${s['itemCount']} items (${s['totalQty']} units)'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Accounting Totals
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2EAF5)),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Taxable Amount', '₹${(s['subTotal'] as double).toStringAsFixed(2)}'),
                  const SizedBox(height: 6),
                  if (!isInterState) ...[
                    _buildSummaryRow('CGST Total', '₹${(s['cgst'] as double).toStringAsFixed(2)}'),
                    const SizedBox(height: 6),
                    _buildSummaryRow('SGST Total', '₹${(s['sgst'] as double).toStringAsFixed(2)}'),
                  ] else ...[
                    _buildSummaryRow('IGST Total', '₹${(s['igst'] as double).toStringAsFixed(2)}'),
                  ],
                  if ((s['sundryTotal'] as double) != 0.0) ...[
                    const SizedBox(height: 6),
                    _buildSummaryRow('Bill Sundries', '₹${(s['sundryTotal'] as double).toStringAsFixed(2)}'),
                  ],
                  if ((s['roundOff'] as double) != 0.0) ...[
                    const SizedBox(height: 6),
                    _buildSummaryRow('Round Off', '₹${(s['roundOff'] as double).toStringAsFixed(2)}'),
                  ],
                  const Divider(height: 18, color: Color(0xFFE2EAF5)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Grand Total',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF101B3A)),
                      ),
                      Text(
                        '₹${(s['grandTotal'] as double).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F62FE)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Actions (Save focused by default)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cancel (Esc)'),
                ),
                const SizedBox(width: 12),
                Focus(
                  focusNode: _saveFocusNode,
                  child: Builder(builder: (context) {
                    final hasFocus = Focus.of(context).hasFocus;
                    return ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F62FE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: hasFocus ? const Color(0xFF101B3A) : Colors.transparent,
                            width: 2.0,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: const Text(
                        'Confirm & Save (Enter)',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7B9B)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor ?? const Color(0xFF101B3A),
          ),
        ),
      ],
    );
  }
}