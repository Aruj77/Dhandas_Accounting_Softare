import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../services/focus_policy_service.dart';
import '../services/keyboard_shortcut_service.dart';
import '../services/storage_service.dart';
import '../services/loading_service.dart';
import '../widgets/sidebar.dart';
import '../widgets/top_bar.dart';
import '../widgets/set_directory_dialog.dart';
import '../widgets/company/company_workspace_footer.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/company_action_card.dart';
import '../widgets/home/data_action_card.dart';
import '../widgets/home/data_directory_banner.dart';
import '../widgets/home/recent_companies_panel.dart';
import '../widgets/home/quick_tips_panel.dart';
import '../widgets/home/create_company_dialog.dart';
import '../widgets/home/open_company_dialog.dart';
import 'settings_screen.dart';
import 'company/transactions_dashboard.dart';
import 'company/administration_screen.dart';
import 'company/reports_dashboard_screen.dart';
import 'company/voucher/voucher_entry_screen.dart';
import 'company/voucher/voucher_list_screen.dart';
import 'company/masters_dashboard_screen.dart';

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _currentDataDirectory;
  List<Map<String, dynamic>> _recentCompanies = [];
  bool _isLoadingDirectory = true;
  KeyboardShortcutSettings _keyboardSettings =
      KeyboardShortcutSettings.defaults();

  Map<String, dynamic>? _activeCompany;
  String? _activeVoucherType;
  _ListParams? _activeListQuery;

  final GlobalKey<SideBarState> _sidebarKey = GlobalKey<SideBarState>();
  final GlobalKey<TransactionsDashboardState> _dashboardKey =
      GlobalKey<TransactionsDashboardState>();

  final FocusNode _openCompanyBtnFocus = FocusNode();
  final FocusNode _createCompanyBtnFocus = FocusNode();
  final FocusNode _backupDataFocus = FocusNode();
  final FocusNode _restoreDataFocus = FocusNode();
  final FocusNode _dataDirBannerFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadStoredDirectoryAndData();
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

  Future<void> _handleKeyboardSettingsChanged(
    KeyboardShortcutSettings settings,
  ) async {
    await KeyboardShortcutService.saveSettings(settings);
    if (mounted) {
      setState(() => _keyboardSettings = settings);
    }
  }

  Future<void> _loadStoredDirectoryAndData() async {
    await LoadingService.wrap(() async {
      final savedPath = await StorageService.getSavedDirectory();
      if (savedPath != null) {
        final companies = await StorageService.loadCompanies(savedPath);
        if (mounted) {
          setState(() {
            _currentDataDirectory = savedPath;
            _recentCompanies = companies;
            _isLoadingDirectory = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingDirectory = false);
        }
      }
    }, message: 'Initializing Workspace...');
  }

  void _showSetDirectoryModal() {
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
            child: SetDirectoryDialog(initialPath: _currentDataDirectory),
          ),
        );
      },
    ).then((newPath) async {
      if (newPath != null && newPath.isNotEmpty) {
        await LoadingService.wrap(() async {
          final companies = await StorageService.loadCompanies(newPath);
          if (mounted) {
            setState(() {
              _currentDataDirectory = newPath;
              _recentCompanies = companies;
            });
          }
        }, message: 'Scanning Directory...');
      }
    });
  }

  void _showOpenCompanyModal() {
    if (_currentDataDirectory == null) {
      _promptSetDirectoryFirst();
      return;
    }

    showGeneralDialog<Map<String, dynamic>>(
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
            child: OpenCompanyDialog(directoryPath: _currentDataDirectory!),
          ),
        );
      },
    ).then((selectedCompany) {
      if (selectedCompany != null && mounted) {
        setState(() {
          _activeCompany = selectedCompany;
          _selectedIndex = 0;
          _activeVoucherType = null;
          _activeListQuery = null;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _sidebarKey.currentState?.focusActiveItem();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Opened workspace for: ${selectedCompany['companyName']}',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    });
  }

  void _showCreateCompanyModal() {
    if (_currentDataDirectory == null) {
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
            child: CreateCompanyDialog(currentDirectory: _currentDataDirectory),
          ),
        );
      },
    ).then((saved) async {
      if (saved == true && _currentDataDirectory != null) {
        await LoadingService.wrap(() async {
          final companies =
              await StorageService.loadCompanies(_currentDataDirectory!);
          if (mounted) {
            setState(() => _recentCompanies = companies);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Company database created and saved successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }, message: 'Updating Workspace...');
      }
    });
  }

  void _promptSetDirectoryFirst() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please configure a Data Directory first.'),
        backgroundColor: AppColors.warning,
        action: SnackBarAction(
          label: 'Set Now',
          textColor: AppColors.surface,
          onPressed: _showSetDirectoryModal,
        ),
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

    if (_activeVoucherType != null) {
      content = VoucherEntryScreen(
        company: _activeCompany!,
        voucherType: _activeVoucherType!,
        onClose: () => setState(() => _activeVoucherType = null),
        keyboardSettings: _keyboardSettings,
      );
    } else if (_activeListQuery != null) {
      content = VoucherListScreen(
        company: _activeCompany!,
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
            activeCompany: _activeCompany,
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
                onChangeFy: () => setState(() {
                  _activeVoucherType = null;
                  _activeListQuery = null;
                  _selectedIndex = 4;
                }),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCompanyView() {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        // 0: TRANSACTIONS
        TransactionsDashboard(
          key: _dashboardKey,
          company: _activeCompany!,
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

        // 1: ACCOUNTS & LEDGERS
        MastersDashboardScreen(company: _activeCompany!),

        // 2: INVENTORY & ITEMS
        _buildPlaceholderView(
          icon: Icons.inventory_2_outlined,
          title: 'Inventory & Items',
          subtitle: 'Stock items, HSN codes, batches, and unit measurements.',
        ),

        // 3: REPORTS
        ReportsDashboardScreen(company: _activeCompany!),

        // 4: ADMINISTRATION
        AdministrationScreen(
          company: _activeCompany!,
          onCompanyUpdated: (updated) {
            setState(() => _activeCompany = updated);
          },
        ),
      ],
    );
  }

  Widget _buildGlobalIndexedView() {
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
          currentDirectory: _currentDataDirectory,
          onChangeDirectory: _showSetDirectoryModal,
          keyboardSettings: _keyboardSettings,
          onKeyboardSettingsChanged: _handleKeyboardSettingsChanged,
        ),
      ],
    );
  }

  Widget _buildHomeDashboardView() {
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Starting automated database backup...'),
                        backgroundColor: AppColors.purple,
                      ),
                    );
                  },
                  onRestore: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Open restore snapshot chooser...'),
                        backgroundColor: AppColors.purple,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          DataDirectoryBanner(
            focusNode: _dataDirBannerFocus,
            currentDirectory: _currentDataDirectory,
            isLoading: _isLoadingDirectory,
            onTap: _showSetDirectoryModal,
            onMoveUp: () => _openCompanyBtnFocus.requestFocus(),
            onMoveLeft: _jumpToSidebar,
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RecentCompaniesPanel(companies: _recentCompanies),
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