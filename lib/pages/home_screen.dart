import 'package:flutter/material.dart';
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
import 'company/voucher_entry_screen.dart';
import 'company/voucher_list_screen.dart';

class _ListParams {
  final String voucherType;
  final DateTime fromDate;
  final DateTime toDate;

  _ListParams({
    required this.voucherType,
    required this.fromDate,
    required this.toDate,
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

  Map<String, dynamic>? _activeCompany;
  String? _activeVoucherType;
  _ListParams? _activeListQuery;

  @override
  void initState() {
    super.initState();
    _loadStoredDirectoryAndData();
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
      barrierColor: const Color(0x60091834),
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
      barrierColor: const Color(0x60091834),
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Opened workspace for: ${selectedCompany['companyName']}',
            ),
            backgroundColor: const Color(0xFF0F62FE),
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
      barrierColor: const Color(0x60091834),
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
                content: Text('Company database created and saved successfully!'),
                backgroundColor: Color(0xFF11A25B),
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
        backgroundColor: const Color(0xFFF39E00),
        action: SnackBarAction(
          label: 'Set Now',
          textColor: Colors.white,
          onPressed: _showSetDirectoryModal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_activeVoucherType != null) {
      content = VoucherEntryScreen(
        company: _activeCompany!,
        voucherType: _activeVoucherType!,
        onClose: () => setState(() => _activeVoucherType = null),
      );
    } else if (_activeListQuery != null) {
      content = VoucherListScreen(
        company: _activeCompany!,
        voucherType: _activeListQuery!.voucherType,
        fromDate: _activeListQuery!.fromDate,
        toDate: _activeListQuery!.toDate,
        onClose: () => setState(() => _activeListQuery = null),
      );
    } else {
      content = Row(
        children: [
          SideBar(
            selectedIndex: _selectedIndex,
            activeCompany: _activeCompany,
            onSwitchCompany: () {
              setState(() {
                _activeCompany = null;
                _selectedIndex = 0;
                _activeVoucherType = null;
                _activeListQuery = null;
              });
            },
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

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FB),
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
    );
  }

  Widget _buildActiveCompanyView() {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        // 0: TRANSACTIONS
        TransactionsDashboard(
          company: _activeCompany!,
          onAddTransaction: (vchType) {
            setState(() {
              _activeVoucherType = vchType;
              _activeListQuery = null;
            });
          },
          onShowList: (vchType, from, to) {
            setState(() {
              _activeListQuery = _ListParams(
                voucherType: vchType,
                fromDate: from,
                toDate: to,
              );
              _activeVoucherType = null;
            });
          },
        ),

        // 1: ACCOUNTS & LEDGERS
        _buildPlaceholderView(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Accounts & Ledgers',
          subtitle: 'Manage charts of accounts, sundry debtors, and creditors.',
        ),

        // 2: INVENTORY & ITEMS
        _buildPlaceholderView(
          icon: Icons.inventory_2_outlined,
          title: 'Inventory & Items',
          subtitle: 'Stock items, HSN codes, batches, and unit measurements.',
        ),

        // 3: REPORTS
        _buildPlaceholderView(
          icon: Icons.bar_chart_rounded,
          title: 'Financial Reports & GST',
          subtitle: 'Balance Sheet, Profit & Loss, Trial Balance, and GSTR summaries.',
        ),

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
                  onOpenCompany: _showOpenCompanyModal,
                  onCreateCompany: _showCreateCompanyModal,
                ),
              ),
              const SizedBox(width: 20),
              const Expanded(flex: 50, child: DataActionCard()),
            ],
          ),
          const SizedBox(height: 20),
          DataDirectoryBanner(
            currentDirectory: _currentDataDirectory,
            isLoading: _isLoadingDirectory,
            onTap: _showSetDirectoryModal,
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: RecentCompaniesPanel(companies: _recentCompanies)),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFDCE6F5)),
            ),
            child: Icon(icon, color: const Color(0xFF0F62FE), size: 30),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF101B38))),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF637392))),
        ],
      ),
    );
  }
}