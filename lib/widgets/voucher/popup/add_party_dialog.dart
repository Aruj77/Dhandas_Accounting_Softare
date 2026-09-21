import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../models/party_master_model.dart';
import '../../../services/focus_policy_service.dart';
import '../../../services/gstin_service.dart';
import '../../../services/loading_service.dart';

class AddPartyDialog extends StatefulWidget {
  final String voucherType;
  final Function(Map<String, dynamic> partyData) onPartyCreated;
  final PartyMasterModel? initialParty;
  final bool isEdit;

  const AddPartyDialog({
    super.key,
    required this.voucherType,
    required this.onPartyCreated,
    this.initialParty,
    this.isEdit = false,
  });

  @override
  State<AddPartyDialog> createState() => _AddPartyDialogState();
}

class _AddPartyDialogState extends State<AddPartyDialog> {
  final _formKey = GlobalKey<FormState>();

  final Map<String, TextEditingController> _c = {
    for (final k in [
      'name',
      'gstin',
      'group',
      'pan',
      'address',
      'state',
      'pincode',
      'country',
      'aadhaar',
      'mobile',
    ])
      k: TextEditingController(),
  };

  final Map<String, FocusNode> _fn = {
    for (final k in ['name', 'gstin', 'address']) k: FocusNode(),
  };

  String? _gstinStatus;
  bool _isCheckingGstin = false;

  static const List<String> _countries = [
    'Afghanistan',
    'Albania',
    'Algeria',
    'Andorra',
    'Angola',
    'Argentina',
    'Armenia',
    'Australia',
    'Austria',
    'Azerbaijan',
    'Bahrain',
    'Bangladesh',
    'Belarus',
    'Belgium',
    'Bhutan',
    'Bolivia',
    'Brazil',
    'Bulgaria',
    'Cambodia',
    'Cameroon',
    'Canada',
    'Chile',
    'China',
    'Colombia',
    'Croatia',
    'Cuba',
    'Cyprus',
    'Czech Republic',
    'Denmark',
    'Egypt',
    'Estonia',
    'Ethiopia',
    'Finland',
    'France',
    'Georgia',
    'Germany',
    'Ghana',
    'Greece',
    'Hungary',
    'Iceland',
    'India',
    'Indonesia',
    'Iran',
    'Iraq',
    'Ireland',
    'Israel',
    'Italy',
    'Japan',
    'Jordan',
    'Kazakhstan',
    'Kenya',
    'Kuwait',
    'Laos',
    'Latvia',
    'Lebanon',
    'Luxembourg',
    'Malaysia',
    'Maldives',
    'Mauritius',
    'Mexico',
    'Monaco',
    'Morocco',
    'Myanmar',
    'Nepal',
    'Netherlands',
    'New Zealand',
    'Nigeria',
    'Norway',
    'Oman',
    'Pakistan',
    'Panama',
    'Peru',
    'Philippines',
    'Poland',
    'Portugal',
    'Qatar',
    'Romania',
    'Russia',
    'Saudi Arabia',
    'Serbia',
    'Singapore',
    'Slovakia',
    'Slovenia',
    'South Africa',
    'South Korea',
    'Spain',
    'Sri Lanka',
    'Sweden',
    'Switzerland',
    'Taiwan',
    'Thailand',
    'Turkey',
    'Uganda',
    'Ukraine',
    'United Arab Emirates',
    'United Kingdom',
    'United States',
    'Uruguay',
    'Uzbekistan',
    'Vatican City',
    'Venezuela',
    'Vietnam',
    'Yemen',
    'Zimbabwe',
  ];

  static const List<String> _states = [
    'Andaman and Nicobar Islands',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chandigarh',
    'Chhattisgarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu and Kashmir',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Ladakh',
    'Lakshadweep',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Puducherry',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.initialParty;

    if (widget.isEdit && p != null) {
      _c['name']!.text = p.name;
      _c['gstin']!.text = p.gstin;
      _c['group']!.text = p.group;
      _c['country']!.text = p.country.isNotEmpty ? p.country : 'India';
      _c['state']!.text = p.state;
      _c['address']!.text = p.address;
      _c['pincode']!.text = p.pincode;
      _c['aadhaar']!.text = p.aadhaar;
      _c['mobile']!.text = p.mobile;

      if (p.gstin.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _validateGstin());
      }
    } else {
      final isSales = widget.voucherType.toLowerCase().contains('sale');
      _c['group']!.text = isSales ? 'Sundry Debtors' : 'Sundry Creditors';
      _c['country']!.text = 'India';
    }

    _c['gstin']!.addListener(_onGstinChanged);
  }

  void _onGstinChanged() {
    final gstin = _c['gstin']!.text.trim().toUpperCase();
    final pan = GstinService.extractPan(gstin) ?? '';
    if (_c['pan']!.text != pan) {
      _c['pan']!.text = pan;
    }

    if (_gstinStatus != null) {
      setState(() => _gstinStatus = null);
    }
  }

  Future<void> _validateGstin() async {
    await LoadingService.wrap(() async {
      final gstin = _c['gstin']!.text.trim().toUpperCase();
      if (gstin.isEmpty) {
        setState(() => _gstinStatus = 'Please enter GSTIN first');
        return;
      }

      setState(() => _isCheckingGstin = true);
      try {
        final data = await GstinService.validateAndFetch(gstin);

        if (!mounted) return;
        setState(() {
          _isCheckingGstin = false;
          _gstinStatus = 'GSTIN verified - ${GstinService.getStateName(gstin)}';
        });

        final state = data.state.isNotEmpty
            ? data.state
            : GstinService.getStateName(gstin);
        if (state != 'Unknown') {
          _c['state']!.text = state;
        }
        if (_c['name']!.text.trim().isEmpty) {
          final name = data.tradeName.isNotEmpty
              ? data.tradeName
              : data.legalName;
          if (name.isNotEmpty) _c['name']!.text = name;
        }
        if (_c['address']!.text.trim().isEmpty && data.address.isNotEmpty) {
          _c['address']!.text = data.address;
        }
        if (_c['pincode']!.text.trim().isEmpty && data.pincode.isNotEmpty) {
          _c['pincode']!.text = data.pincode;
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isCheckingGstin = false;
          _gstinStatus = e is FormatException
              ? e.message
              : e.toString().replaceFirst('Exception: ', '');
        });
      }
    }, message: 'Validating GSTIN...');
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final party = {
      for (final entry in _c.entries) entry.key: entry.value.text.trim(),
    };
    party['gstin'] = party['gstin']!.toUpperCase();
    party['pan'] = party['pan']!.toUpperCase();

    widget.onPartyCreated(party);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    for (final controller in _c.values) {
      controller.dispose();
    }
    for (final node in _fn.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth >= 1200 ? 900.0 : screenWidth * 0.9;
    final isSales = widget.voucherType.toLowerCase().contains('sale');

    return AutoScreenFocus(
      screen: FocusTargetScreen.addPartyDialog,
      nodeMap: {
        FocusFieldNode.partyGstinField: _fn['gstin']!,
        FocusFieldNode.partyNameField: _fn['name']!,
        FocusFieldNode.partyAddressField: _fn['address']!,
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border.withValues(alpha: .85)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .15),
                blurRadius: 40,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(isSales),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(26, 18, 26, 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTaxSection(),
                          const SizedBox(height: 13),
                          _buildPartySection(),
                          const SizedBox(height: 13),
                          _buildAddressSection(),
                          const SizedBox(height: 13),
                          _buildContactSection(),
                        ],
                      ),
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

  Widget _buildHeader(bool isSales) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: .75)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.isEdit
                  ? Icons.edit_note_rounded
                  : Icons.person_add_alt_1_rounded,
              size: 22,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 13),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.isEdit ? 'Edit Party' : 'Create New Party',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.isEdit
                    ? 'Update party master details'
                    : 'Add a new account to your ledger',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isSales ? 'CUSTOMER' : 'SUPPLIER',
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: .7,
              ),
            ),
          ),
          const SizedBox(width: 9),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxSection() {
    return _buildSection(
      title: 'Tax & Registration',
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildField(
                  controller: _c['gstin']!,
                  focusNode: _fn['gstin'],
                  label: 'GSTIN',
                  hint: '15-digit GSTIN',
                  icon: Icons.badge_outlined,
                  capitalization: TextCapitalization.characters,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 19),
                child: SizedBox(
                  height: 40,
                  width: 105,
                  child: ElevatedButton(
                    onPressed: _isCheckingGstin ? null : _validateGstin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: _isCheckingGstin
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.verified_outlined, size: 15),
                              SizedBox(width: 6),
                              Text(
                                'Verify',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
          if (_gstinStatus != null) ...[
            const SizedBox(height: 7),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _gstinStatus!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _gstinStatus!.contains('verified')
                      ? Colors.green
                      : AppColors.errorDark,
                ),
              ),
            ),
          ],
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _buildBadgeInfo(
                  'PAN',
                  _c['pan']!.text.isEmpty ? 'Auto from GSTIN' : _c['pan']!.text,
                  Icons.credit_card_outlined,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _buildBadgeInfo(
                  'Detected State',
                  _c['state']!.text.isEmpty
                      ? 'Auto from GSTIN'
                      : _c['state']!.text,
                  Icons.location_on_outlined,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _buildBadgeInfo(
                  'Ledger Group',
                  _c['group']!.text,
                  Icons.account_tree_outlined,
                  isMuted: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartySection() {
    return _buildSection(
      title: 'Party Information',
      icon: Icons.business_center_outlined,
      child: Row(
        children: [
          Expanded(
            flex: 7,
            child: _buildField(
              controller: _c['name']!,
              focusNode: _fn['name'],
              label: 'Party / Business Name *',
              hint: 'Enter registered or trade name',
              icon: Icons.business_outlined,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Party name is required'
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: _buildField(
              controller: _c['group']!,
              label: 'Ledger Group',
              icon: Icons.account_tree_outlined,
              enabled: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return _buildSection(
      title: 'Address',
      icon: Icons.location_on_outlined,
      child: Column(
        children: [
          _buildField(
            controller: _c['address']!,
            focusNode: _fn['address'],
            label: 'Street Address',
            hint: 'Building, street, area, locality...',
            icon: Icons.home_work_outlined,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: _buildAutocomplete(
                  'State',
                  _c['state']!,
                  _states,
                  Icons.map_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: _buildField(
                  controller: _c['pincode']!,
                  label: 'PIN Code',
                  hint: '246761',
                  icon: Icons.pin_drop_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: _buildAutocomplete(
                  'Country',
                  _c['country']!,
                  _countries,
                  Icons.public_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return _buildSection(
      title: 'Contact & Identification',
      icon: Icons.contact_phone_outlined,
      child: Row(
        children: [
          Expanded(
            child: _buildField(
              controller: _c['mobile']!,
              label: 'Mobile Number',
              hint: '10-digit mobile number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildField(
              controller: _c['aadhaar']!,
              label: 'Aadhaar Number',
              hint: '12-digit Aadhaar number',
              icon: Icons.fingerprint_rounded,
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 11, 15, 13),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: .75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 14, color: AppColors.primary),
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    String? hint,
    IconData? icon,
    bool enabled = true,
    String? Function(String?)? validator,
    TextCapitalization capitalization = TextCapitalization.none,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            validator: validator,
            enabled: enabled,
            textCapitalization: capitalization,
            keyboardType: keyboardType,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
            ),
            decoration: _inputDecoration(
              hint: hint,
              icon: icon,
              disabled: !enabled,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAutocomplete(
    String label,
    TextEditingController controller,
    List<String> options,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Autocomplete<String>(
          initialValue: TextEditingValue(text: controller.text),
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) return options.take(6);
            return options.where(
              (o) =>
                  o.toLowerCase().contains(textEditingValue.text.toLowerCase()),
            );
          },
          onSelected: (option) => controller.text = option,
          fieldViewBuilder:
              (context, textEditingController, focusNode, onFieldSubmitted) {
                textEditingController.addListener(() {
                  if (controller.text != textEditingController.text) {
                    controller.text = textEditingController.text;
                  }
                });
                return SizedBox(
                  height: 40,
                  child: TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    decoration: _inputDecoration(
                      hint: 'Search $label...',
                      icon: icon,
                      suffixIcon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 17,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                );
              },
        ),
      ],
    );
  }

  Widget _buildBadgeInfo(
    String label,
    String value,
    IconData icon, {
    bool isMuted = false,
  }) {
    final bgColor = isMuted
        ? AppColors.background
        : AppColors.primary.withValues(alpha: .035);
    final borderColor = isMuted
        ? AppColors.border.withValues(alpha: .65)
        : AppColors.primary.withValues(alpha: .12);
    final iconColor = isMuted ? AppColors.textMuted : AppColors.primary;

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isMuted
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hint,
    IconData? icon,
    Widget? suffixIcon,
    bool disabled = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              size: 15,
              color: disabled ? AppColors.textMuted : AppColors.textSecondary,
            ),
      prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 40),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: disabled ? AppColors.background : AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: AppColors.border.withValues(alpha: .8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: AppColors.border.withValues(alpha: .8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(
          color: AppColors.primary.withValues(alpha: .75),
          width: 1.2,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: AppColors.border.withValues(alpha: .65)),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: .75)),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          const Text(
            '* Required field',
            style: TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
              side: BorderSide(color: AppColors.border.withValues(alpha: .9)),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 9),
          ElevatedButton.icon(
            onPressed: _handleSubmit,
            icon: Icon(
              widget.isEdit ? Icons.check_rounded : Icons.add_rounded,
              size: 16,
            ),
            label: Text(widget.isEdit ? 'Save Changes' : 'Create Party'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
