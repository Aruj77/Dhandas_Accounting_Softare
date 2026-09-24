// lib/widgets/voucher/popup/add_party_dialog.dart
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_decoration.dart';
import '../../../constants/gst_constants.dart';
import '../../../models/party_master_model.dart';
import '../../../services/focus_policy_service.dart';
import '../../../services/gstin_service.dart';
import '../../../services/loading_service.dart';
import '../../../services/storage_service.dart';

class AddPartyDialog extends StatefulWidget {
  final String voucherType;
  final String? folderPath;
  final Function(Map<String, dynamic> partyData) onPartyCreated;
  final PartyMasterModel? initialParty;
  final bool isEdit;
  final String? initialName;
  final String? initialGstin;
  final String? initialState;
  final String? initialAddress;

  const AddPartyDialog({
    super.key,
    required this.voucherType,
    this.folderPath,
    required this.onPartyCreated,
    this.initialParty,
    this.isEdit = false,
    this.initialName,
    this.initialGstin,
    this.initialState,
    this.initialAddress,
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
      'email',
      'contactPerson',
      'accountNumber',
      'ifsc',
    ])
      k: TextEditingController()
  };

  final Map<String, FocusNode> _fn = {
    for (final k in ['name', 'gstin', 'address']) k: FocusNode()
  };

  String? _gstinStatus;
  bool _isCheckingGstin = false;

  late List<String> _ledgerGroups = (StorageService.defaultCompanyMasters['accountGroups'] as List? ?? [])
      .map((e) => e is Map ? (e['name'] ?? '').toString().trim() : e.toString().trim())
      .where((s) => s.isNotEmpty)
      .toList();

  List<String> get _countries => GstConstants.allSortedCountries;
  List<String> get _states => GstConstants.allSortedStateNames;

  @override
  void initState() {
    super.initState();
    _loadLedgerGroupsFromDb();
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
      _c['email']!.text = p.email;
      _c['contactPerson']!.text = p.contactPerson;
      _c['accountNumber']!.text = p.accountNumber;
      _c['ifsc']!.text = p.ifsc;
      _c['pan']!.text = GstinService.extractPan(p.gstin) ?? '';

      if (p.gstin.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _validateGstin());
      }
    } else {
      final isSales = widget.voucherType.toLowerCase().contains('sale');
      _c['group']!.text = isSales ? 'Sundry Debtors' : 'Sundry Creditors';
      _c['country']!.text = 'India';

      if (widget.initialName != null && widget.initialName!.isNotEmpty) {
        _c['name']!.text = widget.initialName!;
      }
      if (widget.initialGstin != null && widget.initialGstin!.isNotEmpty) {
        _c['gstin']!.text = widget.initialGstin!;
        _c['pan']!.text = GstinService.extractPan(widget.initialGstin!) ?? '';
      }
      if (widget.initialState != null && widget.initialState!.isNotEmpty) {
        _c['state']!.text = widget.initialState!;
      }
      if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
        _c['address']!.text = widget.initialAddress!;
      }

      if (_c['gstin']!.text.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _validateGstin());
      }
    }

    _c['gstin']!.addListener(_onGstinChanged);
  }

  Future<void> _loadLedgerGroupsFromDb() async {
    final path = widget.folderPath;
    if (path == null || path.isEmpty) return;

    try {
      final rawMasters = await StorageService.loadCompanyMasters(folderPath: path);
      final groups = rawMasters['accountGroups'] as List? ?? [];
      if (groups.isNotEmpty && mounted) {
        setState(() {
          _ledgerGroups = groups
              .map((e) {
                if (e is Map) {
                  return (e['name'] ?? '').toString().trim();
                }
                return e.toString().trim();
              })
              .where((e) => e.isNotEmpty)
              .toList();
        });
      }
    } catch (_) {}
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
    final gstin = _c['gstin']!.text.trim().toUpperCase();
    if (gstin.isEmpty) {
      setState(() => _gstinStatus = 'Please enter GSTIN first');
      return;
    }

    await LoadingService.wrap(() async {
      setState(() => _isCheckingGstin = true);
      final isValid = GstinService.isValid(gstin);

      if (!mounted) return;
      setState(() {
        _isCheckingGstin = false;
        _gstinStatus = isValid
            ? 'GSTIN verified • ${GstinService.getStateName(gstin)}'
            : 'Invalid GSTIN format or checksum';
      });

      if (isValid) {
        final state = GstinService.getStateName(gstin);
        if (state != 'Unknown') {
          _c['state']!.text = state;
        }
      }
    }, message: 'Validating GSTIN...');
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final party = {
      for (final entry in _c.entries) entry.key: entry.value.text.trim()
    };
    party['gstin'] = party['gstin']!.toUpperCase();
    party['pan'] = party['pan']!.toUpperCase();
    party['ifsc'] = party['ifsc']!.toUpperCase();

    if (widget.isEdit && widget.initialParty != null) {
      party['originalName'] = widget.initialParty!.name.trim();
    }

    widget.onPartyCreated(party);
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(party);
    }
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
    final width = screenWidth >= 1200 ? 1220.0 : (screenWidth >= 800 ? 1020.0 : screenWidth * 0.98);
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Container(
          width: width,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.98,
            maxWidth: 1260,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withValues(alpha: .75)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .18),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(isSales),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(26),
                    child: Form(
                      key: _formKey,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isTwoColumn = constraints.maxWidth >= 780;

                          final leftCard = _buildCardContainer(
                            title: 'Business & Tax Profile',
                            subtitle: 'GSTIN verification, party name & address',
                            icon: Icons.storefront_outlined,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildGstinBlock(),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 6,
                                      child: _buildField(
                                        controller: _c['name']!,
                                        focusNode: _fn['name'],
                                        label: 'Party / Business Name *',
                                        hint: 'Registered or trade name',
                                        icon: Icons.business_outlined,
                                        validator: (v) => (v == null || v.trim().isEmpty)
                                            ? 'Party name is required'
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 5,
                                      child: _buildAutocomplete(
                                        'Ledger Group *',
                                        _c['group']!,
                                        _ledgerGroups,
                                        Icons.account_tree_outlined,
                                        validator: (v) => (v == null || v.trim().isEmpty)
                                            ? 'Ledger group is required'
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildField(
                                  controller: _c['address']!,
                                  focusNode: _fn['address'],
                                  label: 'Street Address',
                                  hint: 'Building, street, locality...',
                                  icon: Icons.home_work_outlined,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: _buildAutocomplete(
                                        'State *',
                                        _c['state']!,
                                        _states,
                                        Icons.map_outlined,
                                        validator: (v) => (v == null || v.trim().isEmpty)
                                            ? 'State is required'
                                            : null,
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
                                        'Country *',
                                        _c['country']!,
                                        _countries,
                                        Icons.public_outlined,
                                        validator: (v) => (v == null || v.trim().isEmpty)
                                            ? 'Country is required'
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );

                          final rightCard = _buildCardContainer(
                            title: 'Contact & Banking',
                            subtitle: 'Representative details & settlement account',
                            icon: Icons.account_balance_outlined,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSubHeader('Point of Contact', Icons.person_pin_outlined),
                                _buildField(
                                  controller: _c['contactPerson']!,
                                  label: 'Contact Person Name',
                                  hint: 'Representative full name',
                                  icon: Icons.person_outline_rounded,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _buildField(
                                        controller: _c['mobile']!,
                                        label: 'Mobile Number',
                                        hint: '10-digit number',
                                        icon: Icons.phone_outlined,
                                        keyboardType: TextInputType.phone,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildField(
                                        controller: _c['email']!,
                                        label: 'Email Address',
                                        hint: 'party@example.com',
                                        icon: Icons.email_outlined,
                                        keyboardType: TextInputType.emailAddress,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Divider(height: 1, color: AppColors.background),
                                const SizedBox(height: 16),
                                _buildSubHeader('Bank & Identification', Icons.account_balance_wallet_outlined),
                                _buildField(
                                  controller: _c['accountNumber']!,
                                  label: 'Bank Account Number',
                                  hint: 'Enter account number',
                                  icon: Icons.numbers_rounded,
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _buildField(
                                        controller: _c['ifsc']!,
                                        label: 'IFSC Code',
                                        hint: 'e.g. HDFC0001234',
                                        icon: Icons.code_rounded,
                                        capitalization: TextCapitalization.characters,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildField(
                                        controller: _c['aadhaar']!,
                                        label: 'ID / Reference Number',
                                        hint: 'Identification number',
                                        icon: Icons.fingerprint_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );

                          if (isTwoColumn) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: leftCard),
                                const SizedBox(width: 22),
                                Expanded(child: rightCard),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                leftCard,
                                const SizedBox(height: 22),
                                rightCard,
                              ],
                            );
                          }
                        },
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
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: .75)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              widget.isEdit ? Icons.edit_note_rounded : Icons.person_add_alt_1_rounded,
              size: 22,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      widget.isEdit ? 'Edit Party Master' : 'Create New Party',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSales
                            ? Colors.teal.withValues(alpha: .12)
                            : AppColors.primary.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSales
                              ? Colors.teal.withValues(alpha: .30)
                              : AppColors.primary.withValues(alpha: .25),
                        ),
                      ),
                      child: Text(
                        isSales ? 'CUSTOMER' : 'SUPPLIER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .5,
                          color: isSales ? Colors.teal.shade700 : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.isEdit
                      ? 'Update party master credentials & configurations'
                      : 'Add a new verified account to your party ledger',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              hoverColor: AppColors.border.withValues(alpha: .3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildGstinBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildField(
                controller: _c['gstin']!,
                focusNode: _fn['gstin'],
                label: 'GSTIN Number',
                hint: '15-digit GSTIN identification',
                icon: Icons.receipt_long_outlined,
                capitalization: TextCapitalization.characters,
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 23),
              child: SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: _isCheckingGstin ? null : _validateGstin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: _isCheckingGstin
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.verified_outlined, size: 16),
                  label: Text(
                    _isCheckingGstin ? 'Verifying' : 'Verify',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_gstinStatus != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _gstinStatus!.contains('verified')
                  ? const Color(0xFFE8F5E9)
                  : AppColors.errorDark.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _gstinStatus!.contains('verified')
                    ? const Color(0xFFA5D6A7)
                    : AppColors.errorDark.withValues(alpha: .25),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _gstinStatus!.contains('verified')
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  size: 15,
                  color: _gstinStatus!.contains('verified')
                      ? const Color(0xFF2E7D32)
                      : AppColors.errorDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _gstinStatus!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _gstinStatus!.contains('verified')
                          ? const Color(0xFF1B5E20)
                          : AppColors.errorDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: .5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border.withValues(alpha: .6)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  'PAN',
                  _c['pan']!.text.isEmpty ? 'From GSTIN' : _c['pan']!.text,
                  Icons.credit_card_outlined,
                  isDetected: _c['pan']!.text.isNotEmpty,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoChip(
                  'State',
                  _c['state']!.text.isEmpty ? 'From GSTIN' : _c['state']!.text,
                  Icons.location_on_outlined,
                  isDetected: _c['state']!.text.isNotEmpty,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardContainer({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: .75)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.background),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildSubHeader(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: .6,
              color: AppColors.textMuted,
            ),
          ),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: .1,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          validator: validator,
          enabled: enabled,
          textCapitalization: capitalization,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
          ),
          decoration: AppDecorations.standard(
            label: '',
            hintText: hint,
            prefixIcon: icon,
            fillColor: enabled ? AppColors.surface : AppColors.background.withValues(alpha: .6),
          ),
        ),
      ],
    );
  }

  Widget _buildAutocomplete(
    String label,
    TextEditingController controller,
    List<String> options,
    IconData icon, {
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: .1,
          ),
        ),
        const SizedBox(height: 5),
        LayoutBuilder(
          builder: (context, constraints) {
            return Autocomplete<String>(
              key: ValueKey('autocomplete_${label}_${options.length}'),
              initialValue: TextEditingValue(text: controller.text),
              optionsBuilder: (TextEditingValue textEditingValue) {
                final text = textEditingValue.text.trim();
                final isAllSelected = textEditingValue.selection.baseOffset == 0 &&
                    textEditingValue.selection.extentOffset == textEditingValue.text.length &&
                    textEditingValue.text.isNotEmpty;

                if (text.isEmpty || isAllSelected) {
                  return options;
                }
                final q = text.toLowerCase();
                final matches = options.where((o) => o.toLowerCase().contains(q)).toList();
                return matches.isNotEmpty ? matches : options;
              },
              onSelected: (option) => controller.text = option,
              optionsViewBuilder: (context, onSelected, filteredOptions) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 10,
                    shadowColor: Colors.black.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.surface,
                    child: Container(
                      width: constraints.maxWidth,
                      constraints: const BoxConstraints(maxHeight: 250),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        shrinkWrap: true,
                        itemCount: filteredOptions.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: AppColors.background),
                        itemBuilder: (context, index) {
                          final option = filteredOptions.elementAt(index);
                          final isSelected = option.toLowerCase() == controller.text.trim().toLowerCase();
                          return InkWell(
                            onTap: () => onSelected(option),
                            hoverColor: AppColors.primary.withValues(alpha: .08),
                            child: Container(
                              color: isSelected ? AppColors.primary.withValues(alpha: .08) : Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              fieldViewBuilder:
                  (context, textEditingController, focusNode, onFieldSubmitted) {
                if (controller.text.isNotEmpty &&
                    textEditingController.text != controller.text) {
                  textEditingController.text = controller.text;
                }

                focusNode.addListener(() {
                  if (focusNode.hasFocus) {
                    textEditingController.value = TextEditingValue(
                      text: textEditingController.text,
                      selection: TextSelection(
                        baseOffset: 0,
                        extentOffset: textEditingController.text.length,
                      ),
                    );
                  }
                });

                textEditingController.addListener(() {
                  if (controller.text != textEditingController.text) {
                    controller.text = textEditingController.text;
                  }
                });

                return TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  validator: validator,
                  onTap: () {
                    textEditingController.value = TextEditingValue(
                      text: textEditingController.text,
                      selection: TextSelection(
                        baseOffset: 0,
                        extentOffset: textEditingController.text.length,
                      ),
                    );
                  },
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: AppDecorations.standard(
                    label: '',
                    hintText: 'Select $label',
                    prefixIcon: icon,
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        if (!focusNode.hasFocus) {
                          focusNode.requestFocus();
                        }
                        textEditingController.value = TextEditingValue(
                          text: textEditingController.text,
                          selection: TextSelection(
                            baseOffset: 0,
                            extentOffset: textEditingController.text.length,
                          ),
                        );
                      },
                    ),
                    fillColor: AppColors.surface,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoChip(
    String label,
    String value,
    IconData icon, {
    bool isDetected = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDetected
            ? AppColors.primary.withValues(alpha: .06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDetected
              ? AppColors.primary.withValues(alpha: .22)
              : AppColors.border.withValues(alpha: .5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: isDetected ? AppColors.primary : AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .4,
                    color: isDetected ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDetected ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: .75)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          const Text('* Indicates required field',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const Spacer(),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: BorderSide(color: AppColors.border.withValues(alpha: .9)),
            ),
            child: const Text('Cancel',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}