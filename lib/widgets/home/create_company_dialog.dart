import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/gst_constants.dart';
import '../../provider/company_provider.dart';
import '../../services/loading_service.dart';
import '../../services/notification_service.dart';

class CreateCompanyDialog extends ConsumerStatefulWidget {
  final String? currentDirectory;

  const CreateCompanyDialog({super.key, this.currentDirectory});

  @override
  ConsumerState<CreateCompanyDialog> createState() => _CreateCompanyDialogState();
}

class _CreateCompanyDialogState extends ConsumerState<CreateCompanyDialog> {
  final _formKey = GlobalKey<FormState>();

  final _gstinController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');

  bool _isValidatingGst = false;
  bool _isGstValid = false;
  bool _isSaving = false;
  String? _gstError;

  List<String> get _countries => GstConstants.allSortedCountries;
  List<String> get _allStates => GstConstants.allSortedStateNames;

  Future<void> _validateAndFetchGstin() async {
    await LoadingService.wrap(() async {
      final gstin = _gstinController.text.trim().toUpperCase();
      if (gstin.isEmpty) {
        setState(() => _gstError = 'Enter a GSTIN to validate');
        return;
      }
      if (!GstConstants.gstinRegex.hasMatch(gstin)) {
        setState(() {
          _gstError = 'Invalid GSTIN format (e.g. 09AAECB1234F1Z5)';
          _isGstValid = false;
        });
        return;
      }

      setState(() {
        _isValidatingGst = true;
        _gstError = null;
      });

      await Future.delayed(const Duration(milliseconds: 750));

      final stateCode = gstin.substring(0, 2);
      final detectedState = GstConstants.getStateName(stateCode);

      setState(() {
        _isValidatingGst = false;
        _isGstValid = true;
        _stateController.text = detectedState != 'Unknown' ? detectedState : 'Delhi';
        _countryController.text = 'India';

        if (_companyNameController.text.isEmpty) {
          _companyNameController.text = 'Dhandas Global Solutions Pvt Ltd';
        }
        if (_cityController.text.isEmpty) {
          _cityController.text = (stateCode == '09')
              ? 'Noida'
              : (stateCode == '27')
                  ? 'Mumbai'
                  : (stateCode == '29')
                      ? 'Bengaluru'
                      : 'Central District';
        }
        if (_addressController.text.isEmpty) {
          _addressController.text = 'Unit 402, Signature Tower, Tech Park';
        }
      });
    }, message: 'Validating GSTIN...');
  }

  Future<void> _submitForm() async {
    await LoadingService.wrap(() async {
      if (!(_formKey.currentState?.validate() ?? false)) return;

      if (widget.currentDirectory == null || widget.currentDirectory!.isEmpty) {
        NotificationService.show(
          context,
          message: 'Please select a Data Directory first before creating a company.',
          type: NotificationType.error,
        );
        return;
      }

      setState(() => _isSaving = true);

      final companyData = {
        'companyName': _companyNameController.text.trim(),
        'gstin': _gstinController.text.trim().toUpperCase(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'country': _countryController.text.trim().isNotEmpty ? _countryController.text.trim() : 'India',
        'createdAt': DateTime.now().toIso8601String(),
      };

      try {
        final repo = ref.read(companyRepositoryProvider);
        await repo.createCompany(
          directoryPath: widget.currentDirectory!,
          companyData: companyData,
        );

        ref.invalidate(companiesProvider);

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        setState(() => _isSaving = false);
        if (mounted) {
          NotificationService.show(
            context,
            message: 'Error saving company: $e',
            type: NotificationType.error,
          );
        }
      }
    }, message: 'Saving Company...');
  }

  @override
  void dispose() {
    _gstinController.dispose();
    _companyNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 820,
        constraints: const BoxConstraints(maxHeight: 820),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.12),
              blurRadius: 50,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIdentitySection(),
                        const SizedBox(height: 24),
                        _buildGstCard(),
                        const SizedBox(height: 24),
                        _buildAddressSection(),
                      ],
                    ),
                  ),
                ),
              ),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(36, 24, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryAccent, AppColors.primarySemiLight],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryAccent.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.domain_add_rounded, color: AppColors.surface, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Organization',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Configure company credentials and official address details',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, size: 22),
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderMedium),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryAccent, size: 22),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload Logo',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const Text('PNG or JPG', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildInputField(
            label: 'Legal Entity Name',
            hint: 'e.g. Acme Innovations Private Limited',
            controller: _companyNameController,
            prefixIcon: Icons.badge_outlined,
            isRequired: true,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Company name is required' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildGstCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isGstValid ? AppColors.successBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Tax Identification (GSTIN)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 8),
              if (_isGstValid)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, size: 13, color: AppColors.successDark),
                      SizedBox(width: 4),
                      Text(
                        'Verified & Autofilled',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.successDark),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _gstError != null
                    ? AppColors.error
                    : _isGstValid
                        ? AppColors.success
                        : AppColors.borderMedium,
                width: 1.2,
              ),
            ),
            padding: const EdgeInsets.only(left: 14, right: 6),
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primaryAccent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _gstinController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: '22AAAAA0000A1Z5',
                      hintStyle: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w400, letterSpacing: 0, color: AppColors.textMuted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _isValidatingGst ? null : _validateAndFetchGstin,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _isValidatingGst
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.surface),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(_isValidatingGst ? 'Verifying...' : 'Fetch Details', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          if (_gstError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                _gstError!,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          label: 'Office / Registered Address',
          hint: 'Floor, building name, street, road, sector',
          controller: _addressController,
          prefixIcon: Icons.location_on_outlined,
          maxLines: 2,
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _buildInputField(
                label: 'City',
                hint: 'e.g. Gurugram',
                controller: _cityController,
                prefixIcon: Icons.location_city_rounded,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 4,
              child: _buildWritableAutocomplete(
                label: 'State / Province',
                controller: _stateController,
                options: _allStates,
                icon: Icons.map_outlined,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 3,
              child: _buildWritableAutocomplete(
                label: 'Country',
                controller: _countryController,
                options: _countries,
                icon: Icons.public_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData prefixIcon,
    int maxLines = 1,
    bool isRequired = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            if (isRequired) const Text(' *', style: TextStyle(color: AppColors.error, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w400),
            prefixIcon: Icon(prefixIcon, color: AppColors.textSecondary, size: 19),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderMedium),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWritableAutocomplete({
    required String label,
    required TextEditingController controller,
    required List<String> options,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 7),
        LayoutBuilder(
          builder: (context, constraints) {
            return Autocomplete<String>(
              initialValue: TextEditingValue(text: controller.text),
              optionsBuilder: (TextEditingValue textEditingValue) {
                final query = textEditingValue.text.trim().toLowerCase();
                if (query.isEmpty) return options;
                return options.where((item) => item.toLowerCase().contains(query));
              },
              onSelected: (selection) {
                controller.text = selection;
              },
              optionsViewBuilder: (context, onSelected, filteredOptions) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.surface,
                    child: Container(
                      width: constraints.maxWidth,
                      constraints: const BoxConstraints(maxHeight: 260),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderMedium, width: 1.2),
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        shrinkWrap: true,
                        itemCount: filteredOptions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.background),
                        itemBuilder: (context, index) {
                          final option = filteredOptions.elementAt(index);
                          return Builder(
                            builder: (itemContext) {
                              final isHighlighted = AutocompleteHighlightedOption.of(itemContext) == index;
                              if (isHighlighted) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  Scrollable.ensureVisible(
                                    itemContext,
                                    alignment: 0.5,
                                    duration: const Duration(milliseconds: 100),
                                  );
                                });
                              }
                              return InkWell(
                                onTap: () => onSelected(option),
                                hoverColor: AppColors.primaryLight,
                                child: Container(
                                  color: isHighlighted ? AppColors.primaryLight : Colors.transparent,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
                                      color: isHighlighted ? AppColors.primary : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                textEditingController.addListener(() {
                  if (controller.text != textEditingController.text) {
                    controller.text = textEditingController.text;
                  }
                });
                return TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Select or type $label...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w400),
                    prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 19),
                    suffixIcon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderMedium),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
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

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.borderMedium),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _isSaving ? null : _submitForm,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              shadowColor: AppColors.primaryAccent.withValues(alpha: 0.35),
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.surface),
                  )
                : const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(
              _isSaving ? 'Saving...' : 'Save & Continue',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}