import 'package:flutter/material.dart';

class SideBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final Map<String, dynamic>? activeCompany;
  final VoidCallback? onSwitchCompany;

  const SideBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.activeCompany,
    this.onSwitchCompany,
  });

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  int? hoveringIndex;

  List<_MenuItem> get _currentMenuItems {
    if (widget.activeCompany != null) {
      return const [
        _MenuItem(icon: Icons.receipt_long_rounded, title: 'Transactions'),
        _MenuItem(icon: Icons.account_balance_wallet_outlined, title: 'Accounts & Ledgers'),
        _MenuItem(icon: Icons.inventory_2_outlined, title: 'Inventory & Stock'),
        _MenuItem(icon: Icons.bar_chart_rounded, title: 'Reports & GST'),
        _MenuItem(icon: Icons.admin_panel_settings_outlined, title: 'Administration'),
      ];
    }
    return const [
      _MenuItem(icon: Icons.home_rounded, title: 'Home'),
      _MenuItem(icon: Icons.apartment_outlined, title: 'Companies'),
      _MenuItem(icon: Icons.layers_outlined, title: 'Data'),
      _MenuItem(icon: Icons.settings_outlined, title: 'Settings'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _currentMenuItems;

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE5ECF5), width: 1.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 20, 24),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2C7BF6), Color(0xFF0F62FE)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Color(0x350F62FE), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dhandas™',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF101C38), letterSpacing: -0.4),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Accounts Made Simple',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF7586A3)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.activeCompany != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: InkWell(
                onTap: widget.onSwitchCompany,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F6FE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD6E4FA)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.swap_horiz_rounded, size: 18, color: Color(0xFF0F62FE)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Switch Workspace',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F62FE)),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF0F62FE)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = widget.selectedIndex == index;
                final isHovered = hoveringIndex == index;

                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => hoveringIndex = index),
                  onExit: (_) => setState(() => hoveringIndex = null),
                  child: GestureDetector(
                    onTap: () => widget.onItemSelected(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutCubic,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(colors: [Color(0xFFE9F2FE), Color(0xFFF3F7FF)])
                            : isHovered
                                ? LinearGradient(colors: [const Color(0xFFF4F8FE).withOpacity(0.9), const Color(0xFFF9FBFF).withOpacity(0.5)])
                                : null,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: const Color(0xFFD2E3FB), width: 1.1) : Border.all(color: Colors.transparent),
                        boxShadow: isSelected ? const [BoxShadow(color: Color(0x0A0F62FE), blurRadius: 8, offset: Offset(0, 3))] : null,
                      ),
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 160),
                            left: 0,
                            top: isSelected ? 11 : 23,
                            bottom: isSelected ? 11 : 23,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: isSelected ? 3.5 : 0,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F62FE),
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  size: 20,
                                  color: isSelected ? const Color(0xFF0F62FE) : isHovered ? const Color(0xFF1E2F50) : const Color(0xFF6B7E9D),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? const Color(0xFF0F62FE) : isHovered ? const Color(0xFF101D38) : const Color(0xFF455573),
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 10, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Version 1.0.0', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF90A1BA))),
                SizedBox(height: 2),
                Text('© 2026 Dhandas. All rights reserved.', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: Color(0xFFA1B0C5))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;

  const _MenuItem({required this.icon, required this.title});
}