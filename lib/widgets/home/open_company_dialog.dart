import 'package:flutter/material.dart';
import '../../services/storage_service.dart';

class OpenCompanyDialog extends StatefulWidget {
  final String directoryPath;

  const OpenCompanyDialog({
    super.key,
    required this.directoryPath,
  });

  @override
  State<OpenCompanyDialog> createState() => _OpenCompanyDialogState();
}

class _OpenCompanyDialogState extends State<OpenCompanyDialog> {
  final TextEditingController _searchController = TextEditingController();
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
        if (data.isNotEmpty) {
          _selectedIndex = 0;
        } else {
          _selectedIndex = null;
        }
      });
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

      if (_filteredCompanies.isEmpty) {
        _selectedIndex = null;
      } else {
        _selectedIndex = 0;
      }
    });
  }

  void _confirmSelection() {
    if (_selectedIndex != null &&
        _selectedIndex! >= 0 &&
        _selectedIndex! < _filteredCompanies.length) {
      Navigator.of(context).pop(_filteredCompanies[_selectedIndex!]);
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
            width: 600,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFD6E3F2)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x200A1838),
                  blurRadius: 30,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 18),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAFBFD),
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE5EDF7)),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_note_rounded,
                              color: Color(0xFF0F62FE), size: 24),
                          const SizedBox(width: 10),
                          const Text(
                            'Edit Company Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF101C38),
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
                              prefixIcon: const Icon(Icons.apartment_rounded,
                                  size: 19),
                              filled: true,
                              fillColor: const Color(0xFFF9FBFE),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFD6E3F2)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: gstinController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: 'GSTIN',
                              prefixIcon: const Icon(
                                  Icons.qr_code_scanner_rounded,
                                  size: 19),
                              filled: true,
                              fillColor: const Color(0xFFF9FBFE),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFD6E3F2)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: cityController,
                            decoration: InputDecoration(
                              labelText: 'City',
                              prefixIcon: const Icon(
                                  Icons.location_city_rounded,
                                  size: 19),
                              filled: true,
                              fillColor: const Color(0xFFF9FBFE),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFD6E3F2)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: addressController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Address',
                              prefixIcon: const Icon(
                                  Icons.location_on_outlined,
                                  size: 19),
                              filled: true,
                              fillColor: const Color(0xFFF9FBFE),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFD6E3F2)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAFBFD),
                        border: Border(
                          top: BorderSide(color: Color(0xFFE5EDF7)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState?.validate() ?? false) {
                                final updatedData =
                                    Map<String, dynamic>.from(company);
                                updatedData['companyName'] =
                                    nameController.text.trim();
                                updatedData['gstin'] = gstinController.text
                                    .trim()
                                    .toUpperCase();
                                updatedData['city'] =
                                    cityController.text.trim();
                                updatedData['address'] =
                                    addressController.text.trim();

                                await StorageService.updateCompanyLocally(
                                  companyData: updatedData,
                                );
                                if (ctx.mounted) {
                                  Navigator.of(ctx).pop(true);
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F62FE),
                            ),
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(color: Colors.white),
                            ),
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
    final folderLabel =
        (company['companyId'] ?? company['folderName'] ?? '').toString();

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFEE4343), size: 26),
              SizedBox(width: 10),
              Text(
                'Delete Company',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF101C38),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to permanently delete "$companyName" ($folderLabel)? All associated company files and folders will be removed from your drive.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEE4343),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: Container(
          width: 880,
          constraints: const BoxConstraints(maxHeight: 740),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD6E3F2), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x240A1838),
                blurRadius: 40,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.fromLTRB(32, 22, 24, 22),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAFBFD),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5EDF7), width: 1.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2C7BF6), Color(0xFF0F62FE)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x350F62FE),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.folder_open_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Open Company',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF101C38),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Select an organization stored in ${widget.directoryPath}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF657593),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: const Color(0xFF677797),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),

                // SEARCH BAR
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 20, 32, 12),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF101C38),
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Search by Company Name, GSTIN, or Folder Name...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF90A1B9),
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF0F62FE),
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF9FBFE),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFFD6E3F2), width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFF0F62FE), width: 1.5),
                      ),
                    ),
                  ),
                ),

                // TABLE HEADER
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5FB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          'Company Name',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          'GSTIN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Folder ID',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Center(
                          child: Text(
                            'Actions',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // COMPANY LIST
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF0F62FE),
                          ),
                        )
                      : _filteredCompanies.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.business_center_outlined,
                                    size: 48,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'No matching companies found',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 10),
                              itemCount: _filteredCompanies.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (context, index) {
                                final company = _filteredCompanies[index];
                                final isSelected = _selectedIndex == index;
                                final folderLabel = (company['companyId'] ??
                                        company['folderName'] ??
                                        'Default')
                                    .toString();

                                return InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () =>
                                      setState(() => _selectedIndex = index),
                                  onDoubleTap: () {
                                    setState(() => _selectedIndex = index);
                                    _confirmSelection();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFEFF6FF)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF3B82F6)
                                            : const Color(0xFFE2E8F0),
                                        width: isSelected ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Company Name
                                        Expanded(
                                          flex: 5,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? const Color(0xFF2563EB)
                                                      : const Color(0xFFF1F5F9),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.apartment_rounded,
                                                  size: 18,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : const Color(0xFF475569),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  company['companyName'] ??
                                                      'Untitled',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: isSelected
                                                        ? const Color(0xFF1D4ED8)
                                                        : const Color(
                                                            0xFF0F172A),
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // GSTIN
                                        Expanded(
                                          flex: 4,
                                          child: Text(
                                            (company['gstin'] != null &&
                                                    company['gstin']
                                                        .toString()
                                                        .isNotEmpty)
                                                ? company['gstin'].toString()
                                                : 'Unregistered',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                              color: (company['gstin'] !=
                                                          null &&
                                                      company['gstin']
                                                          .toString()
                                                          .isNotEmpty)
                                                  ? const Color(0xFF334155)
                                                  : const Color(0xFF94A3B8),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),

                                        // Folder Name / ID
                                        Expanded(
                                          flex: 3,
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.folder_outlined,
                                                size: 16,
                                                color: Color(0xFF64748B),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  folderLabel,
                                                  style: const TextStyle(
                                                    fontSize: 12.5,
                                                    fontFamily: 'monospace',
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // ACTION BUTTONS (EDIT & DELETE)
                                        SizedBox(
                                          width: 100,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                tooltip: 'Edit Company',
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 18,
                                                  color: Color(0xFF0F62FE),
                                                ),
                                                onPressed: () =>
                                                    _openEditModal(company),
                                                style: IconButton.styleFrom(
                                                  hoverColor:
                                                      const Color(0xFFE8F1FE),
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: 'Delete Company',
                                                icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  size: 18,
                                                  color: Color(0xFFEE4343),
                                                ),
                                                onPressed: () =>
                                                    _confirmDelete(company),
                                                style: IconButton.styleFrom(
                                                  hoverColor:
                                                      const Color(0xFFFFECEC),
                                                  padding:
                                                      const EdgeInsets.all(8),
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

                // FOOTER
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAFBFD),
                    border: Border(
                      top: BorderSide(color: Color(0xFFE5EDF7), width: 1.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${_filteredCompanies.length} organizations detected',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed:
                            _selectedIndex == null ? null : _confirmSelection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F62FE),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_rounded,
                                size: 18, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Open Selected',
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
          ),
        ),
      ),
    );
  }
}