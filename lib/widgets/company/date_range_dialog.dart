import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/focus_policy_service.dart';
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
  final FocusNode _fromFocusNode = FocusNode();
  final FocusNode _toFocusNode = FocusNode();
  String? _errorMessage;

  late final DateTime _fyStartDate;
  late final DateTime _fyEndDate;

  List<String> _availableSeries = ['All'];
  String _selectedSeries = 'All';
  bool _isLoadingSeries = true;

  @override
  void initState() {
    super.initState();
    final bounds = AppDateUtils.parseFinancialYearBounds(widget.financialYear);
    _fyStartDate = bounds.startDate;
    _fyEndDate = bounds.endDate;

    _fromCtrl = TextEditingController(text: AppDateUtils.formatDate(_fyStartDate));
    _toCtrl = TextEditingController(text: AppDateUtils.formatDate(_fyEndDate));
    _loadSeries();

    _fromFocusNode.addListener(() {
      if (!_fromFocusNode.hasFocus) {
        _formatAndValidateDate(_fromCtrl, isFromDate: true);
      }
    });

    _toFocusNode.addListener(() {
      if (!_toFocusNode.hasFocus) {
        _formatAndValidateDate(_toCtrl, isFromDate: false);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _fromFocusNode.canRequestFocus) {
        _fromFocusNode.requestFocus();
      }
    });
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
    _fromFocusNode.dispose();
    _toFocusNode.dispose();
    super.dispose();
  }

  /// Parses date with support for shortcuts like 1-5, 1/5, 0105, 1.5, etc.
  /// Also ensures the year resolved belongs inside the active financial year.
  DateTime? _resolveDate(String raw) {
    DateTime? parsed = AppDateUtils.parseDate(raw);
    if (parsed == null) return null;

    // If no year was explicitly typed (or defaulted to current calendar year),
    // align it into the company's active financial year range
    if (!raw.contains(RegExp(r'[-/.](20\d\d|\d\d)$'))) {
      final month = parsed.month;
      final year = (month >= 4) ? _fyStartDate.year : _fyEndDate.year;
      parsed = DateTime(year, month, parsed.day);
    }

    return parsed;
  }

  bool _formatAndValidateDate(TextEditingController ctrl, {required bool isFromDate}) {
    final text = ctrl.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = '${isFromDate ? "Starting" : "Ending"} date cannot be empty');
      return false;
    }

    final parsed = _resolveDate(text);
    if (parsed == null) {
      setState(() => _errorMessage = 'Invalid date format (${ctrl.text})');
      return false;
    }

    if (parsed.isBefore(_fyStartDate) || parsed.isAfter(_fyEndDate)) {
      setState(() => _errorMessage = 'Date must be within F.Y. ${widget.financialYear}');
      return false;
    }

    ctrl.text = AppDateUtils.formatDate(parsed);
    setState(() => _errorMessage = null);
    return true;
  }

  void _submit() {
    final fromValid = _formatAndValidateDate(_fromCtrl, isFromDate: true);
    final toValid = _formatAndValidateDate(_toCtrl, isFromDate: false);

    if (!fromValid || !toValid) return;

    final from = _resolveDate(_fromCtrl.text);
    final to = _resolveDate(_toCtrl.text);

    if (from == null || to == null) {
      setState(() => _errorMessage = 'Please enter valid dates');
      return;
    }

    if (from.isAfter(to)) {
      setState(() => _errorMessage = 'Starting Date cannot be after Ending Date');
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
    return AutoScreenFocus(
      screen: FocusTargetScreen.dateRangeDialog,
      nodeMap: {
        FocusFieldNode.firstField: _fromFocusNode,
      },
      child: AppDialogFrame(
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
                Expanded(
                  child: _buildDateField(
                    label: 'Starting Date',
                    ctrl: _fromCtrl,
                    focusNode: _fromFocusNode,
                    autofocus: true,
                    onSubmitted: () {
                      if (_formatAndValidateDate(_fromCtrl, isFromDate: true)) {
                        _toFocusNode.requestFocus();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    label: 'Ending Date',
                    ctrl: _toCtrl,
                    focusNode: _toFocusNode,
                    autofocus: false,
                    onSubmitted: _submit,
                  ),
                ),
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
                      'Supports quick date formats like 1-5, 1/5, 0105. Select a series or leave as "All" for F.Y. ${widget.financialYear}.',
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
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController ctrl,
    required FocusNode focusNode,
    bool autofocus = false,
    VoidCallback? onSubmitted,
  }) {
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final hasFocus = focusNode.hasFocus;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: hasFocus ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: hasFocus
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: TextField(
                controller: ctrl,
                focusNode: focusNode,
                autofocus: autofocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => onSubmitted?.call(),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.calendar_today_rounded,
                    size: 15,
                    color: hasFocus ? AppColors.primary : AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.cardBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderMedium),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}