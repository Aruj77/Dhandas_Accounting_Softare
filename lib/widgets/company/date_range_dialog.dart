import 'package:flutter/material.dart';

class DateRangeDialog extends StatefulWidget {
  final String financialYear;
  final String voucherType;

  const DateRangeDialog({
    super.key,
    required this.financialYear,
    required this.voucherType,
  });

  @override
  State<DateRangeDialog> createState() => _DateRangeDialogState();
}

class _DateRangeDialogState extends State<DateRangeDialog> {
  late final TextEditingController _fromCtrl;
  late final TextEditingController _toCtrl;
  late DateTime _fyStartDate;
  late DateTime _fyEndDate;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _parseFinancialYearBounds(widget.financialYear);
    _fromCtrl = TextEditingController(text: _formatDate(_fyStartDate));
    _toCtrl = TextEditingController(text: _formatDate(_fyEndDate));
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  void _parseFinancialYearBounds(String fyStr) {
    try {
      final parts = fyStr.trim().split(RegExp(r'[-/]'));
      var startY = int.parse(parts[0].trim());
      if (startY < 100) startY += 2000;

      var endY = startY + 1;
      if (parts.length > 1) {
        final parsedEnd = int.tryParse(parts[1].trim());
        if (parsedEnd != null) {
          endY = parsedEnd < 100 ? 2000 + parsedEnd : parsedEnd;
        }
      }

      _fyStartDate = DateTime(startY, 4, 1);
      _fyEndDate = DateTime(endY, 3, 31);
    } catch (_) {
      _fyStartDate = DateTime(2026, 4, 1);
      _fyEndDate = DateTime(2027, 3, 31);
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
  }

  DateTime? _parseDate(String raw) {
    final sanitized = raw.trim().replaceAll('/', '-').replaceAll('.', '-');
    final parts = sanitized.split('-');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    var year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    if (year < 100) year += 2000;
    try {
      final dt = DateTime(year, month, day);
      if (dt.day == day && dt.month == month) return dt;
    } catch (_) {}
    return null;
  }

  void _submit() {
    final from = _parseDate(_fromCtrl.text);
    final to = _parseDate(_toCtrl.text);

    if (from == null || to == null) {
      setState(() => _errorMessage = 'Please enter valid dates (DD-MM-YYYY)');
      return;
    }

    if (from.isAfter(to)) {
      setState(() => _errorMessage = 'From Date cannot be after To Date');
      return;
    }

    Navigator.of(context).pop({
      'from': from,
      'to': to,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 460,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFDCE6F5), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x220A1838),
              blurRadius: 36,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFBFD),
                  border: Border(bottom: BorderSide(color: Color(0xFFE5EDF7))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2C7BF6), Color(0xFF0F62FE)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.date_range_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Date Range',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF101C38),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.voucherType} Register • F.Y. ${widget.financialYear}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF657593)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => Navigator.of(context).pop(),
                      color: const Color(0xFF64748B),
                    ),
                  ],
                ),
              ),

              // DATE INPUTS
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField('Starting Date', _fromCtrl),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateField('Ending Date', _toCtrl),
                        ),
                      ],
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEE4343),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F6FE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD6E4FA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF0F62FE)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pre-filled with F.Y. ${widget.financialYear} period. You can narrow this range to view specific monthly or quarterly registers.',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF274375), height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // FOOTER ACTIONS
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFBFD),
                  border: Border(top: BorderSide(color: Color(0xFFE5EDF7))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F62FE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.table_view_rounded, size: 16),
                      label: const Text('Show List (Enter)', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF101B3A)),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFF0F62FE)),
            filled: true,
            fillColor: const Color(0xFFF8FAFD),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.3),
            ),
          ),
        ),
      ],
    );
  }
}