// lib/pages/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company_model.dart';
import '../constants/app_colors.dart';
import '../provider/company_provider.dart';
import '../services/focus_policy_service.dart';
import '../services/keyboard_shortcut_service.dart';
import '../services/loading_service.dart';
import '../services/notification_service.dart';
import '../widgets/company/company_workspace_footer.dart';
import '../widgets/home/company_action_card.dart';
import '../widgets/home/create_company_dialog.dart';
import '../widgets/home/data_action_card.dart';
import '../widgets/home/data_directory_banner.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/open_company_dialog.dart';
import '../widgets/home/quick_tips_panel.dart';
import '../widgets/home/recent_companies_panel.dart';
import '../widgets/set_directory_dialog.dart';
import '../widgets/sidebar.dart';
import '../widgets/top_bar.dart';
import 'company/gstr2b_reconciliation_screen.dart';
import 'company/masters_dashboard_screen.dart';
import 'company/reports_dashboard_screen.dart';
import 'company/transactions_dashboard.dart';
import 'company/voucher/voucher_entry_screen.dart';
import 'company/voucher/voucher_list_screen.dart';
import 'settings_screen.dart';

class _ListParams {
  final String voucherType;
  final DateTime fromDate;
  final DateTime toDate;
  final String series;

  _ListParams({
    required this.voucherType,
    required this.fromDate,
    required this.toDate,
    this.series = 'All',
  });
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  KeyboardShortcutSettings _keyboardSettings = KeyboardShortcutSettings.defaults();

  CompanyModel? _activeCompany;
  String? _activeVoucherType;
  _ListParams? _activeListQuery;

  final GlobalKey<SideBarState> _sidebarKey = GlobalKey<SideBarState>();
  final GlobalKey<TransactionsDashboardState> _dashboardKey = GlobalKey<TransactionsDashboardState>();

  final FocusNode _openCompanyBtnFocus = FocusNode();
  final FocusNode _createCompanyBtnFocus = FocusNode();
  final FocusNode _backupDataFocus = FocusNode();
  final FocusNode _restoreDataFocus = FocusNode();
  final FocusNode _dataDirBannerFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadKeyboardSettings();

    FocusPolicyService.requestScreenFocus(
      screen: FocusTargetScreen.homeDashboard,
      nodeMap: {
        FocusFieldNode.firstField: _openCompanyBtnFocus,
        FocusFieldNode.secondaryAction: _createCompanyBtnFocus,
      },
    );
  }

  @override
  void dispose() {
    _openCompanyBtnFocus.dispose();
    _createCompanyBtnFocus.dispose();
    _backupDataFocus.dispose();
    _restoreDataFocus.dispose();
    _dataDirBannerFocus.dispose();
    super.dispose();
  }

  Future<void> _loadKeyboardSettings() async {
    final settings = await KeyboardShortcutService.loadSettings();
    if (mounted) {
      setState(() => _keyboardSettings = settings);
    }
  }

  Future<void> _handleKeyboardSettingsChanged(KeyboardShortcutSettings settings) async {
    await KeyboardShortcutService.saveSettings(settings);
    if (mounted) {
      setState(() => _keyboardSettings = settings);
    }
  }

  void _showSetDirectoryModal() {
    final currentDir = ref.read(dataDirectoryProvider);
    showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Set Directory Dialog',
      barrierColor: AppColors.primaryDark.withValues(alpha: 0.38),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curvedValue = Curves.easeOutCubic.transform(anim1.value);
        return Transform.scale(
          scale: curvedValue,
          child: Opacity(
            opacity: anim1.value.clamp(0.0, 1.0),
            child: SetDirectoryDialog(initialPath: currentDir),
          ),
        );
      },
    ).then((newPath) async {
      if (newPath != null && newPath.isNotEmpty) {
        await LoadingService.wrap(() async {
          await ref.read(dataDirectoryProvider.notifier).setDirectory(newPath);
        }, message: 'Scanning Directory...');
      }
    });
  }

  void _showOpenCompanyModal() {
    final currentDir = ref.read(dataDirectoryProvider);
    if (currentDir == null) {
      _promptSetDirectoryFirst();
      return;
    }

    showGeneralDialog<dynamic>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Open Company Dialog',
      barrierColor: AppColors.primaryDark.withValues(alpha: 0.38),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curvedValue = Curves.easeOutBack.transform(anim1.value);
        return Transform.scale(
          scale: curvedValue,
          child: Opacity(
            opacity: anim1.value.clamp(0.0, 1.0),
            child: OpenCompanyDialog(directoryPath: currentDir),
          ),
        );
      },
    ).then((selectedCompany) {
      if (selectedCompany != null && mounted) {
        final CompanyModel companyModel = selectedCompany is CompanyModel
            ? selectedCompany
            : CompanyModel.fromJson(selectedCompany as Map<String, dynamic>);

        setState(() {
          _activeCompany = companyModel;
          _selectedIndex = 0;
          _activeVoucherType = null;
          _activeListQuery = null;
        });

        _syncCompanyToProvider(companyModel);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _sidebarKey.currentState?.focusActiveItem();
        });

        NotificationService.show(
          context,
          message: 'Opened workspace for: ${companyModel.companyName}',
          type: NotificationType.success,
        );
      }
    });
  }

  void _syncCompanyToProvider(CompanyModel company) {
    try {
      ref.read(activeCompanyProvider.notifier).state = company as dynamic;
    } catch (_) {
      ref.read(activeCompanyProvider.notifier).state = company.toJson() as dynamic;
    }
  }

  void _showCreateCompanyModal() {
    final currentDir = ref.read(dataDirectoryProvider);
    if (currentDir == null) {
      _promptSetDirectoryFirst();
      return;
    }

    showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Create Company Dialog',
      barrierColor: AppColors.primaryDark.withValues(alpha: 0.38),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curvedValue = Curves.easeOutBack.transform(anim1.value);
        return Transform.scale(
          scale: curvedValue,
          child: Opacity(
            opacity: anim1.value.clamp(0.0, 1.0),
            child: CreateCompanyDialog(currentDirectory: currentDir),
          ),
        );
      },
    ).then((saved) async {
      if (saved == true && mounted) {
        ref.invalidate(companiesProvider);
        NotificationService.show(
          context,
          message: 'Company database created and saved successfully!',
          type: NotificationType.success,
        );
      }
    });
  }

  void _promptSetDirectoryFirst() {
    NotificationService.show(
      context,
      message: 'Please configure a Data Directory first.',
      type: NotificationType.warning,
      action: SnackBarAction(
        label: 'Set Now',
        textColor: AppColors.surface,
        onPressed: _showSetDirectoryModal,
      ),
    );
  }

  bool _isEditableFocusActive() {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext == null) return false;
    return focusContext.widget is EditableText ||
        focusContext.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  void _switchWorkspace() {
    if (_activeCompany == null) return;
    setState(() {
      _activeCompany = null;
      _selectedIndex = 0;
      _activeVoucherType = null;
      _activeListQuery = null;
    });

    ref.read(activeCompanyProvider.notifier).state = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sidebarKey.currentState?.focusActiveItem();
    });
  }

  void _goBack() {
    if (_activeVoucherType != null) {
      setState(() => _activeVoucherType = null);
      return;
    }

    if (_activeListQuery != null) {
      setState(() => _activeListQuery = null);
      return;
    }

    if (_activeCompany != null) {
      _switchWorkspace();
      return;
    }

    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
    }
  }

  void _jumpToRightPane() {
    if (_activeCompany != null && _selectedIndex == 0) {
      _dashboardKey.currentState?.focusFirstTile();
    } else if (_activeCompany == null && _selectedIndex == 0) {
      _openCompanyBtnFocus.requestFocus();
    }
  }

  void _jumpToSidebar() {
    _sidebarKey.currentState?.focusActiveItem();
  }

  KeyEventResult _handleKeyboardEvent(FocusNode node, KeyEvent event) {
    if (!_keyboardSettings.keyboardIntensiveMode) {
      return KeyEventResult.ignored;
    }

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (_isEditableFocusActive()) {
      return KeyEventResult.ignored;
    }

    if (KeyboardShortcutService.matchesAction(
      _keyboardSettings,
      KeyboardShortcutService.goBackAction,
      event,
    )) {
      _goBack();
      return KeyEventResult.handled;
    }

    if (_activeVoucherType != null || _activeListQuery != null) {
      return KeyEventResult.ignored;
    }

    if (KeyboardShortcutService.matchesAction(
      _keyboardSettings,
      KeyboardShortcutService.openCompanyAction,
      event,
    )) {
      _showOpenCompanyModal();
      return KeyEventResult.handled;
    }

    if (KeyboardShortcutService.matchesAction(
      _keyboardSettings,
      KeyboardShortcutService.createCompanyAction,
      event,
    )) {
      _showCreateCompanyModal();
      return KeyEventResult.handled;
    }

    if (KeyboardShortcutService.matchesAction(
      _keyboardSettings,
      KeyboardShortcutService.changeDirectoryAction,
      event,
    )) {
      _showSetDirectoryModal();
      return KeyEventResult.handled;
    }

    if (KeyboardShortcutService.matchesAction(
      _keyboardSettings,
      KeyboardShortcutService.openSettingsAction,
      event,
    )) {
      setState(() {
        _activeCompany = null;
        _activeVoucherType = null;
        _activeListQuery = null;
        _selectedIndex = 3;
      });
      ref.read(activeCompanyProvider.notifier).state = null;
      return KeyEventResult.handled;
    }

    if (KeyboardShortcutService.matchesAction(
      _keyboardSettings,
      KeyboardShortcutService.switchWorkspaceAction,
      event,
    )) {
      _switchWorkspace();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    _activeCompany?.toJson();

    if (_activeVoucherType != null) {
      content = VoucherEntryScreen(
        company: _activeCompany!, // Pass CompanyModel directly
        voucherType: _activeVoucherType!,
        onClose: () => setState(() => _activeVoucherType = null),
        keyboardSettings: _keyboardSettings,
      );
    } else if (_activeListQuery != null) {
      content = VoucherListScreen(
        company: _activeCompany!, // Pass CompanyModel directly
        voucherType: _activeListQuery!.voucherType,
        fromDate: _activeListQuery!.fromDate,
        toDate: _activeListQuery!.toDate,
        initialSeries: _activeListQuery!.series,
        onClose: () => setState(() => _activeListQuery = null),
      );
    } else {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SideBar(
            key: _sidebarKey,
            selectedIndex: _selectedIndex,
            activeCompany: _activeCompany?.toJson(), // SideBar can still accept a map if needed
            onSwitchCompany: _switchWorkspace,
            onMoveToRightPane: _jumpToRightPane,
            onItemSelected: (index) {
              setState(() => _selectedIndex = index);
            },
          ),
          Expanded(
            child: Column(
              children: [
                const TopBar(),
                Expanded(
                  child: _activeCompany != null
                      ? _buildActiveCompanyView()
                      : _buildGlobalIndexedView(),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyboardEvent,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Expanded(child: content),
            if (_activeCompany != null)
              CompanyWorkspaceFooter(
                company: _activeCompany!,
                onCompanyUpdated: (dynamic updated) {
                  final CompanyModel updatedModel = updated is CompanyModel
                      ? updated
                      : CompanyModel.fromJson(updated as Map<String, dynamic>);
                  setState(() => _activeCompany = updatedModel);
                  _syncCompanyToProvider(updatedModel);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCompanyView() {
    final activeCompany = _activeCompany!;

   return IndexedStack(
      index: _selectedIndex,
      children: [
        TransactionsDashboard(
          key: _dashboardKey,
          company: activeCompany, // Pass CompanyModel
          onMoveToSidebar: _jumpToSidebar,
          onAddTransaction: (vchType) {
            setState(() {
              _activeVoucherType = vchType;
              _activeListQuery = null;
            });
          },
          onShowList: (vchType, from, to, series) {
            setState(() {
              _activeListQuery = _ListParams(
                voucherType: vchType,
                fromDate: from,
                toDate: to,
                series: series,
              );
              _activeVoucherType = null;
            });
          },
        ),
        MastersDashboardScreen(company: activeCompany), // Pass CompanyModel
        _buildPlaceholderView(
          icon: Icons.inventory_2_outlined,
          title: 'Inventory & Items',
          subtitle: 'Stock items, HSN codes, batches, and unit measurements.',
        ),
        ReportsDashboardScreen(company: activeCompany), // Pass CompanyModel
        const Gstr2bReconciliationScreen(),
      ],
    );
  }

  Widget _buildGlobalIndexedView() {
    final currentDir = ref.watch(dataDirectoryProvider);

    return IndexedStack(
      index: _selectedIndex,
      children: [
        _buildHomeDashboardView(),
        _buildPlaceholderView(
          icon: Icons.apartment_outlined,
          title: 'Companies Directory',
          subtitle: 'Browse all registered company databases.',
        ),
        _buildPlaceholderView(
          icon: Icons.layers_outlined,
          title: 'Data & Archives',
          subtitle: 'Manage backups and migrations.',
        ),
        SettingsScreen(
          currentDirectory: currentDir,
          onChangeDirectory: _showSetDirectoryModal,
          keyboardSettings: _keyboardSettings,
          onKeyboardSettingsChanged: _handleKeyboardSettingsChanged,
        ),
      ],
    );
  }

  Widget _buildHomeDashboardView() {
    final currentDir = ref.watch(dataDirectoryProvider);
    final companiesAsync = ref.watch(companiesProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeHeader(),
          const SizedBox(height: 26),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 50,
                child: CompanyActionCard(
                  openCompanyFocusNode: _openCompanyBtnFocus,
                  createCompanyFocusNode: _createCompanyBtnFocus,
                  onOpenCompany: _showOpenCompanyModal,
                  onCreateCompany: _showCreateCompanyModal,
                  onMoveToSidebar: _jumpToSidebar,
                  onMoveRight: () => _backupDataFocus.requestFocus(),
                  onMoveDown: () => _dataDirBannerFocus.requestFocus(),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 50,
                child: DataActionCard(
                  backupFocusNode: _backupDataFocus,
                  restoreFocusNode: _restoreDataFocus,
                  onMoveLeft: () => _createCompanyBtnFocus.requestFocus(),
                  onMoveRight: () => _dataDirBannerFocus.requestFocus(),
                  onMoveDown: () => _dataDirBannerFocus.requestFocus(),
                  onBackup: () {
                    NotificationService.show(
                      context,
                      message: 'Starting automated database backup...',
                      type: NotificationType.info,
                    );
                  },
                  onRestore: () {
                    NotificationService.show(
                      context,
                      message: 'Open restore snapshot chooser...',
                      type: NotificationType.info,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          DataDirectoryBanner(
            focusNode: _dataDirBannerFocus,
            currentDirectory: currentDir,
            isLoading: currentDir != null && companiesAsync.isLoading,
            onTap: _showSetDirectoryModal,
            onMoveUp: () => _openCompanyBtnFocus.requestFocus(),
            onMoveLeft: _jumpToSidebar,
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: companiesAsync.when(
                  data: (companies) => RecentCompaniesPanel(
                    companies: companies.map((c) => c.toJson()).toList(),
                  ),
                  loading: () => const RecentCompaniesPanel(companies: []),
                  error: (_, __) => const RecentCompaniesPanel(companies: []),
                ),
              ),
              const SizedBox(width: 20),
              const Expanded(child: QuickTipsPanel()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderView({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}