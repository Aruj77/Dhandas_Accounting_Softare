import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/item_master_model.dart';
import '../../models/party_master_model.dart';
import '../../repositories/master_repository.dart';
import '../../services/focus_policy_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_action_bottom_sheet.dart';
import '../../widgets/common/app_confirm_dialog.dart';
import '../../widgets/common/dashboard_action_chip.dart';
import '../../widgets/common/interactive_dashboard_card.dart';
import '../../widgets/common/company_dashboard_header.dart';
import '../../widgets/voucher/popup/add_item_dialog.dart';
import '../../widgets/voucher/popup/add_party_dialog.dart';
import '../../widgets/voucher/popup/add_series_dialog.dart';
import '../../widgets/common/app_input_dialog.dart';
import '../../models/company_model.dart';

enum MasterCategory { accounts, inventory, configuration }
enum MasterAction { add, modify }
enum MasterType {
  party,
  accountGroup,
  item,
  materialCenter,
  unit,
  series,
  saleType,
  billSundry,
  taxCategory,
}

class _MasterConfig {
  final String? storageKey;
  final bool isReadOnly;
  final String fallbackBadge;
  const _MasterConfig({this.storageKey, this.isReadOnly = false, this.fallbackBadge = ''});
}

const Map<MasterType, _MasterConfig> _masterConfigs = {
  MasterType.party: _MasterConfig(),
  MasterType.item: _MasterConfig(),
  MasterType.series: _MasterConfig(),
  MasterType.materialCenter: _MasterConfig(storageKey: 'materialCenters', fallbackBadge: 'Active Godown'),
  MasterType.accountGroup: _MasterConfig(storageKey: 'accountGroups', fallbackBadge: 'Account Group'),
  MasterType.billSundry: _MasterConfig(storageKey: 'billSundries', fallbackBadge: 'Sundry Charge'),
  MasterType.unit: _MasterConfig(storageKey: 'units', isReadOnly: true, fallbackBadge: 'Standard UOM'),
  MasterType.saleType: _MasterConfig(storageKey: 'saleTypes', isReadOnly: true, fallbackBadge: 'GST Type'),
  MasterType.taxCategory: _MasterConfig(storageKey: 'taxCategories', isReadOnly: true, fallbackBadge: 'GST Slab'),
};

class _MasterItem {
  final MasterType type;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final String shortcut;

  const _MasterItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    this.shortcut = '',
  });

  bool get isReadOnly => _masterConfigs[type]?.isReadOnly ?? false;
}

class MastersDashboardScreen extends StatefulWidget {
  final CompanyModel company;
  final VoidCallback? onMoveToSidebar;
  final void Function(MasterType type, MasterAction action)? onMasterAction;
  final VoidCallback? onMastersChanged;

  const MastersDashboardScreen({
    super.key,
    required this.company,
    this.onMoveToSidebar,
    this.onMasterAction,
    this.onMastersChanged,
  });

  @override
  State<MastersDashboardScreen> createState() => MastersDashboardScreenState();
}

class MastersDashboardScreenState extends State<MastersDashboardScreen> {
  static const List<_MasterItem> _items = [
    _MasterItem(
      type: MasterType.party,
      title: 'Party & Account Ledgers',
      subtitle: 'Customers, suppliers & banks',
      description: 'Sundry Debtors, Creditors, GSTIN, opening balances and credit terms',
      icon: Icons.people_alt_rounded,
      color: AppColors.primaryAccent,
      shortcut: 'Alt+P',
    ),
    _MasterItem(
      type: MasterType.accountGroup,
      title: 'Account Groups',
      subtitle: 'Ledger chart classifications with Major Heads',
      description: 'Primary, Capital, Direct & Indirect expense/income ledger hierarchies',
      icon: Icons.account_tree_rounded,
      color: AppColors.primary,
    ),
    _MasterItem(
      type: MasterType.item,
      title: 'Item Master',
      subtitle: 'Products, stock & services',
      description: 'Inventory items, HSN/SAC codes, default prices, MRP, and GST rates',
      icon: Icons.inventory_2_rounded,
      color: AppColors.purple,
      shortcut: 'Alt+I',
    ),
    _MasterItem(
      type: MasterType.materialCenter,
      title: 'Material Centre',
      subtitle: 'Godowns & warehouses',
      description: 'Physical locations, branch stores, and multi-location inventory centers',
      icon: Icons.warehouse_rounded,
      color: AppColors.warning,
      shortcut: 'Alt+M',
    ),
    _MasterItem(
      type: MasterType.unit,
      title: 'Units of Measure (UOM)',
      subtitle: 'Pcs, Kgs, Litres, Boxes',
      description: 'Standard measurement units and packaging conversion factors',
      icon: Icons.straighten_rounded,
      color: AppColors.success,
    ),
    _MasterItem(
      type: MasterType.series,
      title: 'Voucher Series',
      subtitle: 'Voucher numbering rules',
      description: 'Prefixes, suffixes, auto-number sequences, and series settings',
      icon: Icons.confirmation_number_rounded,
      color: AppColors.error,
      shortcut: 'Alt+S',
    ),
    _MasterItem(
      type: MasterType.saleType,
      title: 'Taxation / Sale Types',
      subtitle: 'Local, Interstate & Exempt',
      description: 'Itemwise, Multirate, RCM, and tax classification transaction types',
      icon: Icons.receipt_long_rounded,
      color: AppColors.primaryDark,
      shortcut: 'Alt+T',
    ),
    _MasterItem(
      type: MasterType.billSundry,
      title: 'Bill Sundry',
      subtitle: 'Charges, discounts & round off',
      description: 'Freight, packaging, cash discounts, insurance, and surcharge rules',
      icon: Icons.percent_rounded,
      color: AppColors.primary,
      shortcut: 'Alt+B',
    ),
    _MasterItem(
      type: MasterType.taxCategory,
      title: 'Tax Categories',
      subtitle: 'GST slabs (0%, 5%, 12%, 18%, 28%)',
      description: 'Schedule rates, compensation cess, and statutory tax slabs',
      icon: Icons.gavel_rounded,
      color: AppColors.textSecondary,
    ),
  ];

  static const _sections = [
    (title: 'Accounts & Ledgers', desc: 'Customer accounts, vendors, banks, and chart of accounts', icon: Icons.account_balance_wallet_rounded, color: AppColors.primaryAccent, indices: [0, 1]),
    (title: 'Inventory & Items', desc: 'Stock items, measurement units, and storage godowns', icon: Icons.inventory_2_rounded, color: AppColors.purple, indices: [2, 3, 4]),
    (title: 'Voucher Configuration & Taxes', desc: 'Voucher series numbering, sale types, sundries, and tax rates', icon: Icons.settings_suggest_rounded, color: AppColors.error, indices: [5, 6, 7, 8]),
  ];

  static final List<List<int>> _gridSections = _sections.map((s) => s.indices).toList();

  late final List<FocusNode> _focusNodes = List.generate(_items.length, (_) => FocusNode());

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void focusFirstTile() => _focusNodes.firstOrNull?.requestFocus();

  Future<void> _handleAction(_MasterItem item, MasterAction action) async {
    if (widget.onMasterAction != null) {
      widget.onMasterAction!(item.type, action);
      return;
    }
    final folderPath = widget.company.folderPath;
    if (action == MasterAction.add) {
      await _openAddMasterDialog(item.type, folderPath);
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => MasterModifyDialog(
        company: widget.company.toJson(),
        item: item,
        onAddNew: () => _openAddMasterDialog(item.type, folderPath),
        onDataChanged: () => widget.onMastersChanged?.call(),
      ),
    );
  }

  Future<void> _openAddMasterDialog(MasterType type, String? folderPath) async {
    if (folderPath == null) return;

    switch (type) {
      case MasterType.party:
        await showDialog(
          context: context,
          builder: (_) => AddPartyDialog(
            voucherType: 'Sales Invoice',
            onPartyCreated: (data) async {
              await MasterRepository.upsertParty(
                folderPath: folderPath,
                party: PartyMasterModel.fromJson(data),
              );
              _onMasterAdded('Party "${data['name']}"');
            },
          ),
        );
        break;

      case MasterType.item:
        await showDialog(
          context: context,
          builder: (_) => AddItemDialog(
            company: widget.company.toJson(),
            folderPath: folderPath,
            onItemCreated: (data) async {
              await MasterRepository.upsertItem(
                folderPath: folderPath,
                item: ItemMasterModel.fromJson(data),
              );
              _onMasterAdded('Item "${data['name']}"');
            },
          ),
        );
        break;

      case MasterType.series:
        await showDialog(
          context: context,
          builder: (_) => AddSeriesDialog(
            onSeriesCreated: (data) async {
              final name = data['name']?.toString() ?? 'Main';
              await MasterRepository.upsertSeries(
                folderPath: folderPath,
                seriesName: name,
                seriesSettings: data,
              );
              _onMasterAdded('Series "$name"');
            },
          ),
        );
        break;

      case MasterType.accountGroup:
        await _openAddAccountGroupDialog(folderPath);
        break;

      default:
        final key = _masterConfigs[type]?.storageKey;
        if (key != null) {
          await _addSimpleStringMaster(key, _items.firstWhere((i) => i.type == type).title, folderPath);
        } else {
          _showToast('Standard statutory master cannot be added manually.');
        }
    }
  }

  Future<void> _openAddAccountGroupDialog(String folderPath) async {
    final masters = await MasterRepository.loadMasters(folderPath: folderPath);
    final majorHeadsList = masters.majorHeads;

    final nameCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    String? selectedMajorHead = majorHeadsList.isNotEmpty ? majorHeadsList.first : '';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Add Account Group', style: TextStyle(fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Account Group Name', hintText: 'e.g., Equipment Reserve'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedMajorHead != null && majorHeadsList.contains(selectedMajorHead) ? selectedMajorHead : null,
                  decoration: const InputDecoration(labelText: 'Major Head'),
                  items: majorHeadsList.map((mh) => DropdownMenuItem(value: mh, child: Text(mh, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedMajorHead = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: idCtrl,
                  decoration: const InputDecoration(labelText: 'Account ID (Optional)', hintText: 'e.g., 11500'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      final success = await MasterRepository.upsertAccountGroup(
        folderPath: folderPath,
        group: {
          'name': nameCtrl.text.trim(),
          'majorHead': selectedMajorHead ?? '',
          'id': idCtrl.text.trim(),
        },
      );

      if (success) {
        _onMasterAdded('Account Group "${nameCtrl.text}"');
      } else {
        _showToast('Account Group already exists.');
      }
    }
  }

  Future<void> _addSimpleStringMaster(String key, String title, String? folderPath) async {
    final name = await AppInputDialog.show(
      context: context,
      title: 'Add $title',
      hintText: 'Enter $title name',
    );

    if (name != null && name.isNotEmpty && folderPath != null) {
      final success = await MasterRepository.addSimpleMaster(
        folderPath: folderPath,
        key: key,
        value: name,
      );

      if (success) {
        _onMasterAdded('$title "$name"');
      } else {
        _showToast('$title already exists');
      }
    }
  }

  void _onMasterAdded(String label) {
    widget.onMastersChanged?.call();
    _showToast('$label created');
  }

  void _showToast(String msg) {
    if (!mounted) return;
    NotificationService.show(
      context,
      message: msg,
      type: NotificationType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final companyName = widget.company.companyName;
    final activeFy = widget.company.activeFinancialYear;

    return AutoScreenFocus(
      screen: FocusTargetScreen.mastersDashboard,
      nodeMap: {
        FocusFieldNode.firstField: _focusNodes.first,
      },
      child: Container(
        color: AppColors.background,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth - 64;
            final cols = width > 1050 ? 3 : (width > 680 ? 2 : 1);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CompanyDashboardHeader(
                    companyName: companyName,
                    financialYear: activeFy,
                    subtitle: 'Master Data Management: Add and modify accounts, stock catalog, voucher series, and GST rules.',
                    accentColor: AppColors.purple,
                  ),
                  const SizedBox(height: 30),
                  for (final sec in _sections) ...[
                    _buildCategorySection(sec.title, sec.desc, sec.icon, sec.color, sec.indices, cols),
                    const SizedBox(height: 22),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategorySection(String title, String desc, IconData icon, Color color, List<int> indices, int cols) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 20, offset: Offset(0, 7))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: color.withValues(alpha: .09), borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Text(desc, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: indices.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              mainAxisExtent: 220,
            ),
            itemBuilder: (_, i) {
              final idx = indices[i];
              final item = _items[idx];
              return InteractiveDashboardCard(
                index: idx,
                cols: cols,
                focusNode: _focusNodes[idx],
                allFocusNodes: _focusNodes,
                sections: _gridSections,
                title: item.title,
                subtitle: item.subtitle,
                description: item.description,
                icon: item.icon,
                color: item.color,
                shortcut: item.shortcut,
                onPrimaryAction: () => _showMasterActions(item),
                actionChips: [
                  if (!item.isReadOnly)
                    DashboardActionChip(
                      label: 'Add',
                      icon: Icons.add_rounded,
                      color: AppColors.success,
                      height: 32,
                      onTap: () => _handleAction(item, MasterAction.add),
                    ),
                  DashboardActionChip(
                    label: item.isReadOnly ? 'View List' : 'Modify',
                    icon: item.isReadOnly ? Icons.visibility_outlined : Icons.edit_note_rounded,
                    color: AppColors.primaryAccent,
                    height: 32,
                    onTap: () => _handleAction(item, MasterAction.modify),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showMasterActions(_MasterItem item) {
    if (item.isReadOnly) {
      _handleAction(item, MasterAction.modify);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AppActionBottomSheet(
        title: item.title,
        subtitle: item.subtitle,
        actions: [
          AppActionItem(
            title: 'Add New',
            desc: 'Create and configure a new master record',
            icon: Icons.add_circle_outline_rounded,
            color: AppColors.success,
            onTap: () {
              Navigator.pop(ctx);
              _handleAction(item, MasterAction.add);
            },
          ),
          AppActionItem(
            title: 'Modify',
            desc: 'View, edit, or delete existing records',
            icon: Icons.edit_note_rounded,
            color: AppColors.primaryAccent,
            onTap: () {
              Navigator.pop(ctx);
              _handleAction(item, MasterAction.modify);
            },
          ),
        ],
      ),
    );
  }
}

class MasterModifyDialog extends StatefulWidget {
  final Map<String, dynamic> company;
  final _MasterItem item;
  final VoidCallback onAddNew;
  final VoidCallback? onDataChanged;

  const MasterModifyDialog({
    super.key,
    required this.company,
    required this.item,
    required this.onAddNew,
    this.onDataChanged,
  });

  @override
  State<MasterModifyDialog> createState() => _MasterModifyDialogState();
}

class _MasterModifyDialogState extends State<MasterModifyDialog> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _loading = true;
  List<Map<String, dynamic>> _allRecords = [];
  List<Map<String, dynamic>> _filteredRecords = [];

  String? get _folderPath => widget.company['folderPath']?.toString();
  bool get _isReadOnly => widget.item.isReadOnly;

  @override
  void initState() {
    super.initState();
    _loadMastersData();
    _searchController.addListener(_filterRecords);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMastersData() async {
    final path = _folderPath;
    if (path == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final masters = await MasterRepository.loadMasters(folderPath: path);
    final List<Map<String, dynamic>> records = [];

    switch (widget.item.type) {
      case MasterType.party:
        for (final p in [...masters.debtors, ...masters.creditors]) {
          records.add({
            'title': p.name,
            'badge': p.group.isNotEmpty ? p.group : 'Sundry Debtors',
            'detail': 'GSTIN: ${p.gstin.isEmpty ? "Unregistered" : p.gstin}',
            'raw': p.toJson(),
          });
        }
        break;

      case MasterType.item:
        for (final i in masters.items) {
          records.add({
            'title': i.name,
            'badge': '${i.taxRate}% GST',
            'detail': 'HSN: ${i.hsn.isEmpty ? "-" : i.hsn} | Unit: ${i.unit} | Sales Price: ₹${i.salesPrice}',
            'raw': i.toJson(),
          });
        }
        break;

      case MasterType.series:
        for (final sName in masters.series) {
          final cfg = Map<String, dynamic>.from(masters.seriesSettings[sName] ?? {'name': sName});
          records.add({
            'title': sName,
            'badge': cfg['prefix']?.toString().isNotEmpty == true ? 'Prefix: ${cfg['prefix']}' : 'Standard',
            'detail': 'Numbering: ${cfg['numberingType'] ?? "Automatic"}',
            'raw': cfg,
          });
        }
        break;

      case MasterType.accountGroup:
        for (final g in masters.accountGroups) {
          final name = g['name']?.toString() ?? '';
          final majorHead = g['majorHead']?.toString() ?? '';
          final id = g['id']?.toString() ?? '';
          records.add({
            'title': name,
            'badge': majorHead,
            'detail': 'Account ID: ${id.isNotEmpty ? id : "-"}',
            'raw': g,
          });
        }
        break;

      default:
        final key = _masterConfigs[widget.item.type]?.storageKey;
        if (key != null) {
          final list = masters.getSimpleList(key);
          for (final name in list) {
            records.add({
              'title': name,
              'badge': _masterConfigs[widget.item.type]!.fallbackBadge,
              'detail': '${widget.item.title} master entity',
              'raw': {'name': name},
            });
          }
        }
    }

    if (mounted) {
      setState(() {
        _allRecords = records;
        _filteredRecords = records;
        _loading = false;
      });
    }
  }

  void _filterRecords() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredRecords = q.isEmpty
          ? _allRecords
          : _allRecords.where((r) {
              return (r['title'] ?? '').toString().toLowerCase().contains(q) ||
                  (r['badge'] ?? '').toString().toLowerCase().contains(q) ||
                  (r['detail'] ?? '').toString().toLowerCase().contains(q);
            }).toList();
    });
  }

  Future<void> _editRecord(Map<String, dynamic> record) async {
    if (_isReadOnly || _folderPath == null) return;
    final title = record['title']?.toString().trim() ?? '';
    final raw = Map<String, dynamic>.from(record['raw'] as Map? ?? {});

    switch (widget.item.type) {
      case MasterType.party:
        await showDialog(
          context: context,
          builder: (_) => AddPartyDialog(
            voucherType: 'Sales Invoice',
            isEdit: true,
            initialParty: PartyMasterModel.fromJson(raw),
            onPartyCreated: (data) async {
              await MasterRepository.upsertParty(
                folderPath: _folderPath!,
                party: PartyMasterModel.fromJson(data),
                oldName: title,
              );
              _onMutationSuccess('Updated "${data['name']}"');
            },
          ),
        );
        break;

      case MasterType.item:
        await showDialog(
          context: context,
          builder: (_) => AddItemDialog(
            company: widget.company,
            folderPath: _folderPath,
            isEdit: true,
            initialItem: ItemMasterModel.fromJson(raw).copyWith(
              name: raw['name']?.toString().isNotEmpty == true ? raw['name'] : title,
            ),
            onItemCreated: (data) async {
              await MasterRepository.upsertItem(
                folderPath: _folderPath!,
                item: ItemMasterModel.fromJson(data),
                oldName: title,
              );
              _onMutationSuccess('Updated "${data['name']}"');
            },
          ),
        );
        break;

      case MasterType.series:
        await showDialog(
          context: context,
          builder: (_) => AddSeriesDialog(
            isEdit: true,
            initialSeries: raw.isNotEmpty ? raw : {'name': title, 'numberingType': 'Automatic'},
            onSeriesCreated: (data) async {
              final newName = data['name']?.toString() ?? 'Main';
              await MasterRepository.upsertSeries(
                folderPath: _folderPath!,
                seriesName: newName,
                seriesSettings: data,
                oldName: title,
              );
              _onMutationSuccess('Updated series "$newName"');
            },
          ),
        );
        break;

      case MasterType.accountGroup:
        await _editAccountGroup(title, raw);
        break;

      default:
        final key = _masterConfigs[widget.item.type]?.storageKey;
        if (key != null) await _editSimpleStringMaster(title, key);
    }
  }

  Future<void> _editAccountGroup(String oldTitle, Map<String, dynamic> initialData) async {
    final masters = await MasterRepository.loadMasters(folderPath: _folderPath!);
    final majorHeadsList = masters.majorHeads;

    final nameCtrl = TextEditingController(text: initialData['name'] ?? oldTitle);
    final idCtrl = TextEditingController(text: initialData['id'] ?? '');
    String? selectedMajorHead = initialData['majorHead']?.toString();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Edit Account Group', style: TextStyle(fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Account Group Name'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedMajorHead != null && majorHeadsList.contains(selectedMajorHead) ? selectedMajorHead : null,
                  decoration: const InputDecoration(labelText: 'Major Head'),
                  items: majorHeadsList.map((mh) => DropdownMenuItem(value: mh, child: Text(mh, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedMajorHead = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: idCtrl,
                  decoration: const InputDecoration(labelText: 'Account ID (Optional)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true && _folderPath != null) {
      await MasterRepository.upsertAccountGroup(
        folderPath: _folderPath!,
        group: {
          'name': nameCtrl.text.trim(),
          'majorHead': selectedMajorHead ?? '',
          'id': idCtrl.text.trim(),
        },
        oldName: oldTitle,
      );
      _onMutationSuccess('Updated Account Group "${nameCtrl.text}"');
    }
  }

  Future<void> _editSimpleStringMaster(String oldVal, String key) async {
    final updated = await AppInputDialog.show(
      context: context,
      title: 'Edit ${widget.item.title}',
      labelText: 'Name',
      initialValue: oldVal,
    );
    if (updated == null || updated.isEmpty || updated == oldVal || _folderPath == null) return;

    final success = await MasterRepository.updateSimpleMaster(
      folderPath: _folderPath!,
      key: key,
      oldValue: oldVal,
      newValue: updated,
    );
    if (success) {
      _onMutationSuccess('Updated "$updated"');
    }
  }

  Future<void> _deleteRecord(Map<String, dynamic> record) async {
    if (_isReadOnly || _folderPath == null) return;
    final title = record['title']?.toString() ?? '';

    if (widget.item.type == MasterType.series && title.toLowerCase() == 'main') {
      _showToast('Cannot delete default "Main" series');
      return;
    }

    final confirm = await AppConfirmDialog.show(
      context: context,
      title: 'Confirm Delete',
      message: 'Are you sure you want to delete "$title"? This action cannot be undone.',
      confirmLabel: 'Delete',
      type: ConfirmDialogType.danger,
    );

    if (!confirm) return;

    switch (widget.item.type) {
      case MasterType.party:
        await MasterRepository.deleteParty(folderPath: _folderPath!, partyName: title);
        break;
      case MasterType.item:
        await MasterRepository.deleteItem(folderPath: _folderPath!, itemName: title);
        break;
      case MasterType.series:
        await MasterRepository.deleteSeries(folderPath: _folderPath!, seriesName: title);
        break;
      case MasterType.accountGroup:
        await MasterRepository.deleteAccountGroup(folderPath: _folderPath!, groupName: title);
        break;
      default:
        final key = _masterConfigs[widget.item.type]?.storageKey;
        if (key != null) {
          await MasterRepository.deleteSimpleMaster(folderPath: _folderPath!, key: key, value: title);
        }
    }

    _onMutationSuccess('Deleted "$title"');
  }

  void _onMutationSuccess(String msg) {
    widget.onDataChanged?.call();
    _showToast(msg);
    _loadMastersData();
  }

  void _showToast(String msg) {
    if (!mounted) return;
    NotificationService.show(
      context,
      message: msg,
      type: NotificationType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 760,
        height: 580,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 30, offset: Offset(0, 10))],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: widget.item.color.withValues(alpha: .10), borderRadius: BorderRadius.circular(12)),
                    child: Icon(widget.item.icon, color: widget.item.color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _isReadOnly ? widget.item.title : 'Modify ${widget.item.title}',
                              style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(color: widget.item.color.withValues(alpha: .1), borderRadius: BorderRadius.circular(6)),
                              child: Text('${_allRecords.length} records', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: widget.item.color)),
                            ),
                          ],
                        ),
                        Text(_isReadOnly ? 'Statutory system catalog' : 'Edit or delete registered records', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  if (!_isReadOnly)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onAddNew();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.surface),
                      label: const Text('New Entry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.surface)),
                    ),
                  IconButton(icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        autofocus: true,
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        decoration: const InputDecoration(hintText: 'Search records...', hintStyle: TextStyle(color: AppColors.textMuted), border: InputBorder.none, isDense: true),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(onTap: _searchController.clear, child: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _filteredRecords.isEmpty
                      ? Center(child: Text(_searchController.text.isEmpty ? 'No records found' : 'No matching results', style: const TextStyle(color: AppColors.textSecondary)))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                          itemCount: _filteredRecords.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.background),
                          itemBuilder: (_, i) {
                            final r = _filteredRecords[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 13,
                                    backgroundColor: widget.item.color.withValues(alpha: .1),
                                    child: Text('${i + 1}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: widget.item.color)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(r['title'] ?? '', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(4)),
                                              child: Text(r['badge'] ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                                            ),
                                          ],
                                        ),
                                        Text(r['detail'] ?? '', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  if (!_isReadOnly) ...[
                                    IconButton(icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primaryAccent), onPressed: () => _editRecord(r)),
                                    IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error), onPressed: () => _deleteRecord(r)),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}