// lib/pages/company/masters_dashboard_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_colors.dart';
import '../../models/item_master_model.dart';
import '../../models/party_master_model.dart';
import '../../services/focus_policy_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/app_confirm_dialog.dart';
import '../../widgets/voucher/popup/add_item_dialog.dart';
import '../../widgets/voucher/popup/add_party_dialog.dart';
import '../../widgets/voucher/popup/add_series_dialog.dart';

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
  final Map<String, dynamic> company;
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
      subtitle: 'Ledger chart classifications',
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

  late final List<FocusNode> _focusNodes = List.generate(_items.length, (_) => FocusNode());
  int? _focusedIndex;
  int? _hoveredIndex;

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void focusFirstTile() => _focusNodes.firstOrNull?.requestFocus();

  void _handleGridNavigation(int currentIndex, LogicalKeyboardKey key, int cols) {
    int target = currentIndex;
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.numpad6) {
      target = (currentIndex + 1) % _items.length;
    } else if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.numpad4) {
      target = (currentIndex - 1 + _items.length) % _items.length;
    } else if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.numpad8) {
      target = (currentIndex - cols + _items.length) % _items.length;
    } else if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.numpad2) {
      target = (currentIndex + cols) % _items.length;
    }
    _focusNodes[target].requestFocus();
  }

  Future<void> _handleAction(_MasterItem item, MasterAction action) async {
    if (widget.onMasterAction != null) {
      widget.onMasterAction!(item.type, action);
      return;
    }
    final folderPath = widget.company['folderPath']?.toString();
    if (action == MasterAction.add) {
      await _openAddMasterDialog(item.type, folderPath);
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => MasterModifyDialog(
        company: widget.company,
        item: item,
        onAddNew: () => _openAddMasterDialog(item.type, folderPath),
        onDataChanged: () => widget.onMastersChanged?.call(),
      ),
    );
  }

  Future<void> _openAddMasterDialog(MasterType type, String? folderPath) async {
    switch (type) {
      case MasterType.party:
        await showDialog(
          context: context,
          builder: (_) => AddPartyDialog(
            voucherType: 'Sales Invoice',
            onPartyCreated: (data) async {
              if (folderPath != null) {
                await _mutateCompanyMasters(folderPath, (raw) {
                  final key = (data['group'] ?? '').toString().toLowerCase().contains('creditor') ? 'creditors' : 'debtors';
                  (raw[key] ??= <dynamic>[]).add(data);
                });
              }
              _onMasterAdded('Party "${data['name']}"');
            },
          ),
        );
        break;

      case MasterType.item:
        await showDialog(
          context: context,
          builder: (_) => AddItemDialog(
            company: widget.company,
            onItemCreated: (data) {
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
              if (folderPath != null) {
                await _mutateCompanyMasters(folderPath, (raw) {
                  final series = List<String>.from(raw['series'] ?? ['Main']);
                  final name = data['name']?.toString() ?? 'Main';
                  if (!series.contains(name)) series.add(name);
                  raw['series'] = series;
                  (raw['seriesSettings'] ??= <String, dynamic>{})[name] = data;
                });
              }
              _onMasterAdded('Series "${data['name']}"');
            },
          ),
        );
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

  Future<void> _addSimpleStringMaster(String key, String title, String? folderPath) async {
    final controller = TextEditingController();
    final name = await _showInputDialog('Add $title', 'Enter $title name', controller);

    if (name != null && name.isNotEmpty && folderPath != null) {
      final success = await _mutateCompanyMasters(folderPath, (raw) {
        final list = List<String>.from(raw[key] ?? []);
        if (list.any((e) => e.toLowerCase() == name.toLowerCase())) return false;
        list.add(name);
        raw[key] = list;
        return true;
      });

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final companyName = (widget.company['companyName'] ?? 'Workspace').toString();
    final activeFy = (widget.company['activeFinancialYear'] ?? '2026-27').toString();

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
                  _buildHeader(companyName, activeFy),
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

  Widget _buildHeader(String companyName, String financialYear) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 18, offset: Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(width: 5, height: 58, decoration: BoxDecoration(color: AppColors.purple, borderRadius: BorderRadius.circular(10))),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.purpleLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text('FY $financialYear', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.purple)),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  'Master Data Management: Add and modify accounts, stock catalog, voucher series, and GST rules.',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
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
            itemBuilder: (_, i) => _buildMasterCard(indices[i], cols),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterCard(int index, int cols) {
    final item = _items[index];
    final isFocused = _focusedIndex == index;
    final isHovered = _hoveredIndex == index;

    return Focus(
      focusNode: _focusNodes[index],
      onFocusChange: (has) {
        setState(() => _focusedIndex = has ? index : null);
        if (has) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Scrollable.ensureVisible(context, alignment: 0.5, duration: const Duration(milliseconds: 250));
          });
        }
      },
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final k = event.logicalKey;
        if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.space || k == LogicalKeyboardKey.numpadEnter) {
          _showMasterActions(item);
          return KeyEventResult.handled;
        }
        if ({
          LogicalKeyboardKey.arrowUp,
          LogicalKeyboardKey.arrowDown,
          LogicalKeyboardKey.arrowLeft,
          LogicalKeyboardKey.arrowRight,
          LogicalKeyboardKey.numpad2,
          LogicalKeyboardKey.numpad4,
          LogicalKeyboardKey.numpad6,
          LogicalKeyboardKey.numpad8,
        }.contains(k)) {
          _handleGridNavigation(index, k, cols);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          setState(() => _hoveredIndex = index);
          _focusNodes[index].requestFocus();
        },
        onExit: (_) => setState(() => _hoveredIndex = null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, (isHovered || isFocused) ? -3 : 0, 0),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isFocused ? item.color : (isHovered ? item.color.withValues(alpha: .35) : AppColors.border),
              width: isFocused ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered || isFocused ? item.color.withValues(alpha: .10) : AppColors.shadowColor,
                blurRadius: isHovered || isFocused ? 18 : 8,
                offset: Offset(0, isHovered || isFocused ? 8 : 3),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              _focusNodes[index].requestFocus();
              _showMasterActions(item);
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: item.color.withValues(alpha: .10), borderRadius: BorderRadius.circular(14)),
                        child: Icon(item.icon, color: item.color, size: 22),
                      ),
                      const Spacer(),
                      if (item.shortcut.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(6)),
                          child: Text(item.shortcut, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: item.color)),
                  const SizedBox(height: 3),
                  Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, height: 1.35, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                  const Spacer(),
                  Row(
                    children: [
                      if (!item.isReadOnly) ...[
                        _cardActionButton('Add', Icons.add_rounded, AppColors.success, () => _handleAction(item, MasterAction.add)),
                        const SizedBox(width: 8),
                      ],
                      _cardActionButton(
                        item.isReadOnly ? 'View List' : 'Modify',
                        item.isReadOnly ? Icons.visibility_outlined : Icons.edit_note_rounded,
                        AppColors.primaryAccent,
                        () => _handleAction(item, MasterAction.modify),
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

  Widget _cardActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: .08), borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
          ),
        ),
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
      builder: (ctx) => _MasterActionsSheet(
        item: item,
        onSelect: (action) {
          Navigator.pop(ctx);
          _handleAction(item, action);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom Sheet Action Chooser with Reliable Focus on Modify
// ---------------------------------------------------------------------------
class _MasterActionsSheet extends StatefulWidget {
  final _MasterItem item;
  final ValueChanged<MasterAction> onSelect;

  const _MasterActionsSheet({required this.item, required this.onSelect});

  @override
  State<_MasterActionsSheet> createState() => _MasterActionsSheetState();
}

class _MasterActionsSheetState extends State<_MasterActionsSheet> {
  final FocusNode _addNode = FocusNode();
  final FocusNode _modifyNode = FocusNode();
  Animation<double>? _routeAnimation;

  @override
  void initState() {
    super.initState();
    // Safety fallback timer to request focus in case animation callbacks are skipped
    Timer(const Duration(milliseconds: 100), () {
      if (mounted && !_modifyNode.hasFocus) {
        _modifyNode.requestFocus();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Attach listener to bottom sheet modal transition to trigger focus ring on completion
    final animation = ModalRoute.of(context)?.animation;
    if (_routeAnimation != animation) {
      _routeAnimation?.removeStatusListener(_onAnimationStatusChanged);
      _routeAnimation = animation;
      _routeAnimation?.addStatusListener(_onAnimationStatusChanged);
    }
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      _modifyNode.requestFocus();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onAnimationStatusChanged);
    _addNode.dispose();
    _modifyNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(20)),
            ),
            const SizedBox(height: 18),
            Text(
              widget.item.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              widget.item.subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),

            // Action 1: Add New (Primary Action)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildActionTile(
                focusNode: _addNode,
                autofocus: false,
                title: 'Add New',
                desc: 'Create and configure a new master record',
                icon: Icons.add_circle_outline_rounded,
                color: AppColors.success,
                onTap: () => widget.onSelect(MasterAction.add),
                onDown: () => _modifyNode.requestFocus(),
                onUp: () => _modifyNode.requestFocus(),
              ),
            ),

            // Action 2: Modify (Default focused with active ring)
            _buildActionTile(
              focusNode: _modifyNode,
              autofocus: true,
              title: 'Modify',
              desc: 'View, edit, or delete existing records',
              icon: Icons.edit_note_rounded,
              color: AppColors.primaryAccent,
              onTap: () => widget.onSelect(MasterAction.modify),
              onDown: () => _addNode.requestFocus(),
              onUp: () => _addNode.requestFocus(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required FocusNode focusNode,
    required bool autofocus,
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required VoidCallback onDown,
    required VoidCallback onUp,
  }) {
    return Focus(
      focusNode: focusNode,
      autofocus: autofocus,
      onFocusChange: (_) => setState(() {}),
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;

        if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          onTap();
          return KeyEventResult.handled;
        }

        if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
            event.logicalKey == LogicalKeyboardKey.numpad2) {
          onDown();
          return KeyEventResult.handled;
        }

        if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
            event.logicalKey == LogicalKeyboardKey.numpad8) {
          onUp();
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (ctx) {
          final isFocused = Focus.of(ctx).hasFocus;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: BoxDecoration(
              color: isFocused ? color.withValues(alpha: .06) : AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFocused ? color : AppColors.border,
                width: isFocused ? 2.5 : 1.0,
              ),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: .25),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              desc,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isFocused ? color : AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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

    final raw = await StorageService.loadCompanyMasters(folderPath: path);
    final List<Map<String, dynamic>> records = [];

    switch (widget.item.type) {
      case MasterType.party:
        for (final group in ['debtors', 'creditors']) {
          for (final p in (raw[group] as List? ?? [])) {
            final gstin = p['gstin']?.toString();
            records.add({
              'title': p['name'] ?? '',
              'badge': p['group'] ?? (group == 'debtors' ? 'Sundry Debtors' : 'Sundry Creditors'),
              'detail': 'GSTIN: ${gstin == null || gstin.isEmpty ? "Unregistered" : gstin}',
              'raw': p,
            });
          }
        }
        break;

      case MasterType.item:
        for (final i in (raw['items'] as List? ?? [])) {
          records.add({
            'title': i['name'] ?? '',
            'badge': '${i['taxRate'] ?? 18}% GST',
            'detail': 'HSN: ${i['hsn'] ?? "-"} | Unit: ${i['unit'] ?? "PCS"} | Sales Price: ₹${i['salesPrice'] ?? 0.0}',
            'raw': i,
          });
        }
        break;

      case MasterType.series:
        final seriesList = (raw['series'] as List? ?? ['Main']);
        final settings = (raw['seriesSettings'] as Map? ?? {});
        for (final s in seriesList) {
          final sName = s.toString();
          final cfg = Map<String, dynamic>.from(settings[sName] ?? {'name': sName});
          records.add({
            'title': sName,
            'badge': cfg['prefix']?.toString().isNotEmpty == true ? 'Prefix: ${cfg['prefix']}' : 'Standard',
            'detail': 'Numbering: ${cfg['numberingType'] ?? "Automatic"}',
            'raw': cfg,
          });
        }
        break;

      default:
        final key = _masterConfigs[widget.item.type]?.storageKey;
        if (key != null) {
          for (final val in (raw[key] as List? ?? [])) {
            final name = val.toString();
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
    if (_isReadOnly) return;
    final title = record['title']?.toString().trim() ?? '';
    final raw = Map<String, dynamic>.from(record['raw'] as Map? ?? {});

    switch (widget.item.type) {
      case MasterType.party:
        await showDialog(
          context: context,
          builder: (_) => AddPartyDialog(
            voucherType: 'Sales Invoice',
            isEdit: true,
            initialParty: PartyMasterModel(
              name: raw['name']?.toString() ?? title,
              gstin: raw['gstin']?.toString() ?? '',
              group: raw['group']?.toString() ?? record['badge']?.toString() ?? 'Sundry Debtors',
            ),
            onPartyCreated: (data) async {
              await _mutateCompanyMasters(_folderPath!, (masters) {
                _removeParty(masters, title);
                final key = (data['group'] ?? '').toString().toLowerCase().contains('creditor') ? 'creditors' : 'debtors';
                (masters[key] ??= <dynamic>[]).add(data);
              });
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
            isEdit: true,
            initialItem: ItemMasterModel(
              name: raw['name']?.toString() ?? title,
              hsn: raw['hsn']?.toString() ?? '',
              unit: raw['unit']?.toString() ?? 'PCS',
              taxCategory: raw['taxCategory']?.toString() ?? 'GST 18%',
              taxRate: (raw['taxRate'] as num?)?.toDouble() ?? 18.0,
              salesPrice: (raw['salesPrice'] as num?)?.toDouble() ?? 0.0,
              purchasePrice: (raw['purchasePrice'] as num?)?.toDouble() ?? 0.0,
              mrp: (raw['mrp'] as num?)?.toDouble() ?? 0.0,
            ),
            onItemCreated: (data) {
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
              await _mutateCompanyMasters(_folderPath!, (masters) {
                final list = List<String>.from(masters['series'] ?? []);
                final idx = list.indexWhere((s) => s.trim().toLowerCase() == title.toLowerCase());
                final newName = data['name']?.toString() ?? 'Main';
                if (idx != -1) {
                  list[idx] = newName;
                } else if (!list.contains(newName)) {
                  list.add(newName);
                }
                masters['series'] = list;
                final settings = Map<String, dynamic>.from(masters['seriesSettings'] ?? {});
                settings.remove(title);
                settings[newName] = data;
                masters['seriesSettings'] = settings;
              });
              _onMutationSuccess('Updated series "${data['name']}"');
            },
          ),
        );
        break;

      default:
        final key = _masterConfigs[widget.item.type]?.storageKey;
        if (key != null) await _editSimpleStringMaster(title, key);
    }
  }

  Future<void> _editSimpleStringMaster(String oldVal, String key) async {
    final controller = TextEditingController(text: oldVal);
    final updated = await _showInputDialog('Edit ${widget.item.title}', 'Name', controller);
    if (updated == null || updated.isEmpty || updated == oldVal) return;

    await _mutateCompanyMasters(_folderPath!, (masters) {
      final list = List<String>.from(masters[key] ?? []);
      final idx = list.indexWhere((e) => e.toLowerCase() == oldVal.toLowerCase());
      if (idx != -1) {
        list[idx] = updated;
      } else {
        list.add(updated);
      }
      masters[key] = list;
    });
    _onMutationSuccess('Updated "$updated"');
  }

  Future<void> _deleteRecord(Map<String, dynamic> record) async {
    if (_isReadOnly) return;
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

    if (!confirm || _folderPath == null) return;

    await _mutateCompanyMasters(_folderPath!, (masters) {
      switch (widget.item.type) {
        case MasterType.party:
          _removeParty(masters, title);
          break;
        case MasterType.item:
          (masters['items'] as List?)?.removeWhere((i) => (i['name'] ?? '').toString().trim().toLowerCase() == title.toLowerCase());
          break;
        case MasterType.series:
          (masters['series'] as List?)?.removeWhere((s) => s.toString().trim().toLowerCase() == title.toLowerCase());
          (masters['seriesSettings'] as Map?)?.remove(title);
          break;
        default:
          final key = _masterConfigs[widget.item.type]?.storageKey;
          if (key != null) {
            (masters[key] as List?)?.removeWhere((e) => e.toString().trim().toLowerCase() == title.toLowerCase());
          }
      }
    });

    _onMutationSuccess('Deleted "$title"');
  }

  void _removeParty(Map<String, dynamic> masters, String title) {
    final lower = title.toLowerCase();
    (masters['debtors'] as List?)?.removeWhere((p) => (p['name'] ?? '').toString().trim().toLowerCase() == lower);
    (masters['creditors'] as List?)?.removeWhere((p) => (p['name'] ?? '').toString().trim().toLowerCase() == lower);
  }

  void _onMutationSuccess(String msg) {
    widget.onDataChanged?.call();
    _showToast(msg);
    _loadMastersData();
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)), backgroundColor: AppColors.primary),
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

Future<bool> _mutateCompanyMasters(String folderPath, dynamic Function(Map<String, dynamic> raw) mutator) async {
  final raw = await StorageService.loadCompanyMasters(folderPath: folderPath);
  final res = mutator(raw);
  if (res == false) return false;
  await StorageService.saveCompanyMasters(folderPath: folderPath, mastersData: raw);
  return true;
}

Future<String?> _showInputDialog(String title, String hint, TextEditingController controller) {
  return showDialog<String>(
    context: FocusManager.instance.primaryFocus?.context ?? navigatorKey.currentContext!,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      content: TextField(controller: controller, decoration: InputDecoration(hintText: hint), autofocus: true),
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Save', style: TextStyle(color: AppColors.surface)),
        ),
      ],
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();