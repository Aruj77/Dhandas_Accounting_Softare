import 'package:flutter/material.dart';
import '../../services/storage_service.dart';

class AdministrationScreen extends StatefulWidget {
  final Map<String, dynamic> company;
  final ValueChanged<Map<String, dynamic>> onCompanyUpdated;

  const AdministrationScreen({
    super.key,
    required this.company,
    required this.onCompanyUpdated,
  });

  @override
  State<AdministrationScreen> createState() => _AdministrationScreenState();
}

class _AdministrationScreenState extends State<AdministrationScreen> {
  late String _activeFy;
  late List<String> _allFys;

  @override
  void initState() {
    super.initState();
    _activeFy = (widget.company['activeFinancialYear'] ?? '2026-27').toString();
    _allFys = List<String>.from(widget.company['financialYears'] ?? ['2024-25', '2025-26', '2026-27']);
  }

  Future<void> _changeFy(String newFy) async {
    setState(() => _activeFy = newFy);
    final updated = Map<String, dynamic>.from(widget.company)..['activeFinancialYear'] = newFy;
    await StorageService.updateCompanyLocally(companyData: updated);
    widget.onCompanyUpdated(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched Active Financial Year to F.Y. $newFy'),
          backgroundColor: const Color(0xFF15803D),
        ),
      );
    }
  }

  void _showAddFyDialog() {
    final controller = TextEditingController(text: '2027-28');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Financial Year'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'e.g. 2027-28', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final val = controller.text.trim();
              if (val.isNotEmpty && !_allFys.contains(val)) {
                setState(() => _allFys.add(val));
                final updated = Map<String, dynamic>.from(widget.company)
                  ..['financialYears'] = _allFys
                  ..['activeFinancialYear'] = val;
                await StorageService.updateCompanyLocally(companyData: updated);
                widget.onCompanyUpdated(updated);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Add & Activate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Company Administration',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F1B38)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Manage financial periods, accounting parameters, and data partitions.',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF637392)),
          ),
          const SizedBox(height: 28),

          // FINANCIAL YEAR MANAGEMENT
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE4EDF7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.date_range_rounded, color: Color(0xFF0F62FE)),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Financial Year Selection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF101C38))),
                          Text('Select the current accounting year. All transactions will be isolated to this FY.', style: TextStyle(fontSize: 12, color: Color(0xFF6B7B9A))),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddFyDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add F.Y.'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F62FE), foregroundColor: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _allFys.map((fy) {
                    final isCurrent = _activeFy == fy;
                    return InkWell(
                      onTap: () => _changeFy(fy),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: isCurrent ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFD),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrent ? const Color(0xFF0F62FE) : const Color(0xFFE2EAF5),
                            width: isCurrent ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCurrent ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                              size: 18,
                              color: isCurrent ? const Color(0xFF0F62FE) : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'F.Y. $fy',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                color: isCurrent ? const Color(0xFF0F62FE) : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}