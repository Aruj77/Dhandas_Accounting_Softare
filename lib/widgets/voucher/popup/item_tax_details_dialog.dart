import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../voucher_item_row.dart';

class ItemTaxDetailsDialog extends StatefulWidget {
  final VoucherItemRow row;
  final bool isInterState;
  final VoidCallback onUpdated;

  const ItemTaxDetailsDialog({
    super.key,
    required this.row,
    required this.isInterState,
    required this.onUpdated,
  });

  @override
  State<ItemTaxDetailsDialog> createState() => _ItemTaxDetailsDialogState();
}

class _ItemTaxDetailsDialogState extends State<ItemTaxDetailsDialog> {
  late TextEditingController _cgstCtrl;
  late TextEditingController _sgstCtrl;
  late TextEditingController _igstCtrl;
  late TextEditingController _taxableCtrl;

  @override
  void initState() {
    super.initState();
    _taxableCtrl = TextEditingController(text: widget.row.taxable.text);
    _cgstCtrl = TextEditingController(text: widget.row.cgst.text);
    _sgstCtrl = TextEditingController(text: widget.row.sgst.text);
    _igstCtrl = TextEditingController(text: widget.row.igst.text);
  }

  void _applyChanges() {
    widget.row.taxable.text = _taxableCtrl.text.trim();
    widget.row.cgst.text = _cgstCtrl.text.trim();
    widget.row.sgst.text = _sgstCtrl.text.trim();
    widget.row.igst.text = _igstCtrl.text.trim();

    final t = double.tryParse(widget.row.taxable.text) ?? 0.0;
    final c = double.tryParse(widget.row.cgst.text) ?? 0.0;
    final s = double.tryParse(widget.row.sgst.text) ?? 0.0;
    final i = double.tryParse(widget.row.igst.text) ?? 0.0;

    final gross = t + (widget.isInterState ? i : (c + s));
    widget.row.amount.text = gross == 0 ? '' : gross.toStringAsFixed(2);

    widget.onUpdated();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _taxableCtrl.dispose();
    _cgstCtrl.dispose();
    _sgstCtrl.dispose();
    _igstCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemName = widget.row.item.text.isNotEmpty ? widget.row.item.text : 'Item Line';

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calculate_outlined, color: Color(0xFF0F62FE), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tax Details: $itemName',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF101B3A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.isInterState ? 'Inter-State Transaction (IGST)' : 'Intra-State Transaction (CGST + SGST)',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF6B7B9B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTaxInput(
              label: 'Taxable Value (₹)',
              controller: _taxableCtrl,
              autofocus: true,
            ),
            const SizedBox(height: 10),
            if (!widget.isInterState) ...[
              _buildTaxInput(
                label: 'Central GST (CGST ₹)',
                controller: _cgstCtrl,
              ),
              const SizedBox(height: 10),
              _buildTaxInput(
                label: 'State GST (SGST ₹)',
                controller: _sgstCtrl,
              ),
            ] else ...[
              _buildTaxInput(
                label: 'Integrated GST (IGST ₹)',
                controller: _igstCtrl,
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _applyChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F62FE),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply Details', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxInput({
    required String label,
    required TextEditingController controller,
    bool autofocus = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
        const SizedBox(height: 4),
        SizedBox(
          height: 36,
          child: TextField(
            controller: controller,
            autofocus: autofocus,
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF101B3A)),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: const Color(0xFFF8FAFD),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2EAF5))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2EAF5))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.3)),
            ),
          ),
        ),
      ],
    );
  }
}