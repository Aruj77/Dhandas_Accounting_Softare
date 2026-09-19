import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/app_colors.dart';

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
  final TextEditingController _prefixController = TextEditingController();
  final TextEditingController _suffixController = TextEditingController();
  final TextEditingController _separatorController = TextEditingController(text: '/');
  final TextEditingController _startNumController = TextEditingController(text: '1');
  final TextEditingController _endNumController = TextEditingController(text: '99999999');

  String _numberingType = 'Automatic';
  String _renumberingFreq = 'None';
  String _yearFormat = 'YY-YY';
  String _yearPosition = 'As Prefix';
  String _monthFormat = 'MMM';
  String _dateFormat = 'DD-MM-YYYY';

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.initialSeries != null) {
      final s = widget.initialSeries!;
      _nameController.text = s['name']?.toString() ?? 'Main';
      _numberingType = s['numberingType']?.toString() ?? 'Automatic';
      _renumberingFreq = s['renumberingFreq']?.toString() ?? 'None';
      _yearFormat = s['yearFormat']?.toString() ?? 'YY-YY';
      _yearPosition = s['yearPosition']?.toString() ?? 'As Prefix';
      _monthFormat = s['monthFormat']?.toString() ?? 'MMM';
      _dateFormat = s['dateFormat']?.toString() ?? 'DD-MM-YYYY';
      _separatorController.text = s['separator']?.toString() ?? '-';
      _prefixController.text = s['prefix']?.toString() ?? '';
      _suffixController.text = s['suffix']?.toString() ?? '';
      _startNumController.text = s['startNumber']?.toString() ?? '1';
      _endNumController.text = s['endNumber']?.toString() ?? '99999999';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _prefixController.dispose();
    _suffixController.dispose();
    _separatorController.dispose();
    _startNumController.dispose();
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
    String dateComponent = '';
    if (_renumberingFreq == 'Yearly') {
      dateComponent = (_yearFormat == 'YY-YY') ? '26-27' : '2026-27';
    } else if (_renumberingFreq == 'Monthly') {
      if (_monthFormat == 'MMM') dateComponent = 'Sep';
      if (_monthFormat == 'M-full') dateComponent = 'September';
      if (_monthFormat == 'M-digit') dateComponent = '09';
    } else if (_renumberingFreq == 'Daily') {
      if (_dateFormat == 'DD-MM-YYYY') dateComponent = '19-09-2026';
      if (_dateFormat == 'DD/MM/YY') dateComponent = '19/09/26';
    }

    if (prefix.isNotEmpty) parts.add(prefix);
    if (_renumberingFreq == 'Yearly' && _yearPosition == 'As Prefix' && dateComponent.isNotEmpty) {
      parts.add(dateComponent);
    }
    parts.add(startNum);
    if (_renumberingFreq == 'Yearly' && _yearPosition == 'As Suffix' && dateComponent.isNotEmpty) {
      parts.add(dateComponent);
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
      'dateFormat': _dateFormat,
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

    return Dialog(
      backgroundColor: Colors.white,
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
                          style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Dynamic numbering structure, renumbering frequencies, and format rules',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.preview_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      const Text(
                        'Live Voucher No. Preview: ',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                      ),
                      Text(
                        _generatePreview(),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _nameController,
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
                            onChanged: (val) => setState(() => _yearFormat = val ?? 'YY-YY'),
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
                    _buildDropdown(
                      label: 'Add Month in Voucher No. *',
                      value: _monthFormat,
                      items: const ['None', 'MMM', 'M-full', 'M-digit'],
                      onChanged: (val) => setState(() => _monthFormat = val ?? 'MMM'),
                    ),
                  ] else if (isDaily) ...[
                    const SizedBox(height: 14),
                    _buildDropdown(
                      label: 'Add Date Format in Voucher No. *',
                      value: _dateFormat,
                      items: const ['None', 'DD-MM-YYYY', 'DD/MM/YY'],
                      onChanged: (val) => setState(() => _dateFormat = val ?? 'DD-MM-YYYY'),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _separatorController,
                          label: 'Separator',
                          hintText: 'e.g. - or / (Leave blank for none)',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildTextField(
                          controller: _prefixController,
                          label: 'Prefix',
                          hintText: 'e.g. INV',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildTextField(
                          controller: _suffixController,
                          label: 'Suffix',
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
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
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
        Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: DropdownButtonFormField<String>(
            value: value,
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))))
                .toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              filled: true,
              fillColor: const Color(0xFFF8FAFD),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: TextFormField(
            controller: controller,
            validator: validator,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: const Color(0xFFF8FAFD),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: hintText,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: const Color(0xFFF8FAFD),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
            ),
          ),
        ),
      ],
    );
  }
}