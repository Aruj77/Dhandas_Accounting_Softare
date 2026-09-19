import 'dart:async';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/item_master_model.dart';
import '../../../services/storage_service.dart';

class AddItemDialog extends StatefulWidget {
  final FutureOr<void> Function(Map<String, dynamic> itemData)? onItemCreated;
  final ItemMasterModel? initialItem;
  final bool isEdit;
  final Map<String, dynamic>? company;
  final String? folderPath;

  const AddItemDialog({
    super.key,
    this.onItemCreated,
    this.initialItem,
    this.isEdit = false,
    this.company,
    this.folderPath,
  });

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _hsnController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final FocusNode _unitFocusNode = FocusNode();
  final ScrollController _unitOptionsScrollController = ScrollController();
  final TextEditingController _salesPriceController = TextEditingController();
  final TextEditingController _purchasePriceController = TextEditingController();
  final TextEditingController _mrpController = TextEditingController();

  List<String> _units = (StorageService.defaultCompanyMasters['units'] as List? ?? [])
      .map((e) => e.toString())
      .toList();

  List<String> _taxCategories =
      (StorageService.defaultCompanyMasters['taxCategories'] as List? ?? [])
          .map((e) => e.toString())
          .toList();

  String _selectedTaxCategory = 'GST 18%';
  String? _hsnStatusMessage;
  bool _isHsnValid = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadMastersData();

    if (widget.isEdit && widget.initialItem != null) {
      final item = widget.initialItem!;
      _nameController.text = item.name;
      _hsnController.text = item.hsn;

      final matchedUnit = _units
          .where((u) => u.toLowerCase() == item.unit.trim().toLowerCase())
          .firstOrNull;
      _unitController.text = matchedUnit ?? item.unit.toUpperCase();

      _selectedTaxCategory = _taxCategories.firstWhere(
        (c) => c.contains('${item.taxRate.toInt()}%'),
        orElse: () => _taxCategories.contains(item.taxCategory) ? item.taxCategory : 'GST 18%',
      );
      _salesPriceController.text = item.salesPrice > 0 ? item.salesPrice.toStringAsFixed(2) : '';
      _purchasePriceController.text = item.purchasePrice > 0 ? item.purchasePrice.toStringAsFixed(2) : '';
      _mrpController.text = item.mrp > 0 ? item.mrp.toStringAsFixed(2) : '';
      if (item.hsn.isNotEmpty) _validateHsn();
    } else {
      _unitController.text = _units.isNotEmpty ? _units.first : '';
      _selectedTaxCategory = _taxCategories.isNotEmpty ? _taxCategories.first : 'GST 18%';
    }

    _hsnController.addListener(_autoGenerateName);
    _unitController.addListener(_autoGenerateName);
  }

  Future<void> _loadMastersData() async {
    final path = widget.folderPath ?? widget.company?['folderPath']?.toString();
    if (path == null || path.isEmpty) return;

    final raw = await StorageService.loadCompanyMasters(folderPath: path);
    if (!mounted) return;

    setState(() {
      if (raw['units'] is List && (raw['units'] as List).isNotEmpty) {
        _units = (raw['units'] as List).map((e) => e.toString()).toList();
      }
      if (raw['taxCategories'] is List && (raw['taxCategories'] as List).isNotEmpty) {
        _taxCategories = (raw['taxCategories'] as List).map((e) => e.toString()).toList();
      }

      if (!_taxCategories.contains(_selectedTaxCategory)) {
        _selectedTaxCategory = _taxCategories.isNotEmpty ? _taxCategories.first : 'GST 18%';
      }
    });
  }

  String _extractTaxPercentage(String category) {
    if (category.contains('0%')) return '0%';
    final match = RegExp(r'(\d+)%').firstMatch(category);
    return match != null ? '${match.group(1)}%' : '18%';
  }

  void _autoGenerateName() {
    final hsn = _hsnController.text.trim();
    final tax = _extractTaxPercentage(_selectedTaxCategory);
    final unit = _unitController.text.trim().toUpperCase();

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
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.badgeYellowBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 22),
              ),
              const SizedBox(width: 10),
              const Text(
                'Warning',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ],
          ),
          content: const Text(
            'All previous transactions will be changed accordingly. Do you want to continue?',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.borderMedium),
              ),
              child: const Text('No', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
              ),
              child: const Text('Yes', style: TextStyle(color: AppColors.surface, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );

      if (shouldContinue != true) return;
    }

    setState(() => _isSaving = true);

    final taxMatch = RegExp(r'(\d+)%').firstMatch(_selectedTaxCategory);
    final rate = taxMatch != null ? double.tryParse(taxMatch.group(1)!) ?? 18.0 : 0.0;

    final itemData = {
      'name': _nameController.text.trim(),
      'hsn': _hsnController.text.trim(),
      'unit': _unitController.text.trim().isEmpty ? 'PCS' : _unitController.text.trim().toUpperCase(),
      'taxCategory': _selectedTaxCategory,
      'taxRate': rate,
      'salesPrice': double.tryParse(_salesPriceController.text.trim()) ?? 0.0,
      'purchasePrice': double.tryParse(_purchasePriceController.text.trim()) ?? 0.0,
      'mrp': double.tryParse(_mrpController.text.trim()) ?? 0.0,
    };

    final path = widget.folderPath ?? widget.company?['folderPath']?.toString();
    if (path != null && path.isNotEmpty) {
      try {
        final raw = await StorageService.loadCompanyMasters(folderPath: path);
        final itemsList = (raw['items'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        final originalName = widget.initialItem?.name.trim().toLowerCase();
        final newName = itemData['name'].toString().trim().toLowerCase();

        final idx = itemsList.indexWhere((i) {
          final n = (i['name'] ?? '').toString().trim().toLowerCase();
          return widget.isEdit && originalName != null && originalName.isNotEmpty
              ? n == originalName
              : n == newName;
        });

        if (idx != -1) {
          itemsList[idx] = itemData;
        } else {
          itemsList.add(itemData);
        }

        raw['items'] = itemsList;
        await StorageService.saveCompanyMasters(folderPath: path, mastersData: raw);
      } catch (e) {
        debugPrint('Error saving item: $e');
      }
    }

    if (widget.onItemCreated != null) {
      await widget.onItemCreated!(itemData);
    }

    if (mounted) {
      Navigator.of(context).pop(itemData);
    }
  }

  @override
  void dispose() {
    _hsnController.dispose();
    _nameController.dispose();
    _unitController.dispose();
    _unitFocusNode.dispose();
    _unitOptionsScrollController.dispose();
    _salesPriceController.dispose();
    _purchasePriceController.dispose();
    _mrpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
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
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.isEdit ? Icons.edit_note_rounded : Icons.inventory_2_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEdit ? 'Edit Item Master' : 'Add New Item Master',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      Text(
                        widget.isEdit
                            ? 'Update inventory and tariff configuration'
                            : 'Inventory and tariff configuration',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
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
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.surface,
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
                    color: _isHsnValid ? AppColors.successDark : AppColors.errorDark,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildUnitAutocompleteField(),
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _purchasePriceController,
                      label: 'Purchase Price (₹)',
                      hintText: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _mrpController,
                      label: 'MRP (₹)',
                      hintText: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: AppColors.surface, strokeWidth: 2),
                          )
                        : Text(
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

  Widget _buildUnitAutocompleteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Unit *',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            return RawAutocomplete<String>(
              textEditingController: _unitController,
              focusNode: _unitFocusNode,
              optionsBuilder: (TextEditingValue textEditingValue) {
                final query = textEditingValue.text.trim().toLowerCase();
                if (query.isEmpty) {
                  return _units;
                }
                return _units.where((u) => u.toLowerCase().contains(query));
              },
              onSelected: (String selection) {
                _unitController.text = selection;
                _autoGenerateName();
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return SizedBox(
                  height: 38,
                  child: TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    textCapitalization: TextCapitalization.characters,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Unit is required' : null,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'e.g. PCS',
                      hintStyle: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: AppColors.cardBg,
                      suffixIcon: const Icon(Icons.arrow_drop_down_rounded, size: 20, color: AppColors.textSecondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
                    ),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(8),
                    shadowColor: AppColors.shadowColor,
                    child: Container(
                      width: constraints.maxWidth,
                      constraints: const BoxConstraints(maxHeight: 228),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Scrollbar(
                        controller: _unitOptionsScrollController,
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: _unitOptionsScrollController,
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return InkWell(
                              onTap: () => onSelected(option),
                              hoverColor: AppColors.primaryLight,
                              child: Container(
                                height: 38,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  option,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final effectiveValue = items.contains(value) ? value : (items.isNotEmpty ? items.first : 'GST 18%');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: DropdownButtonFormField<String>(
            value: effectiveValue,
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))))
                .toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              filled: true,
              fillColor: AppColors.cardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
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
    TextInputType? keyboardType,
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
            validator: validator,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: AppColors.cardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
            ),
          ),
        ),
      ],
    );
  }
}