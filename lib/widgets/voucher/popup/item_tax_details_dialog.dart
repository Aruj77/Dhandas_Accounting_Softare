import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/app_colors.dart';
import '../../../services/focus_policy_service.dart';
import '../../../utils/math_expression_evaluator.dart';
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

  final FocusNode _taxableFocusNode = FocusNode();
  final FocusNode _cgstFocusNode = FocusNode();
  final FocusNode _sgstFocusNode = FocusNode();
  final FocusNode _igstFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _taxableCtrl = TextEditingController(text: widget.row.taxable.text);
    _cgstCtrl = TextEditingController(text: widget.row.cgst.text);
    _sgstCtrl = TextEditingController(text: widget.row.sgst.text);
    _igstCtrl = TextEditingController(text: widget.row.igst.text);

    _taxableFocusNode.addListener(() {
      if (!_taxableFocusNode.hasFocus) _evaluateField(_taxableCtrl);
    });
    _cgstFocusNode.addListener(() {
      if (!_cgstFocusNode.hasFocus) _evaluateField(_cgstCtrl);
    });
    _sgstFocusNode.addListener(() {
      if (!_sgstFocusNode.hasFocus) _evaluateField(_sgstCtrl);
    });
    _igstFocusNode.addListener(() {
      if (!_igstFocusNode.hasFocus) _evaluateField(_igstCtrl);
    });
  }

  bool _evaluateField(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) return false;

    final evaluated = MathExpressionEvaluator.tryEvaluate(text);
    if (evaluated != null) {
      final formatted = MathExpressionEvaluator.formatResult(evaluated);
      if (controller.text != formatted) {
        controller.text = formatted;
        controller.selection = TextSelection.collapsed(offset: formatted.length);
        return true;
      }
    }
    return false;
  }

  void _applyChanges() {
    _evaluateField(_taxableCtrl);
    _evaluateField(_cgstCtrl);
    _evaluateField(_sgstCtrl);
    _evaluateField(_igstCtrl);

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
    _taxableFocusNode.dispose();
    _cgstCtrl.dispose();
    _cgstFocusNode.dispose();
    _sgstCtrl.dispose();
    _sgstFocusNode.dispose();
    _igstCtrl.dispose();
    _igstFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemName = widget.row.item.text.isNotEmpty ? widget.row.item.text : 'Item Line';

    return AutoScreenFocus(
      screen: FocusTargetScreen.itemTaxDetailsDialog,
      nodeMap: {
        FocusFieldNode.firstField: _taxableFocusNode,
      },
      child: Dialog(
        backgroundColor: AppColors.surface,
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
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calculate_outlined, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tax Details: $itemName',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.isInterState ? 'Inter-State Transaction (IGST)' : 'Intra-State Transaction (CGST + SGST)',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTaxInput(
                label: 'Taxable Value (₹)',
                controller: _taxableCtrl,
                focusNode: _taxableFocusNode,
                onSubmitted: () {
                  _evaluateField(_taxableCtrl);
                  if (widget.isInterState) {
                    _igstFocusNode.requestFocus();
                  } else {
                    _cgstFocusNode.requestFocus();
                  }
                },
              ),
              const SizedBox(height: 10),
              if (!widget.isInterState) ...[
                _buildTaxInput(
                  label: 'Central GST (CGST ₹)',
                  controller: _cgstCtrl,
                  focusNode: _cgstFocusNode,
                  onSubmitted: () {
                    _evaluateField(_cgstCtrl);
                    _sgstFocusNode.requestFocus();
                  },
                ),
                const SizedBox(height: 10),
                _buildTaxInput(
                  label: 'State GST (SGST ₹)',
                  controller: _sgstCtrl,
                  focusNode: _sgstFocusNode,
                  onSubmitted: () {
                    _evaluateField(_sgstCtrl);
                    _applyChanges();
                  },
                ),
              ] else ...[
                _buildTaxInput(
                  label: 'Integrated GST (IGST ₹)',
                  controller: _igstCtrl,
                  focusNode: _igstFocusNode,
                  onSubmitted: () {
                    _evaluateField(_igstCtrl);
                    _applyChanges();
                  },
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _applyChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                    ),
                    child: const Text('Apply Details', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaxInput({
    required String label,
    required TextEditingController controller,
    FocusNode? focusNode,
    VoidCallback? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        SizedBox(
          height: 36,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.+\-*/() ]')),
            ],
            onSubmitted: (_) => onSubmitted?.call(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: AppColors.cardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.3)),
            ),
          ),
        ),
      ],
    );
  }
}