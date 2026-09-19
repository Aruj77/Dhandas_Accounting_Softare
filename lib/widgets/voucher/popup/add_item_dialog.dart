import 'package:flutter/material.dart';
import '../../../models/item_master_model.dart';

class AddItemDialog extends StatefulWidget {
  final Function(Map<String, dynamic> itemData) onItemCreated;
  final ItemMasterModel? initialItem;
  final bool isEdit;

  const AddItemDialog({
    super.key,
    required this.onItemCreated,
    this.initialItem,
    this.isEdit = false,
  });

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _hsnController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _salesPriceController = TextEditingController();
  final TextEditingController _purchasePriceController = TextEditingController();
  final TextEditingController _mrpController = TextEditingController();

  static const List<String> _units = [
    'Kgs',
    'Pcs',
    'Mtr',
    'Nos',
    'Ltr',
    'Mlt',
    'Box',
    'Ton',
    'Doz',
    'Sqm',
    'Set',
    'Cbm',
    'Bag',
    'Qtl',
    'Oth',
  ];

  static const List<String> _taxCategories = [
    '0% Exempt',
    'GST 3%',
    'GST 5%',
    'GST 12%',
    'GST 18%',
    'GST 28%',
    'GST 40%',
  ];

  String _selectedUnit = 'Pcs';
  String _selectedTaxCategory = 'GST 18%';
  String? _hsnStatusMessage;
  bool _isHsnValid = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.initialItem != null) {
      final item = widget.initialItem!;
      _nameController.text = item.name;
      _hsnController.text = item.hsn;
      _selectedUnit = _units.contains(item.unit) ? item.unit : 'Pcs';
      _selectedTaxCategory = _taxCategories.firstWhere(
        (c) => c.contains('${item.taxRate.toInt()}%'),
        orElse: () => _taxCategories.contains(item.taxCategory) ? item.taxCategory : 'GST 18%',
      );
      _salesPriceController.text = item.salesPrice > 0 ? item.salesPrice.toStringAsFixed(2) : '';
      _purchasePriceController.text = item.purchasePrice > 0 ? item.purchasePrice.toStringAsFixed(2) : '';
      _mrpController.text = item.mrp > 0 ? item.mrp.toStringAsFixed(2) : '';
      if (item.hsn.isNotEmpty) _validateHsn();
    }

    _hsnController.addListener(_autoGenerateName);
  }

  String _extractTaxPercentage(String category) {
    if (category.contains('0%')) return '0%';
    final match = RegExp(r'(\d+)%').firstMatch(category);
    return match != null ? '${match.group(1)}%' : '18%';
  }

  void _autoGenerateName() {
    // Removed 'if (widget.isEdit) return;' so name updates dynamically in edit mode too
    final hsn = _hsnController.text.trim();
    final tax = _extractTaxPercentage(_selectedTaxCategory);
    final unit = _selectedUnit;

    if (hsn.isNotEmpty) {
      _nameController.text = '$hsn $tax $unit';
    } else {
      _nameController.text = '';
    }
  }

  void _validateHsn() {
    final hsn = _hsnController.text.trim();
    if (hsn.isEmpty) {
      setState(() {
        _hsnStatusMessage = 'Please enter an HSN/SAC code.';
        _isHsnValid = false;
      });
      return;
    }

    final isValid = RegExp(r'^[0-9]{4,8}$').hasMatch(hsn);
    setState(() {
      _isHsnValid = isValid;
      _hsnStatusMessage = isValid
          ? 'Valid HSN/SAC code format'
          : 'Invalid HSN. Must be 4 to 8 digits numeric.';
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.isEdit) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 22),
              ),
              const SizedBox(width: 10),
              const Text(
                'Warning',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          content: const Text(
            'All previous transactions will be changed accordingly. Do you want to continue?',
            style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF475569),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              child: const Text('No', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F62FE),
                elevation: 0,
              ),
              child: const Text('Yes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );

      if (shouldContinue != true) return;
    }

    final taxMatch = RegExp(r'(\d+)%').firstMatch(_selectedTaxCategory);
    final rate = taxMatch != null ? double.tryParse(taxMatch.group(1)!) ?? 18.0 : 0.0;

    final itemData = {
      'name': _nameController.text.trim(),
      'hsn': _hsnController.text.trim(),
      'unit': _selectedUnit,
      'taxCategory': _selectedTaxCategory,
      'taxRate': rate,
      'salesPrice': double.tryParse(_salesPriceController.text.trim()) ?? 0.0,
      'purchasePrice': double.tryParse(_purchasePriceController.text.trim()) ?? 0.0,
      'mrp': double.tryParse(_mrpController.text.trim()) ?? 0.0,
    };

    widget.onItemCreated(itemData);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _hsnController.dispose();
    _nameController.dispose();
    _salesPriceController.dispose();
    _purchasePriceController.dispose();
    _mrpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.isEdit ? Icons.edit_note_rounded : Icons.inventory_2_rounded,
                      size: 20,
                      color: const Color(0xFF0F62FE),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEdit ? 'Edit Item Master' : 'Add New Item Master',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF101B3A)),
                      ),
                      Text(
                        widget.isEdit
                            ? 'Update inventory and tariff configuration'
                            : 'Inventory and tariff configuration',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7B9B)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF6B7B9B)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: _buildTextField(
                      controller: _hsnController,
                      label: 'HSN / SAC Code *',
                      hintText: 'e.g. 3304',
                      validator: (val) => val == null || val.trim().isEmpty ? 'HSN code is required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: ElevatedButton.icon(
                      onPressed: _validateHsn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F62FE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.verified_outlined, size: 16),
                      label: const Text('Validate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
              if (_hsnStatusMessage != null) ...[
                const SizedBox(height: 4),
                Text(
                  _hsnStatusMessage!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _isHsnValid ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'Unit *',
                      value: _selectedUnit,
                      items: _units,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedUnit = val;
                            _autoGenerateName();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Tax Category *',
                      value: _selectedTaxCategory,
                      items: _taxCategories,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedTaxCategory = val;
                            _autoGenerateName();
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _nameController,
                label: 'Item Name *',
                hintText: 'Enter item master name',
                validator: (val) => val == null || val.trim().isEmpty ? 'Item name cannot be empty' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _salesPriceController,
                      label: 'Sales Price (₹)',
                      hintText: '0.00',
                      keyboardType: const TextInputMulOption(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _purchasePriceController,
                      label: 'Purchase Price (₹)',
                      hintText: '0.00',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _mrpController,
                      label: 'MRP (₹)',
                      hintText: '0.00',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
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
                      backgroundColor: const Color(0xFF0F62FE),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      widget.isEdit ? 'Save Changes' : 'Save & Select Item',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
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
        Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
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
              fillColor: const Color(0xFFFAFBFD),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5EDF7))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5EDF7))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.4)),
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
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF101B3A)),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF90A1BA)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: const Color(0xFFFAFBFD),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5EDF7))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5EDF7))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.4)),
            ),
          ),
        ),
      ],
    );
  }
}

class TextInputMulOption extends TextInputType {
  const TextInputMulOption() : super.numberWithOptions(decimal: true);
}