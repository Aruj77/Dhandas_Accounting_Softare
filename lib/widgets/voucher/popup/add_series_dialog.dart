import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_decoration.dart';
import '../../../services/focus_policy_service.dart';

class AddSeriesDialog extends StatefulWidget {
  final Function(Map<String, dynamic> seriesData) onSeriesCreated;
  final Map<String, dynamic>? initialSeries;
  final bool isEdit;

  const AddSeriesDialog({
    super.key,
    required this.onSeriesCreated,
    this.initialSeries,
    this.isEdit = false,
  });

  @override
  State<AddSeriesDialog> createState() => _AddSeriesDialogState();
}

class _AddSeriesDialogState extends State<AddSeriesDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController(text: 'Main');
  final FocusNode _nameFocusNode = FocusNode();

  final TextEditingController _prefixController = TextEditingController();
  final TextEditingController _suffixController = TextEditingController();
  final TextEditingController _separatorController = TextEditingController(text: '/');
  final TextEditingController _startNumController = TextEditingController(text: '1');
  final FocusNode _startNumFocusNode = FocusNode();
  final TextEditingController _endNumController = TextEditingController(text: '99999999');

  String _numberingType = 'Automatic';
  String _renumberingFreq = 'Yearly';
  String _yearFormat = 'YYYY-YY';
  String _yearPosition = 'As Prefix';
  String _monthFormat = 'MMM';
  String _monthPosition = 'As Prefix';
  String _dateFormat = 'DD-MM-YYYY';
  String _datePosition = 'As Prefix';

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.initialSeries != null) {
      final s = widget.initialSeries!;
      _nameController.text = s['name']?.toString() ?? 'Main';
      _numberingType = s['numberingType']?.toString() ?? 'Automatic';
      _renumberingFreq = s['renumberingFreq']?.toString() ?? 'Yearly';
      _yearFormat = s['yearFormat']?.toString() ?? 'YYYY-YY';
      _yearPosition = s['yearPosition']?.toString() ?? 'As Prefix';
      _monthFormat = s['monthFormat']?.toString() ?? 'MMM';
      _monthPosition = s['monthPosition']?.toString() ?? 'As Prefix';
      _dateFormat = s['dateFormat']?.toString() ?? 'DD-MM-YYYY';
      _datePosition = s['datePosition']?.toString() ?? 'As Prefix';
      _separatorController.text = s['separator']?.toString() ?? '/';
      _prefixController.text = s['prefix']?.toString() ?? '';
      _suffixController.text = s['suffix']?.toString() ?? '';
      _startNumController.text = s['startNumber']?.toString() ?? '1';
      _endNumController.text = s['endNumber']?.toString() ?? '99999999';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _prefixController.dispose();
    _suffixController.dispose();
    _separatorController.dispose();
    _startNumController.dispose();
    _startNumFocusNode.dispose();
    _endNumController.dispose();
    super.dispose();
  }

  String _generatePreview() {
    if (_numberingType == 'Manual') {
      return '[User Defined / Blank]';
    }

    final sep = _separatorController.text.trim();
    final startNum = _startNumController.text.trim().isEmpty ? '1' : _startNumController.text.trim();
    final prefix = _prefixController.text.trim();
    final suffix = _suffixController.text.trim();

    List<String> parts = [];
    String periodComponent = '';

    if (_renumberingFreq == 'Yearly') {
      periodComponent = (_yearFormat == 'YY-YY') ? '26-27' : '2026-27';
    } else if (_renumberingFreq == 'Monthly') {
      if (_monthFormat == 'MMM') periodComponent = 'Sep';
      if (_monthFormat == 'M-full') periodComponent = 'September';
      if (_monthFormat == 'M-digit') periodComponent = '09';
    } else if (_renumberingFreq == 'Daily') {
      if (_dateFormat == 'DD-MM-YYYY') periodComponent = '19-09-2026';
      if (_dateFormat == 'DD/MM/YY') periodComponent = '19/09/26';
    }

    final activePosition = _renumberingFreq == 'Yearly'
        ? _yearPosition
        : _renumberingFreq == 'Monthly'
            ? _monthPosition
            : _datePosition;

    if (prefix.isNotEmpty) parts.add(prefix);

    if (_renumberingFreq != 'None' && activePosition == 'As Prefix' && periodComponent.isNotEmpty) {
      parts.add(periodComponent);
    }

    parts.add(startNum);

    if (_renumberingFreq != 'None' && activePosition == 'As Suffix' && periodComponent.isNotEmpty) {
      parts.add(periodComponent);
    }

    if (suffix.isNotEmpty) parts.add(suffix);

    return parts.join(sep);
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final seriesData = {
      'name': _nameController.text.trim(),
      'numberingType': _numberingType,
      'renumberingFreq': _renumberingFreq,
      'yearFormat': _yearFormat,
      'yearPosition': _yearPosition,
      'monthFormat': _monthFormat,
      'monthPosition': _monthPosition,
      'dateFormat': _dateFormat,
      'datePosition': _datePosition,
      'separator': _separatorController.text.trim(),
      'prefix': _prefixController.text.trim(),
      'suffix': _suffixController.text.trim(),
      'startNumber': int.tryParse(_startNumController.text.trim()) ?? 1,
      'endNumber': int.tryParse(_endNumController.text.trim()) ?? 99999999,
    };

    widget.onSeriesCreated(seriesData);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final showAutomaticFields = _numberingType == 'Automatic';
    final isYearly = showAutomaticFields && _renumberingFreq == 'Yearly';
    final isMonthly = showAutomaticFields && _renumberingFreq == 'Monthly';
    final isDaily = showAutomaticFields && _renumberingFreq == 'Daily';

    return AutoScreenFocus(
      screen: FocusTargetScreen.addSeriesDialog,
      nodeMap: {
        FocusFieldNode.seriesNameField: _nameFocusNode,
        FocusFieldNode.startNumberField: _startNumFocusNode,
      },
      child: Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: math.min(MediaQuery.of(context).size.width * 0.9, 720),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.format_list_numbered_rounded, size: 22, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isEdit ? 'Configure Voucher Series' : 'Create New Voucher Series',
                            style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Dynamic numbering structure, renumbering frequencies, and format rules',
                            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Live Preview Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderMedium),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.preview_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 10),
                        const Text(
                          'Live Voucher No. Preview: ',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                        ),
                        Text(
                          _generatePreview(),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Series Name & Numbering Type
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          label: 'Series Name *',
                          hintText: 'e.g., Main, POS, Online',
                          validator: (val) => val == null || val.trim().isEmpty ? 'Series name required' : null,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildDropdown(
                          label: 'Numbering Type *',
                          value: _numberingType,
                          items: const ['Automatic', 'Manual'],
                          onChanged: (val) => setState(() => _numberingType = val ?? 'Automatic'),
                        ),
                      ),
                    ],
                  ),

                  if (showAutomaticFields) ...[
                    const SizedBox(height: 14),

                    _buildDropdown(
                      label: 'Renumbering Frequency *',
                      value: _renumberingFreq,
                      items: const ['None', 'Yearly', 'Monthly', 'Daily'],
                      onChanged: (val) => setState(() => _renumberingFreq = val ?? 'None'),
                    ),

                    if (isYearly) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: 'Year Format *',
                              value: _yearFormat,
                              items: const ['YY-YY', 'YYYY-YY'],
                              onChanged: (val) => setState(() => _yearFormat = val ?? 'YYYY-YY'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Year Position *',
                              value: _yearPosition,
                              items: const ['As Prefix', 'As Suffix'],
                              onChanged: (val) => setState(() => _yearPosition = val ?? 'As Prefix'),
                            ),
                          ),
                        ],
                      ),
                    ] else if (isMonthly) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: 'Month Format *',
                              value: _monthFormat,
                              items: const ['MMM', 'M-full', 'M-digit'],
                              onChanged: (val) => setState(() => _monthFormat = val ?? 'MMM'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Month Position *',
                              value: _monthPosition,
                              items: const ['As Prefix', 'As Suffix'],
                              onChanged: (val) => setState(() => _monthPosition = val ?? 'As Prefix'),
                            ),
                          ),
                        ],
                      ),
                    ] else if (isDaily) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: 'Date Format *',
                              value: _dateFormat,
                              items: const ['DD-MM-YYYY', 'DD/MM/YY'],
                              onChanged: (val) => setState(() => _dateFormat = val ?? 'DD-MM-YYYY'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Date Position *',
                              value: _datePosition,
                              items: const ['As Prefix', 'As Suffix'],
                              onChanged: (val) => setState(() => _datePosition = val ?? 'As Prefix'),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _separatorController,
                            label: 'Separator',
                            hintText: 'e.g. / or -',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildTextField(
                            controller: _prefixController,
                            label: 'Custom Prefix',
                            hintText: 'e.g. INV',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildTextField(
                            controller: _suffixController,
                            label: 'Custom Suffix',
                            hintText: 'e.g. EXP',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            controller: _startNumController,
                            focusNode: _startNumFocusNode,
                            label: 'Start Number *',
                            validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildNumberField(
                            controller: _endNumController,
                            label: 'End Number (Default Infinity)',
                            hintText: '99999999',
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: const BorderSide(color: AppColors.border),
                          foregroundColor: AppColors.textPrimary,
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.surface,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: Text(
                          widget.isEdit ? 'Save Changes' : 'Save & Create Series',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: DropdownButtonFormField<String>(
            value: value,
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))))
                .toList(),
            onChanged: onChanged,
            // Replaced duplicated border definitions with AppDecorations.standard
            decoration: AppDecorations.standard(
              label: '',
              hintText: '',
            ).copyWith(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            validator: validator,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            // Replaced duplicated OutlineInputBorders with AppDecorations.standard
            decoration: AppDecorations.standard(
              label: '',
              hintText: hintText,
            ).copyWith(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            validator: validator,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            // Replaced duplicated OutlineInputBorders with AppDecorations.standard
            decoration: AppDecorations.standard(
              label: '',
              hintText: hintText,
            ).copyWith(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }
}