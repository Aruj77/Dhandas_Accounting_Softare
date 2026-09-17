import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../utils/app_date_utils.dart';
import '../common/app_dialog_frame.dart';

class DateRangeDialog extends StatefulWidget {
  final String financialYear;
  final String voucherType;

  const DateRangeDialog({
    super.key,
    required this.financialYear,
    required this.voucherType,
  });

  @override
  State<DateRangeDialog> createState() => _DateRangeDialogState();
}

class _DateRangeDialogState extends State<DateRangeDialog> {
  late final TextEditingController _fromCtrl;
  late final TextEditingController _toCtrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final bounds = AppDateUtils.parseFinancialYearBounds(widget.financialYear);
    _fromCtrl = TextEditingController(text: AppDateUtils.formatDate(bounds.startDate));
    _toCtrl = TextEditingController(text: AppDateUtils.formatDate(bounds.endDate));
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final from = AppDateUtils.parseDate(_fromCtrl.text);
    final to = AppDateUtils.parseDate(_toCtrl.text);

    if (from == null || to == null) {
      setState(() => _errorMessage = 'Please enter valid dates (DD-MM-YYYY)');
      return;
    }

    if (from.isAfter(to)) {
      setState(() => _errorMessage = 'From Date cannot be after To Date');
      return;
    }

    Navigator.of(context).pop({'from': from, 'to': to});
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogFrame(
      title: 'Select Date Range',
      subtitle: '${widget.voucherType} Register • F.Y. ${widget.financialYear}',
      icon: Icons.date_range_rounded,
      maxWidth: 460,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildDateField('Starting Date', _fromCtrl)),
              const SizedBox(width: 16),
              Expanded(child: _buildDateField('Ending Date', _toCtrl)),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.error),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD6E4FA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pre-filled with F.Y. ${widget.financialYear} period. You can narrow this range to view specific monthly or quarterly registers.',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF274375), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.table_view_rounded, size: 16),
          label: const Text('Show List (Enter)', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.cardBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
            ),
          ),
        ),
      ],
    );
  }
}