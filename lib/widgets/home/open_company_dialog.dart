import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/storage_service.dart';

class OpenCompanyDialog extends StatefulWidget {
  final String directoryPath;
  final String illustrationAssetPath;

  const OpenCompanyDialog({
    super.key,
    required this.directoryPath,
    this.illustrationAssetPath = 'assets/images/open_company_dialog.png',
  });

  @override
  State<OpenCompanyDialog> createState() => _OpenCompanyDialogState();
}

class _OpenCompanyDialogState extends State<OpenCompanyDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _dialogFocusNode = FocusNode();
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _filteredCompanies = [];
  bool _isLoading = true;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadCompanies() async {
    final data = await StorageService.loadCompanies(widget.directoryPath);
    if (mounted) {
      setState(() {
        _companies = data;
        _filteredCompanies = data;
        _isLoading = false;
        _selectedIndex = data.isNotEmpty ? 0 : null;
      });
      _dialogFocusNode.requestFocus();
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCompanies = _companies;
      } else {
        _filteredCompanies = _companies.where((company) {
          final name = (company['companyName'] ?? '').toString().toLowerCase();
          final gstin = (company['gstin'] ?? '').toString().toLowerCase();
          final folder = (company['companyId'] ??
                  company['folderName'] ??
                  '')
              .toString()
              .toLowerCase();
          return name.contains(query) ||
              gstin.contains(query) ||
              folder.contains(query);
        }).toList();
      }

      _selectedIndex = _filteredCompanies.isNotEmpty ? 0 : null;
    });
  }

  void _confirmSelection() {
    if (_selectedIndex != null &&
        _selectedIndex! >= 0 &&
        _selectedIndex! < _filteredCompanies.length) {
      Navigator.of(context).pop(_filteredCompanies[_selectedIndex!]);
    }
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.numpad2) {
      if (_filteredCompanies.isNotEmpty) {
        setState(() {
          final current = _selectedIndex ?? -1;
          _selectedIndex = (current + 1).clamp(0, _filteredCompanies.length - 1);
        });
      }
    } else if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.numpad8) {
      if (_filteredCompanies.isNotEmpty) {
        setState(() {
          final current = _selectedIndex ?? 1;
          _selectedIndex = (current - 1).clamp(0, _filteredCompanies.length - 1);
        });
      }
    } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      _confirmSelection();
    } else if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _openEditModal(Map<String, dynamic> company) async {
    final nameController =
        TextEditingController(text: company['companyName'] ?? '');
    final gstinController =
        TextEditingController(text: company['gstin'] ?? '');
    final addressController =
        TextEditingController(text: company['address'] ?? '');
    final cityController = TextEditingController(text: company['city'] ?? '');
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 580,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1E0F172A),
                  blurRadius: 32,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB), size: 22),
                          const SizedBox(width: 10),
                          const Text(
                            'Edit Company Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            icon: const Icon(Icons.close_rounded, size: 20),
                            color: const Color(0xFF64748B),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: nameController,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Company name cannot be empty'
                                : null,
                            decoration: InputDecoration(
                              labelText: 'Company Name',
                              prefixIcon: const Icon(Icons.apartment_rounded, size: 19),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: gstinController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: 'GSTIN',
                              prefixIcon: const Icon(Icons.qr_code_scanner_rounded, size: 19),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: cityController,
                            decoration: InputDecoration(
                              labelText: 'City',
                              prefixIcon: const Icon(Icons.location_city_rounded, size: 19),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: addressController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Address',
                              prefixIcon: const Icon(Icons.location_on_outlined, size: 19),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF475569),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState?.validate() ?? false) {
                                final updatedData = Map<String, dynamic>.from(company);
                                updatedData['companyName'] = nameController.text.trim();
                                updatedData['gstin'] = gstinController.text.trim().toUpperCase();
                                updatedData['city'] = cityController.text.trim();
                                updatedData['address'] = addressController.text.trim();

                                await StorageService.updateCompanyLocally(companyData: updatedData);
                                if (ctx.mounted) Navigator.of(ctx).pop(true);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                            ),
                            child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (updated == true) {
      await _loadCompanies();
      _onSearchChanged();
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> company) async {
    final companyName = company['companyName'] ?? 'Untitled Company';
    final folderLabel = (company['companyId'] ?? company['folderName'] ?? '').toString();

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
              SizedBox(width: 10),
              Text(
                'Delete Company',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to permanently delete "$companyName" ($folderLabel)?',
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await StorageService.deleteCompanyLocally(companyData: company);
      await _loadCompanies();
      _onSearchChanged();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dialogFocusNode.dispose();
    super.dispose();
  }

  Widget _buildFeatureBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEAFE).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 13, color: Color(0xFF2563EB)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _dialogFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        _handleKey(event);
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.arrowDown ||
                event.logicalKey == LogicalKeyboardKey.arrowUp ||
                event.logicalKey == LogicalKeyboardKey.numpad2 ||
                event.logicalKey == LogicalKeyboardKey.numpad8 ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.numpadEnter ||
                event.logicalKey == LogicalKeyboardKey.escape)) {
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Center(
          child: Container(
            width: 820,
            constraints: const BoxConstraints(maxHeight: 720),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEBF2FD), Color(0xFFF7F9FD), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.35, 0.7],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x221E293B),
                  blurRadius: 36,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Positioned(
                    top: -35,
                    right: 48,
                    child: IgnorePointer(
                      child: Image.asset(
                        widget.illustrationAssetPath,
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Opacity(
                            opacity: 0.15,
                            child: Icon(
                              Icons.snippet_folder_rounded,
                              size: 130,
                              color: const Color(0xFF2563EB).withValues(alpha: 0.5),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 18,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: const Color(0xFF94A3B8),
                      splashRadius: 18,
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 24, 160, 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 74,
                              height: 74,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(19),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x352563EB),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.folder_open_rounded,
                                color: Colors.white,
                                size: 38,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Open Company',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    'Find and open an existing company from your local data',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      _buildFeatureBadge('Quick Search'),
                                      _buildFeatureBadge('Organized View'),
                                      _buildFeatureBadge('Open with a Click'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A0F172A),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF0F172A),
                                        ),
                                        decoration: const InputDecoration(
                                          hintText:
                                              'Search company by name, GSTIN, or folder ID...',
                                          hintStyle: TextStyle(
                                            fontSize: 12.5,
                                            color: Color(0xFF94A3B8),
                                          ),
                                          prefixIcon: Icon(
                                            Icons.search_rounded,
                                            size: 19,
                                            color: Color(0xFF2563EB),
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              EdgeInsets.symmetric(vertical: 11),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: const Icon(
                                      Icons.tune_rounded,
                                      size: 18,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Row(
                                  children: const [
                                    SizedBox(width: 44),
                                    Expanded(
                                      flex: 5,
                                      child: Text(
                                        'Company Name',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Center(
                                        child: Text(
                                          'GSTIN',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Center(
                                        child: Text(
                                          'Folder ID',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 80,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          'Actions',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Expanded(
                                child: _isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF2563EB),
                                        ),
                                      )
                                    : _filteredCompanies.isEmpty
                                        ? const Center(
                                            child: Text(
                                              'No matching companies found',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF94A3B8),
                                              ),
                                            ),
                                          )
                                        : ListView.separated(
                                            itemCount: _filteredCompanies.length,
                                            separatorBuilder: (_, __) =>
                                                const SizedBox(height: 8),
                                            itemBuilder: (context, index) {
                                              final company =
                                                  _filteredCompanies[index];
                                              final isSelected =
                                                  _selectedIndex == index;
                                              final hasGstin = company['gstin'] !=
                                                      null &&
                                                  company['gstin']
                                                      .toString()
                                                      .trim()
                                                      .isNotEmpty;
                                              final folderLabel =
                                                  (company['companyId'] ??
                                                          company['folderName'] ??
                                                          'FIN-0001')
                                                      .toString();

                                              return InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                onTap: () => setState(
                                                    () => _selectedIndex = index),
                                                onDoubleTap: () {
                                                  setState(
                                                      () => _selectedIndex = index);
                                                  _confirmSelection();
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 14,
                                                          vertical: 12),
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? const Color(0xFFF4F8FE)
                                                        : Colors.transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(14),
                                                    border: Border.all(
                                                      color: isSelected
                                                        ? const Color(0xFF2563EB)
                                                        : const Color(0xFFE2E8F0),
                                                      width: isSelected ? 1.4 : 1.0,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 20,
                                                        height: 20,
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color: isSelected
                                                              ? const Color(
                                                                  0xFF2563EB)
                                                              : Colors
                                                                  .transparent,
                                                          border: Border.all(
                                                            color: isSelected
                                                                ? const Color(
                                                                    0xFF2563EB)
                                                                : const Color(
                                                                    0xFFCBD5E1),
                                                            width: 1.5,
                                                          ),
                                                        ),
                                                        child: isSelected
                                                            ? const Icon(
                                                                Icons.check,
                                                                size: 13,
                                                                color: Colors.white,
                                                              )
                                                            : null,
                                                      ),
                                                      const SizedBox(width: 12),

                                                      Expanded(
                                                        flex: 5,
                                                        child: Row(
                                                          children: [
                                                            Container(
                                                              width: 36,
                                                              height: 36,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: const Color(
                                                                    0xFFEFF6FF),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(8),
                                                              ),
                                                              child: const Icon(
                                                                Icons
                                                                    .apartment_rounded,
                                                                size: 20,
                                                                color: Color(
                                                                    0xFF2563EB),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 10),
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    company['companyName'] ??
                                                                        'Untitled',
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize: 13,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                      color: Color(
                                                                          0xFF0F172A),
                                                                    ),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                  const SizedBox(
                                                                      height: 2),
                                                                  Text(
                                                                    hasGstin
                                                                        ? 'Primary Company'
                                                                        : 'Unregistered Company',
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize: 11,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w400,
                                                                      color: Color(
                                                                          0xFF94A3B8),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 4,
                                                        child: Center(
                                                          child: hasGstin
                                                              ? Text(
                                                                  company['gstin']
                                                                      .toString()
                                                                      .toUpperCase(),
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize: 12.5,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    letterSpacing:
                                                                        0.5,
                                                                    color: Color(
                                                                        0xFF16A34A),
                                                                  ),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                )
                                                              : Container(
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal: 10,
                                                                      vertical: 4),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: const Color(
                                                                        0xFFFEF3C7),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            12),
                                                                    border: Border.all(
                                                                      color: const Color(
                                                                          0xFFFDE68A),
                                                                    ),
                                                                  ),
                                                                  child: const Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      Icon(
                                                                        Icons
                                                                            .warning_amber_rounded,
                                                                        size: 13,
                                                                        color: Color(
                                                                            0xFFB45309),
                                                                      ),
                                                                      SizedBox(
                                                                          width: 4),
                                                                      Text(
                                                                        'No GSTIN',
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              11,
                                                                          fontWeight:
                                                                              FontWeight.w700,
                                                                          color: Color(
                                                                              0xFFB45309),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                        ),
                                                      ),

                                                      Expanded(
                                                        flex: 3,
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            const Icon(
                                                              Icons.folder_outlined,
                                                              size: 15,
                                                              color: Color(
                                                                  0xFF64748B),
                                                            ),
                                                            const SizedBox(
                                                                width: 6),
                                                            Text(
                                                              folderLabel,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight.w500,
                                                                color: Color(
                                                                    0xFF334155),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),

                                                      SizedBox(
                                                        width: 80,
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment.end,
                                                          children: [
                                                            Container(
                                                              width: 30,
                                                              height: 30,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: const Color(
                                                                    0xFFEFF6FF),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(6),
                                                              ),
                                                              child: IconButton(
                                                                padding:
                                                                    EdgeInsets.zero,
                                                                tooltip: 'Edit',
                                                                icon: const Icon(
                                                                  Icons.edit_outlined,
                                                                  size: 15,
                                                                  color: Color(
                                                                      0xFF2563EB),
                                                                ),
                                                                onPressed: () =>
                                                                    _openEditModal(
                                                                        company),
                                                              ),
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Container(
                                                              width: 30,
                                                              height: 30,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: const Color(
                                                                    0xFFFEE2E2),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(6),
                                                              ),
                                                              child: IconButton(
                                                                padding:
                                                                    EdgeInsets.zero,
                                                                tooltip: 'Delete',
                                                                icon: const Icon(
                                                                  Icons
                                                                      .delete_outline_rounded,
                                                                  size: 15,
                                                                  color: Color(
                                                                      0xFFEF4444),
                                                                ),
                                                                onPressed: () =>
                                                                    _confirmDelete(
                                                                        company),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Icon(
                                Icons.storage_rounded,
                                size: 18,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_filteredCompanies.length} companies found',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const Text(
                                  'Select a company and click Open to continue',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF0F172A),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 22, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _selectedIndex == null
                                  ? null
                                  : _confirmSelection,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 22, vertical: 14),
                                elevation: 4,
                                shadowColor: const Color(0x552563EB),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.arrow_forward_rounded,
                                      size: 16, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    'Open Company',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
}