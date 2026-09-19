import 'package:flutter/material.dart';
import '../../../models/party_master_model.dart';
import '../../../services/gstin_service.dart';

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

  final TextEditingController _gstinController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _groupController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController(text: 'India');
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  String? _gstinStatusMessage;
  bool _isGstinValid = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.initialParty != null) {
      _nameController.text = widget.initialParty!.name;
      _gstinController.text = widget.initialParty!.gstin;
      _groupController.text = widget.initialParty!.group;
      if (widget.initialParty!.gstin.isNotEmpty) {
        _onGstinChanged();
        _validateGstin();
      }
    } else {
      final isSales = widget.voucherType.toLowerCase().contains('sale');
      _groupController.text = isSales ? 'Sundry Debtors' : 'Sundry Creditors';
    }

    _gstinController.addListener(_onGstinChanged);
  }

  void _onGstinChanged() {
    final gstin = _gstinController.text.trim().toUpperCase();
    final pan = GstinService.extractPan(gstin);
    _panController.text = pan ?? '';
  }

  void _validateGstin() {
    final gstin = _gstinController.text.trim().toUpperCase();
    if (gstin.isEmpty) {
      setState(() {
        _gstinStatusMessage = 'Please enter a GSTIN first.';
        _isGstinValid = false;
      });
      return;
    }

    final isValid = GstinService.isValid(gstin);
    setState(() {
      _isGstinValid = isValid;
      _gstinStatusMessage = isValid
          ? 'Valid GSTIN (${GstinService.getStateName(gstin)})'
          : 'Invalid GSTIN format or checksum.';
    });

    if (isValid && _stateController.text.isEmpty) {
      final detectedState = GstinService.getStateName(gstin);
      if (detectedState != 'Unknown') {
        _stateController.text = detectedState;
      }
    }
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final party = {
      'name': _nameController.text.trim(),
      'gstin': _gstinController.text.trim().toUpperCase(),
      'group': _groupController.text.trim(),
      'pan': _panController.text.trim().toUpperCase(),
      'address': _addressController.text.trim(),
      'state': _stateController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'country': _countryController.text.trim(),
      'aadhaar': _aadhaarController.text.trim(),
      'mobile': _mobileController.text.trim(),
    };

    widget.onPartyCreated(party);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _gstinController.dispose();
    _nameController.dispose();
    _groupController.dispose();
    _panController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _aadhaarController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 720,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF3FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.isEdit ? Icons.edit_note_rounded : Icons.person_add_rounded,
                      size: 20,
                      color: const Color(0xFF0F62FE),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEdit
                            ? 'Edit Party (${_groupController.text})'
                            : 'Add New Party (${_groupController.text})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF101B3A)),
                      ),
                      Text(
                        widget.isEdit
                            ? 'Update Master Account Ledger Entry'
                            : 'Master Account Ledger Entry for ${widget.voucherType}',
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

              // GSTIN & Validation Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: _buildTextField(
                      controller: _gstinController,
                      label: 'GSTIN',
                      hintText: 'e.g. 09AABCA1234F1Z5',
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: ElevatedButton.icon(
                      onPressed: _validateGstin,
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
              if (_gstinStatusMessage != null) ...[
                const SizedBox(height: 4),
                Text(
                  _gstinStatusMessage!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _isGstinValid ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Name and Group
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: _buildTextField(
                      controller: _nameController,
                      label: 'Party Name *',
                      hintText: 'Enter registered trade name',
                      validator: (val) => val == null || val.trim().isEmpty ? 'Party name is required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: _buildTextField(
                      controller: _groupController,
                      label: 'Group',
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // PAN, Aadhaar and Mobile
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _panController,
                      label: 'PAN (Auto from GSTIN)',
                      hintText: 'e.g. AABCA1234F',
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _aadhaarController,
                      label: 'Aadhaar No.',
                      hintText: '12-digit Aadhaar number',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _mobileController,
                      label: 'Mobile No.',
                      hintText: '10-digit mobile number',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Address Details
              _buildTextField(
                controller: _addressController,
                label: 'Street Address',
                hintText: 'Building, Street, Area...',
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _stateController,
                      label: 'State',
                      hintText: 'e.g. Uttar Pradesh',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _pincodeController,
                      label: 'PIN Code',
                      hintText: 'e.g. 246761',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _countryController,
                      label: 'Country',
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Actions
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
                      widget.isEdit ? 'Save Changes' : 'Save & Select Party',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    bool readOnly = false,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
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
            readOnly: readOnly,
            validator: validator,
            textCapitalization: textCapitalization,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF101B3A)),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF90A1BA)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: readOnly ? const Color(0xFFF1F5FB) : const Color(0xFFFAFBFD),
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