import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../constants/app_colors.dart';
import '../../../models/item_master_model.dart';
import '../../../services/focus_policy_service.dart';
import '../../../api/hsn_master_data.dart';
import '../../../services/storage_service.dart';
import '../../../utils/smart_filter.dart';
import '../../common/app_confirm_dialog.dart';

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

  // ---------------------------------------------------------------------------
  // Controllers
  // ---------------------------------------------------------------------------

  final TextEditingController _hsnController = TextEditingController();
  final FocusNode _hsnFocusNode = FocusNode();

  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  final TextEditingController _unitController = TextEditingController();
  final FocusNode _unitFocusNode = FocusNode();
  final ScrollController _unitOptionsScrollController = ScrollController();

  final TextEditingController _taxCategoryController =
      TextEditingController();
  final FocusNode _taxCategoryFocusNode = FocusNode();
  final ScrollController _taxOptionsScrollController = ScrollController();

  final TextEditingController _salesPriceController = TextEditingController();
  final FocusNode _salesPriceFocusNode = FocusNode();

  final TextEditingController _purchasePriceController =
      TextEditingController();

  final TextEditingController _mrpController = TextEditingController();

  // ---------------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------------

  List<String> _units =
      (StorageService.defaultCompanyMasters['units'] as List? ?? [])
          .map((e) => e.toString())
          .toList();

  List<String> _taxCategories =
      (StorageService.defaultCompanyMasters['taxCategories'] as List? ?? [])
          .map((e) => e.toString())
          .toList();

  String _selectedTaxCategory = 'GST 18%';

  String? _hsnStatusMessage;

  bool _isHsnValid = false;
  bool _isValidatingHsn = false;
  bool _isSaving = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _loadMastersData();
    HsnService.loadRecords();

    if (widget.isEdit && widget.initialItem != null) {
      final item = widget.initialItem!;

      _nameController.text = item.name;
      _hsnController.text = item.hsn;

      final matchedUnit = _units
          .where(
            (u) => u.toLowerCase() == item.unit.trim().toLowerCase(),
          )
          .firstOrNull;

      _unitController.text =
          matchedUnit ??
          (_units.isNotEmpty ? _units.first : item.unit.toUpperCase());

      _selectedTaxCategory = _taxCategories.firstWhere(
        (c) => c.contains('${item.taxRate.toInt()}%'),
        orElse: () => _taxCategories.contains(item.taxCategory)
            ? item.taxCategory
            : (_taxCategories.isNotEmpty ? _taxCategories.first : 'GST 18%'),
      );

      _taxCategoryController.text = _selectedTaxCategory;

      _salesPriceController.text =
          item.salesPrice > 0 ? item.salesPrice.toStringAsFixed(2) : '';

      _purchasePriceController.text =
          item.purchasePrice > 0 ? item.purchasePrice.toStringAsFixed(2) : '';

      _mrpController.text =
          item.mrp > 0 ? item.mrp.toStringAsFixed(2) : '';

      if (item.hsn.isNotEmpty) {
        _validateHsn();
      }
    } else {
      _unitController.text = _units.isNotEmpty ? _units.first : 'PCS';

      _selectedTaxCategory =
          _taxCategories.isNotEmpty ? _taxCategories.first : 'GST 18%';

      _taxCategoryController.text = _selectedTaxCategory;
    }

    _hsnController.addListener(_autoGenerateName);
    _unitController.addListener(_autoGenerateName);

    _unitFocusNode.addListener(() {
      if (!_unitFocusNode.hasFocus) {
        _enforceValidUnitSelection();
      }
    });

    _taxCategoryFocusNode.addListener(() {
      if (!_taxCategoryFocusNode.hasFocus) {
        _enforceValidTaxCategorySelection();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Data helpers
  // ---------------------------------------------------------------------------

  void _enforceValidUnitSelection() {
    final current = _unitController.text.trim().toUpperCase();

    final match = _units.firstWhere(
      (u) => u.toUpperCase() == current,
      orElse: () => _units.isNotEmpty ? _units.first : '',
    );

    if (_unitController.text != match) {
      _unitController.text = match;
      _autoGenerateName();
    }
  }

  void _enforceValidTaxCategorySelection() {
    final current = _taxCategoryController.text.trim().toUpperCase();

    final match = _taxCategories.firstWhere(
      (t) => t.toUpperCase() == current,
      orElse: () => _selectedTaxCategory,
    );

    _taxCategoryController.text = match;
    _selectedTaxCategory = match;

    _autoGenerateName();
  }

  Future<void> _loadMastersData() async {
    final path =
        widget.folderPath ?? widget.company?['folderPath']?.toString();

    if (path == null || path.isEmpty) return;

    final raw = await StorageService.loadCompanyMasters(
      folderPath: path,
    );

    if (!mounted) return;

    setState(() {
      if (raw['units'] is List && (raw['units'] as List).isNotEmpty) {
        _units =
            (raw['units'] as List).map((e) => e.toString()).toList();
      }

      if (raw['taxCategories'] is List &&
          (raw['taxCategories'] as List).isNotEmpty) {
        _taxCategories =
            (raw['taxCategories'] as List).map((e) => e.toString()).toList();
      }

      if (!_taxCategories.contains(_selectedTaxCategory)) {
        _selectedTaxCategory =
            _taxCategories.isNotEmpty ? _taxCategories.first : 'GST 18%';
      }

      _taxCategoryController.text = _selectedTaxCategory;

      if (!_units.contains(_unitController.text.trim().toUpperCase())) {
        _unitController.text = _units.isNotEmpty ? _units.first : 'PCS';
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

  // ---------------------------------------------------------------------------
  // HSN
  // ---------------------------------------------------------------------------

  Future<void> _validateHsn() async {
    final hsn = _hsnController.text.trim();

    if (hsn.isEmpty) {
      setState(() {
        _hsnStatusMessage = 'Please enter an HSN/SAC code.';
        _isHsnValid = false;
      });
      return;
    }

    final isValidFormat = RegExp(r'^[0-9]{4,8}$').hasMatch(hsn);

    if (!isValidFormat) {
      setState(() {
        _isHsnValid = false;
        _hsnStatusMessage =
            'Invalid HSN. Must be 4 to 8 numeric digits.';
      });
      return;
    }

    setState(() => _isValidatingHsn = true);

    final description = await HsnService.findDescription(hsn);

    if (!mounted) return;

    setState(() {
      _isValidatingHsn = false;

      if (description != null && description.isNotEmpty) {
        _isHsnValid = true;
        _hsnStatusMessage = description;
      } else {
        _isHsnValid = false;
        _hsnStatusMessage = 'Invalid HSN code.';
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _handleSubmit() async {
    _enforceValidUnitSelection();
    _enforceValidTaxCategorySelection();

    if (!_formKey.currentState!.validate()) return;

    if (widget.isEdit) {
      final shouldContinue = await AppConfirmDialog.show(
        context: context,
        barrierDismissible: false,
        title: 'Warning',
        message:
            'All previous transactions will be changed accordingly. Do you want to continue?',
        confirmLabel: 'Yes',
        cancelLabel: 'No',
        type: ConfirmDialogType.warning,
      );

      if (!shouldContinue) return;
    }

    setState(() => _isSaving = true);

    final taxMatch =
        RegExp(r'(\d+)%').firstMatch(_selectedTaxCategory);

    final rate = taxMatch != null
        ? double.tryParse(taxMatch.group(1)!) ?? 18.0
        : 0.0;

    final itemData = {
      'name': _nameController.text.trim(),
      'hsn': _hsnController.text.trim(),
      'unit': _unitController.text.trim().isEmpty
          ? 'PCS'
          : _unitController.text.trim().toUpperCase(),
      'taxCategory': _selectedTaxCategory,
      'taxRate': rate,
      'salesPrice':
          double.tryParse(_salesPriceController.text.trim()) ?? 0.0,
      'purchasePrice':
          double.tryParse(_purchasePriceController.text.trim()) ?? 0.0,
      'mrp': double.tryParse(_mrpController.text.trim()) ?? 0.0,
    };

    final path =
        widget.folderPath ?? widget.company?['folderPath']?.toString();

    if (path != null && path.isNotEmpty) {
      try {
        final raw = await StorageService.loadCompanyMasters(
          folderPath: path,
        );

        final itemsList = (raw['items'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        final originalName =
            widget.initialItem?.name.trim().toLowerCase();

        final newName =
            itemData['name'].toString().trim().toLowerCase();

        final idx = itemsList.indexWhere((i) {
          final n =
              (i['name'] ?? '').toString().trim().toLowerCase();

          return widget.isEdit &&
                  originalName != null &&
                  originalName.isNotEmpty
              ? n == originalName
              : n == newName;
        });

        if (idx != -1) {
          itemsList[idx] = itemData;
        } else {
          itemsList.add(itemData);
        }

        raw['items'] = itemsList;

        await StorageService.saveCompanyMasters(
          folderPath: path,
          mastersData: raw,
        );
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

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _hsnController.dispose();
    _hsnFocusNode.dispose();

    _nameController.dispose();
    _nameFocusNode.dispose();

    _unitController.dispose();
    _unitFocusNode.dispose();
    _unitOptionsScrollController.dispose();

    _taxCategoryController.dispose();
    _taxCategoryFocusNode.dispose();
    _taxOptionsScrollController.dispose();

    _salesPriceController.dispose();
    _salesPriceFocusNode.dispose();

    _purchasePriceController.dispose();
    _mrpController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return AutoScreenFocus(
      screen: FocusTargetScreen.addItemDialog,
      nodeMap: {
        FocusFieldNode.hsnField: _hsnFocusNode,
        FocusFieldNode.itemNameField: _nameFocusNode,
        FocusFieldNode.unitField: _unitFocusNode,
        FocusFieldNode.salesPriceField: _salesPriceFocusNode,
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 24,
        ),
        child: Container(
          width: 760,
          constraints: const BoxConstraints(
            maxHeight: 760,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.border.withOpacity(.65),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor.withOpacity(.18),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      24,
                      22,
                      24,
                      18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIdentificationSection(),
                        const SizedBox(height: 18),
                        _buildPricingSection(),
                      ],
                    ),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 18, 20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(.45),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withOpacity(.55),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(.10),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              widget.isEdit
                  ? Icons.edit_rounded
                  : Icons.inventory_2_rounded,
              color: AppColors.primary,
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEdit ? 'Edit Item' : 'Add New Item',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isEdit
                      ? 'Update inventory, tax and pricing details'
                      : 'Create an inventory item with tax and pricing details',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _buildCloseButton(),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(.75),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border.withOpacity(.7),
            ),
          ),
          child: const Icon(
            Icons.close_rounded,
            size: 19,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // IDENTIFICATION SECTION
  // ===========================================================================

  Widget _buildIdentificationSection() {
    return _buildSectionCard(
      title: 'Item Identification',
      subtitle: 'Define the item code, name, unit and tax category',
      icon: Icons.badge_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: _buildTextField(
                  controller: _hsnController,
                  focusNode: _hsnFocusNode,
                  label: 'HSN / SAC Code',
                  required: true,
                  hintText: 'Enter 4–8 digit code',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  prefixIcon: Icons.tag_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'HSN code is required';
                    }

                    if (val.trim().length < 4) {
                      return 'HSN must be at least 4 digits';
                    }

                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: _buildValidateButton(),
              ),
            ],
          ),
          if (_hsnStatusMessage != null) ...[
            const SizedBox(height: 10),
            _buildHsnStatus(),
          ],
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  label: 'Item Name',
                  required: true,
                  hintText: 'Item name',
                  prefixIcon: Icons.inventory_2_outlined,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Item name cannot be empty';
                    }

                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildUnitAutocompleteField(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildTaxCategoryAutocompleteField(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValidateButton() {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: _isValidatingHsn ? null : _validateHsn,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor:
              AppColors.primary.withOpacity(.55),
          foregroundColor: AppColors.surface,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isValidatingHsn)
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              const Icon(
                Icons.verified_outlined,
                size: 17,
              ),
            const SizedBox(width: 7),
            Text(
              _isValidatingHsn ? 'Checking' : 'Validate',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHsnStatus() {
    final valid = _isHsnValid;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: valid
            ? AppColors.successLight.withOpacity(.65)
            : AppColors.errorLight.withOpacity(.65),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: valid
              ? AppColors.successBorder
              : AppColors.error,
          width: .8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: valid
                  ? AppColors.successBorder.withOpacity(.25)
                  : AppColors.error.withOpacity(.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              valid
                  ? Icons.check_rounded
                  : Icons.error_outline_rounded,
              size: 15,
              color: valid
                  ? AppColors.successDark
                  : AppColors.errorDark,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _hsnStatusMessage!,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: valid
                    ? AppColors.successDark
                    : AppColors.errorDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PRICING SECTION
  // ===========================================================================

  Widget _buildPricingSection() {
    return _buildSectionCard(
      title: 'Pricing',
      subtitle: 'Set default selling and purchase values',
      icon: Icons.currency_rupee_rounded,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildPriceField(
              controller: _salesPriceController,
              focusNode: _salesPriceFocusNode,
              label: 'Sales Price',
              hint: '0.00',
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _buildPriceField(
              controller: _purchasePriceController,
              label: 'Purchase Price',
              hint: '0.00',
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _buildPriceField(
              controller: _mrpController,
              label: 'MRP',
              hint: '0.00',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    required String hint,
  }) {
    return _buildTextField(
      controller: controller,
      focusNode: focusNode,
      label: label,
      hintText: hint,
      prefixText: '₹ ',
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
    );
  }

  // ===========================================================================
  // SECTION CARD
  // ===========================================================================

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(.48),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border.withOpacity(.72),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(.75),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 17,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          child,
        ],
      ),
    );
  }

  // ===========================================================================
  // UNIT AUTOCOMPLETE
  // ===========================================================================

  Widget _buildUnitAutocompleteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(
          'Unit',
          required: true,
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            return RawAutocomplete<String>(
              textEditingController: _unitController,
              focusNode: _unitFocusNode,
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _units;
                }

                return SmartFilter.filterAndSort<String>(
                  items: _units,
                  query: textEditingValue.text,
                  labelExtractor: (u) => u,
                );
              },
              onSelected: (selection) {
                _unitController.text = selection;
                _autoGenerateName();
                _taxCategoryFocusNode.requestFocus();
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                return _buildAutocompleteTextField(
                  controller: controller,
                  focusNode: focusNode,
                  hintText: 'Select unit',
                  icon: Icons.straighten_rounded,
                  onSubmitted: (value) {
                    final matches =
                        SmartFilter.filterAndSort<String>(
                      items: _units,
                      query: value,
                      labelExtractor: (u) => u,
                    );

                    final selected = matches.isNotEmpty
                        ? matches.first
                        : (_units.isNotEmpty
                            ? _units.first
                            : value);

                    controller.text = selected;

                    _autoGenerateName();

                    _taxCategoryFocusNode.requestFocus();
                  },
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Unit is required';
                    }

                    final match = _units.any(
                      (u) =>
                          u.toUpperCase() ==
                          val.trim().toUpperCase(),
                    );

                    if (!match) {
                      return 'Select a valid unit';
                    }

                    return null;
                  },
                );
              },
              optionsViewBuilder:
                  (context, onSelected, options) {
                return _buildAutocompleteOptions(
                  context: context,
                  width: constraints.maxWidth,
                  options: options,
                  controller: _unitOptionsScrollController,
                  onSelected: onSelected,
                );
              },
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // TAX AUTOCOMPLETE
  // ===========================================================================

  Widget _buildTaxCategoryAutocompleteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(
          'Tax Category',
          required: true,
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            return RawAutocomplete<String>(
              textEditingController: _taxCategoryController,
              focusNode: _taxCategoryFocusNode,
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _taxCategories;
                }

                return SmartFilter.filterAndSort<String>(
                  items: _taxCategories,
                  query: textEditingValue.text,
                  labelExtractor: (t) => t,
                );
              },
              onSelected: (selection) {
                _taxCategoryController.text = selection;

                setState(() {
                  _selectedTaxCategory = selection;
                  _autoGenerateName();
                });

                _nameFocusNode.requestFocus();
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                return _buildAutocompleteTextField(
                  controller: controller,
                  focusNode: focusNode,
                  hintText: 'Select tax category',
                  icon: Icons.percent_rounded,
                  onSubmitted: (value) {
                    final matches =
                        SmartFilter.filterAndSort<String>(
                      items: _taxCategories,
                      query: value,
                      labelExtractor: (t) => t,
                    );

                    final selected = matches.isNotEmpty
                        ? matches.first
                        : (_taxCategories.isNotEmpty
                            ? _taxCategories.first
                            : value);

                    controller.text = selected;

                    setState(() {
                      _selectedTaxCategory = selected;
                      _autoGenerateName();
                    });

                    _nameFocusNode.requestFocus();
                  },
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Tax category is required';
                    }

                    final match = _taxCategories.any(
                      (c) =>
                          c.toUpperCase() ==
                          val.trim().toUpperCase(),
                    );

                    if (!match) {
                      return 'Select a valid tax category';
                    }

                    return null;
                  },
                );
              },
              optionsViewBuilder:
                  (context, onSelected, options) {
                return _buildAutocompleteOptions(
                  context: context,
                  width: constraints.maxWidth,
                  options: options,
                  controller: _taxOptionsScrollController,
                  onSelected: onSelected,
                );
              },
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // AUTOCOMPLETE TEXT FIELD
  // ===========================================================================

  Widget _buildAutocompleteTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData icon,
    required ValueChanged<String> onSubmitted,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      height: 46,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        onFieldSubmitted: onSubmitted,
        validator: validator,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            icon,
            size: 17,
            color: AppColors.textSecondary,
          ),
          suffixIcon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          filled: true,
          fillColor: AppColors.surface,
          border: _inputBorder(),
          enabledBorder: _inputBorder(),
          focusedBorder: _inputBorder(
            color: AppColors.primary,
            width: 1.4,
          ),
          errorBorder: _inputBorder(
            color: AppColors.error,
          ),
          focusedErrorBorder: _inputBorder(
            color: AppColors.error,
            width: 1.3,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // AUTOCOMPLETE OPTIONS
  // ===========================================================================

  Widget _buildAutocompleteOptions({
    required BuildContext context,
    required double width,
    required Iterable<String> options,
    required ScrollController controller,
    required AutocompleteOnSelected<String> onSelected,
  }) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: width,
          constraints: const BoxConstraints(
            maxHeight: 220,
          ),
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: AppColors.border.withOpacity(.9),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor.withOpacity(.14),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Scrollbar(
            controller: controller,
            thumbVisibility: true,
            child: ListView.separated(
              controller: controller,
              padding: const EdgeInsets.symmetric(vertical: 5),
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 12,
                endIndent: 12,
                color: AppColors.border.withOpacity(.45),
              ),
              itemBuilder: (context, index) {
                final option = options.elementAt(index);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onSelected(option),
                    hoverColor:
                        AppColors.primaryLight.withOpacity(.55),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight
                                  .withOpacity(.55),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              option,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: AppColors.textMuted,
                          ),
                        ],
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
  }

  // ===========================================================================
  // NORMAL TEXT FIELD
  // ===========================================================================

  Widget _buildTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    String? hintText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    IconData? prefixIcon,
    String? prefixText,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(
          label,
          required: required,
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 46,
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            validator: validator,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(
                      prefixIcon,
                      size: 17,
                      color: AppColors.textSecondary,
                    )
                  : null,
              prefixText: prefixText,
              prefixStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: prefixIcon != null ? 4 : 12,
                vertical: 11,
              ),
              filled: true,
              fillColor: AppColors.surface,
              border: _inputBorder(),
              enabledBorder: _inputBorder(),
              focusedBorder: _inputBorder(
                color: AppColors.primary,
                width: 1.4,
              ),
              errorBorder: _inputBorder(
                color: AppColors.error,
              ),
              focusedErrorBorder: _inputBorder(
                color: AppColors.error,
                width: 1.3,
              ),
              errorStyle: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(
    String text, {
    bool required = false,
  }) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
          letterSpacing: .1,
        ),
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: AppColors.error,
                  ),
                ),
              ]
            : null,
      ),
    );
  }

  OutlineInputBorder _inputBorder({
    Color? color,
    double width = .9,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: color ??
            AppColors.border.withOpacity(.85),
        width: width,
      ),
    );
  }

  // ===========================================================================
  // FOOTER
  // ===========================================================================

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        24,
        15,
        24,
        18,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border.withOpacity(.65),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 9),
                const Flexible(
                  child: Text(
                    'Fields marked with * are required',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          OutlinedButton(
            onPressed: _isSaving
                ? null
                : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              disabledForegroundColor:
                  AppColors.textMuted,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 13,
              ),
              side: BorderSide(
                color: AppColors.border.withOpacity(.9),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 9),
          ElevatedButton(
            onPressed: _isSaving ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor:
                  AppColors.primary.withOpacity(.55),
              foregroundColor: AppColors.surface,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _isSaving
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      key: const ValueKey('save'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isEdit
                              ? Icons.check_rounded
                              : Icons.add_rounded,
                          size: 17,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          widget.isEdit
                              ? 'Save Changes'
                              : 'Save Item',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}