import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../provider/company_provider.dart';
import '../../widgets/common/app_confirm_dialog.dart';
import '../../services/loading_service.dart';
import '../../services/keyboard_shortcut_service.dart';

class OpenCompanyDialog extends ConsumerStatefulWidget {
  final String directoryPath;
  final String illustrationAssetPath;

  const OpenCompanyDialog({
    super.key,
    required this.directoryPath,
    this.illustrationAssetPath = 'assets/images/open_company_dialog.png',
  });

  @override
  ConsumerState<OpenCompanyDialog> createState() => _OpenCompanyDialogState();
}

class _OpenCompanyDialogState extends ConsumerState<OpenCompanyDialog> {
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
    await LoadingService.wrap(() async {
      final repo = ref.read(companyRepositoryProvider);
      final data = await repo.loadCompanies(widget.directoryPath);
      if (mounted) {
        setState(() {
          _companies = data;
          _filteredCompanies = data;
          _isLoading = false;
          _selectedIndex = data.isNotEmpty ? 0 : null;
        });
        _dialogFocusNode.requestFocus();
      }
    }, message: 'Scanning directory for companies...');
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
    if (KeyboardShortcutService.isDown(event)) {
      if (_filteredCompanies.isNotEmpty) {
        setState(() {
          final current = _selectedIndex ?? -1;
          _selectedIndex = (current + 1).clamp(0, _filteredCompanies.length - 1);
        });
      }
    } else if (KeyboardShortcutService.isUp(event)) {
      if (_filteredCompanies.isNotEmpty) {
        setState(() {
          final current = _selectedIndex ?? 1;
          _selectedIndex = (current - 1).clamp(0, _filteredCompanies.length - 1);
        });
      }
    } else if (KeyboardShortcutService.isConfirm(event)) {
      _confirmSelection();
    } else if (KeyboardShortcutService.isExit(event)) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _openEditModal(Map<String, dynamic> company) async {
    await LoadingService.wrap(() async {
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
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowColor,
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
                          color: AppColors.cardBg,
                          border: Border(bottom: BorderSide(color: AppColors.border)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.edit_note_rounded, color: AppColors.primaryAccent, size: 22),
                            const SizedBox(width: 10),
                            const Text(
                              'Edit Company Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              icon: const Icon(Icons.close_rounded, size: 20),
                              color: AppColors.textSecondary,
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
                                fillColor: AppColors.cardBg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.border),
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
                                fillColor: AppColors.cardBg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.border),
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
                                fillColor: AppColors.cardBg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.border),
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
                                fillColor: AppColors.cardBg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: const BoxDecoration(
                          color: AppColors.cardBg,
                          border: Border(top: BorderSide(color: AppColors.border)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                side: const BorderSide(color: AppColors.borderMedium),
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

                                  final repo = ref.read(companyRepositoryProvider);
                                  await repo.updateCompany(companyData: updatedData);
                                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryAccent,
                              ),
                              child: const Text('Save Changes', style: TextStyle(color: AppColors.surface)),
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
        ref.invalidate(companiesProvider);
      }
    }, message: 'Updating Company Data...');
  }

  Future<void> _confirmDelete(Map<String, dynamic> company) async {
    await LoadingService.wrap(() async {
      final companyName = company['companyName'] ?? 'Untitled Company';
      final folderLabel = (company['companyId'] ?? company['folderName'] ?? '').toString();

      final shouldDelete = await AppConfirmDialog.show(
        context: context,
        title: 'Delete Company',
        message: 'Are you sure you want to permanently delete "$companyName" ($folderLabel)?',
        confirmLabel: 'Delete',
        type: ConfirmDialogType.danger,
      );

      if (shouldDelete == true) {
        final repo = ref.read(companyRepositoryProvider);
        await repo.deleteCompany(companyData: company);
        await _loadCompanies();
        _onSearchChanged();
        ref.invalidate(companiesProvider);
      }
    }, message: 'Removing Company Data...');
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
        color: AppColors.badgeBlueFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 13, color: AppColors.primaryAccent),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryAccent,
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
        if (KeyboardShortcutService.isDown(event) ||
            KeyboardShortcutService.isUp(event) ||
            KeyboardShortcutService.isConfirm(event) ||
            KeyboardShortcutService.isExit(event)) {
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
                colors: [AppColors.dialogBgStart, AppColors.dialogBgMiddle, AppColors.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.35, 0.7],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.surface, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowColor,
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
                              color: AppColors.primaryAccent.withValues(alpha: 0.5),
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
                      color: AppColors.textMuted,
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
                                  colors: [AppColors.primarySemiLight, AppColors.primary],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(19),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryAccent.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.folder_open_rounded,
                                color: AppColors.surface,
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
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    'Find and open an existing company from your local data',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textSecondary,
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
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadowColor,
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
                                        color: AppColors.cardBg,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary,
                                        ),
                                        decoration: const InputDecoration(
                                          hintText:
                                              'Search company by name, GSTIN, or folder ID...',
                                          hintStyle: TextStyle(
                                            fontSize: 12.5,
                                            color: AppColors.textMuted,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.search_rounded,
                                            size: 19,
                                            color: AppColors.primaryAccent,
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
                                      color: AppColors.cardBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: const Icon(
                                      Icons.tune_rounded,
                                      size: 18,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    SizedBox(width: 44),
                                    Expanded(
                                      flex: 5,
                                      child: Text(
                                        'Company Name',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textSecondary,
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
                                            color: AppColors.textSecondary,
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
                                            color: AppColors.textSecondary,
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
                                            color: AppColors.textSecondary,
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
                                          color: AppColors.primaryAccent,
                                        ),
                                      )
                                    : _filteredCompanies.isEmpty
                                        ? const Center(
                                            child: Text(
                                              'No matching companies found',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.textMuted,
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
                                                        ? AppColors.primaryLight
                                                        : Colors.transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(14),
                                                    border: Border.all(
                                                      color: isSelected
                                                          ? AppColors.primaryAccent
                                                          : AppColors.border,
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
                                                              ? AppColors.primaryAccent
                                                              : Colors.transparent,
                                                          border: Border.all(
                                                            color: isSelected
                                                                ? AppColors.primaryAccent
                                                                : AppColors.borderMedium,
                                                            width: 1.5,
                                                          ),
                                                        ),
                                                        child: isSelected
                                                            ? const Icon(
                                                                Icons.check,
                                                                size: 13,
                                                                color: AppColors.surface,
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
                                                                color: AppColors.primaryLight,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(8),
                                                              ),
                                                              child: const Icon(
                                                                Icons.apartment_rounded,
                                                                size: 20,
                                                                color: AppColors.primaryAccent,
                                                              ),
                                                            ),
                                                            const SizedBox(width: 10),
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
                                                                      color: AppColors.textPrimary,
                                                                    ),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                  const SizedBox(height: 2),
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
                                                                      color: AppColors.textMuted,
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
                                                                    color: AppColors.success,
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
                                                                    color: AppColors.badgeYellowBg,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            12),
                                                                    border: Border.all(
                                                                      color: AppColors.badgeYellowBorder,
                                                                    ),
                                                                  ),
                                                                  child: const Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      Icon(
                                                                        Icons.warning_amber_rounded,
                                                                        size: 13,
                                                                        color: AppColors.badgeYellowText,
                                                                      ),
                                                                      SizedBox(width: 4),
                                                                      Text(
                                                                        'No GSTIN',
                                                                        style: TextStyle(
                                                                          fontSize: 11,
                                                                          fontWeight: FontWeight.w700,
                                                                          color: AppColors.badgeYellowText,
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
                                                              MainAxisAlignment.center,
                                                          children: [
                                                            const Icon(
                                                              Icons.folder_outlined,
                                                              size: 15,
                                                              color: AppColors.textSecondary,
                                                            ),
                                                            const SizedBox(width: 6),
                                                            Text(
                                                              folderLabel,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight.w500,
                                                                color: AppColors.textPrimary,
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
                                                                color: AppColors.primaryLight,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(6),
                                                              ),
                                                              child: IconButton(
                                                                padding: EdgeInsets.zero,
                                                                tooltip: 'Edit',
                                                                icon: const Icon(
                                                                  Icons.edit_outlined,
                                                                  size: 15,
                                                                  color: AppColors.primaryAccent,
                                                                ),
                                                                onPressed: () =>
                                                                    _openEditModal(company),
                                                              ),
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Container(
                                                              width: 30,
                                                              height: 30,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: AppColors.errorLight,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(6),
                                                              ),
                                                              child: IconButton(
                                                                padding: EdgeInsets.zero,
                                                                tooltip: 'Delete',
                                                                icon: const Icon(
                                                                  Icons.delete_outline_rounded,
                                                                  size: 15,
                                                                  color: AppColors.errorDark,
                                                                ),
                                                                onPressed: () =>
                                                                    _confirmDelete(company),
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
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(
                                Icons.storage_rounded,
                                size: 18,
                                color: AppColors.textSecondary,
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
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const Text(
                                  'Select a company and click Open to continue',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppColors.surface,
                                foregroundColor: AppColors.textPrimary,
                                side: const BorderSide(color: AppColors.borderMedium),
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
                                backgroundColor: AppColors.primaryAccent,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 22, vertical: 14),
                                elevation: 4,
                                shadowColor: AppColors.primaryAccent.withValues(alpha: 0.35),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.arrow_forward_rounded,
                                      size: 16, color: AppColors.surface),
                                  SizedBox(width: 6),
                                  Text(
                                    'Open Company',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.surface,
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