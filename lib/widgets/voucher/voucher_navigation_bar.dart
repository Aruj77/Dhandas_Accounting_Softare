import 'package:flutter/material.dart';
import '../../services/keyboard_shortcut_service.dart';

class VoucherNavigationBar extends StatelessWidget {
  final String voucherType;
  final String financialYear;
  final bool isInterState;
  final Color headerColor;
  final KeyboardShortcutSettings keyboardSettings;
  final VoidCallback onSave;
  final VoidCallback onClose;

  const VoucherNavigationBar({
    super.key,
    required this.voucherType,
    required this.financialYear,
    required this.isInterState,
    required this.headerColor,
    required this.keyboardSettings,
    required this.onSave,
    required this.onClose,
  });

  Widget _buildShortcutBadge(String key, String desc, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isPrimary ? Colors.white : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            key,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isPrimary ? const Color(0xFF0F62FE) : Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            desc,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isPrimary ? const Color(0xFF0F62FE) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: headerColor,
        border: const Border(bottom: BorderSide(color: Color(0xFFE2EAF5), width: 1.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 5),
                Text(
                  'NEW ${voucherType.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              'F.Y. $financialYear',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: headerColor),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: isInterState ? const Color(0xFFFAF5FF) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isInterState ? Icons.alt_route_rounded : Icons.check_circle_outline_rounded,
                  size: 11,
                  color: isInterState ? const Color(0xFF7E22CE) : const Color(0xFF15803D),
                ),
                const SizedBox(width: 3),
                Text(
                  isInterState ? 'Inter-State (IGST)' : 'Intra-State (CGST+SGST)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isInterState ? const Color(0xFF7E22CE) : const Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _buildShortcutBadge(
            KeyboardShortcutService.labelForAction(keyboardSettings, KeyboardShortcutService.saveVoucherAction),
            'Save',
            isPrimary: true,
          ),
          const SizedBox(width: 6),
          _buildShortcutBadge(
            KeyboardShortcutService.labelForAction(keyboardSettings, KeyboardShortcutService.goBackAction),
            'Quit',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}