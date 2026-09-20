import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/storage_service.dart';
import '../../utils/app_date_utils.dart';
import '../common/app_dialog_frame.dart';
import '../../../services/loading_service.dart';

class DateRangeDialog extends StatefulWidget {
  final Map<String, dynamic> company;
  final String financialYear;
  final String voucherType;

  const DateRangeDialog({
    super.key,
    required this.company,
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

  List<String> _availableSeries = ['All'];
  String _selectedSeries = 'All';
  bool _isLoadingSeries = true;

  @override
  void initState() {
    super.initState();
    final bounds = AppDateUtils.parseFinancialYearBounds(widget.financialYear);
    _fromCtrl = TextEditingController(text: AppDateUtils.formatDate(bounds.startDate));
    _toCtrl = TextEditingController(text: AppDateUtils.formatDate(bounds.endDate));
    _loadSeries();
  }

  Future<void> _loadSeries() async {
    await LoadingService.wrap(() async {
      try {
        final folderPath = widget.company['folderPath']?.toString();
        final seriesList = <String>['All'];
        if (folderPath != null) {
          final rawMasters = await StorageService.loadCompanyMasters(folderPath: folderPath);
          final loadedSeries = rawMasters['series'] as List? ?? ['Main'];
          for (final s in loadedSeries) {
            if (s != null && s.toString().trim().isNotEmpty) {
              final name = s.toString().trim();
              if (!seriesList.contains(name)) {
                seriesList.add(name);
              }
            }
          }
        }
        if (!seriesList.contains('Main')) {
          seriesList.add('Main');
        }
        if (mounted) {
          setState(() {
            _availableSeries = seriesList;
            _isLoadingSeries = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoadingSeries = false);
      }
    }, message: '');
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

    Navigator.of(context).pop({
      'from': from,
      'to': to,
      'series': _selectedSeries,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogFrame(
      title: 'Select Register Options',
      subtitle: '${widget.voucherType} Register • F.Y. ${widget.financialYear}',
      icon: Icons.date_range_rounded,
      maxWidth: 480,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Voucher Series',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          _isLoadingSeries
              ? const SizedBox(
                  height: 38,
                  child: Center(child: LinearProgressIndicator(minHeight: 2, color: AppColors.primary)),
                )
              : DropdownButtonFormField<String>(
                  value: _selectedSeries,
                  items: _availableSeries
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSeries = val);
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: AppColors.cardBg,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.borderMedium),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
                    ),
                  ),
                ),
          const SizedBox(height: 16),
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
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select a specific series or leave as "All" to view combined transactions for F.Y. ${widget.financialYear}.',
                    style: const TextStyle(fontSize: 11, color: AppColors.primaryDark, height: 1.3),
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
            foregroundColor: AppColors.surface,
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
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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
              borderSide: const BorderSide(color: AppColors.borderMedium),
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