// lib/widgets/company/company_workspace_footer.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_decoration.dart';
import '../../models/company_model.dart';
import '../../services/loading_service.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_date_utils.dart';

class CompanyWorkspaceFooter extends StatelessWidget {
  /// Accepts either [CompanyModel] or [Map<String, dynamic>]
  final dynamic company;
  final ValueChanged<dynamic>? onCompanyUpdated;

  const CompanyWorkspaceFooter({
    super.key,
    required this.company,
    this.onCompanyUpdated,
  });

  Map<String, dynamic> get _companyMap {
    if (company is Map<String, dynamic>) {
      return company as Map<String, dynamic>;
    }
    if (company is CompanyModel) {
      return (company as CompanyModel).toJson();
    }
    try {
      return (company as dynamic).toJson() as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static int _parseStartYear(String fy) {
    final match = RegExp(r'^(\d{4})').firstMatch(fy.trim());
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 0;
    }
    return 0;
  }

  /// Returns unique financial years sorted in chronological order (oldest to newest)
  List<String> _getAvailableFinancialYears(String activeFy) {
    final raw = _companyMap['financialYears'] as List?;
    final list = raw != null
        ? raw.map((e) => e.toString().trim()).toList()
        : <String>['2024-25', '2025-26', AppDateUtils.defaultFinancialYear];

    if (!list.contains(activeFy)) {
      list.add(activeFy);
    }

    final uniqueSet = list.where((fy) => fy.isNotEmpty).toSet().toList();

    // Sort chronologically by the start year
    uniqueSet.sort((a, b) {
      final startA = _parseStartYear(a);
      final startB = _parseStartYear(b);
      if (startA != startB) {
        return startA.compareTo(startB);
      }
      return a.compareTo(b);
    });

    return uniqueSet;
  }

  void _notifyUpdated(Map<String, dynamic> updatedMap) {
    if (onCompanyUpdated == null) return;
    if (company is CompanyModel) {
      onCompanyUpdated!(CompanyModel.fromJson(updatedMap));
    } else {
      onCompanyUpdated!(updatedMap);
    }
  }

  Future<void> _switchFinancialYear(BuildContext context, String newFy) async {
    final activeFy = (_companyMap['activeFinancialYear'] ?? AppDateUtils.defaultFinancialYear).toString();
    if (newFy == activeFy) return;

    await LoadingService.wrap(() async {
      final updated = Map<String, dynamic>.from(_companyMap)..['activeFinancialYear'] = newFy;
      await StorageService.updateCompanyLocally(companyData: updated);
      _notifyUpdated(updated);

      if (context.mounted) {
        NotificationService.show(
          context,
          message: 'Switched Active Accounting Period to F.Y. $newFy',
          type: NotificationType.success,
        );
      }
    }, message: 'Switching F.Y. to $newFy...');
  }

  Future<void> _showAddFinancialYearDialog(BuildContext context, List<String> existingFys) async {
    // Determine the next suggested FY based on current highest year
    int maxYear = 2026;
    for (final fy in existingFys) {
      final y = _parseStartYear(fy);
      if (y > maxYear) maxYear = y;
    }
    final nextSuggested = '${maxYear + 1}-${((maxYear + 2) % 100).toString().padLeft(2, '0')}';
    final secondSuggested = '${maxYear + 2}-${((maxYear + 3) % 100).toString().padLeft(2, '0')}';

    final controller = TextEditingController(text: nextSuggested);
    String? validationError;

    final newFy = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          void validateAndSubmit() {
            final val = controller.text.trim();
            final regex = RegExp(r'^20\d{2}-\d{2}$');

            if (!regex.hasMatch(val)) {
              setDialogState(() {
                validationError = 'Format must strictly be 20__-__ (e.g. $nextSuggested)';
              });
              return;
            }

            // Verify consecutive mathematical year (e.g., 2027 must be followed by 28)
            final startY = int.tryParse(val.substring(2, 4)) ?? 0;
            final endY = int.tryParse(val.substring(5, 7)) ?? 0;
            if (endY != (startY + 1) % 100) {
              setDialogState(() {
                final correctEnd = ((startY + 1) % 100).toString().padLeft(2, '0');
                validationError = 'Invalid span: Year 20$startY must end in $correctEnd (20$startY-$correctEnd)';
              });
              return;
            }

            Navigator.pop(ctx, val);
          }

          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.date_range_rounded, color: AppColors.primary, size: 22),
                SizedBox(width: 10),
                Text(
                  'Add Financial Year',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ],
            ),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter period in 20__-__ format. All transactions and invoice registers will be partitioned to this period.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 14),

                  // Suggested Next Year Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [nextSuggested, secondSuggested].map((sug) {
                      return ActionChip(
                        label: Text('F.Y. $sug', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        backgroundColor: AppColors.cardBg,
                        side: const BorderSide(color: AppColors.border),
                        onPressed: () {
                          setDialogState(() {
                            controller.text = sug;
                            validationError = null;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                    inputFormatters: [
                      _FinancialYearMaskFormatter(),
                    ],
                    onChanged: (_) {
                      if (validationError != null) {
                        setDialogState(() => validationError = null);
                      }
                    },
                    onSubmitted: (_) => validateAndSubmit(),
                    decoration: AppDecorations.standard(
                      label: 'Financial Year (20__-__) *',
                      hintText: '20__-__',
                      prefixIcon: Icons.calendar_today_rounded,
                    ),
                  ),

                  if (validationError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      validationError!,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: validateAndSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Add & Activate'),
              ),
            ],
          );
        },
      ),
    );

    if (newFy != null && newFy.isNotEmpty) {
      if (existingFys.contains(newFy)) {
        if (context.mounted) {
          _switchFinancialYear(context, newFy);
        }
        return;
      }

      await LoadingService.wrap(() async {
        final updatedList = List<String>.from(existingFys)..add(newFy);
        final updated = Map<String, dynamic>.from(_companyMap)
          ..['financialYears'] = updatedList
          ..['activeFinancialYear'] = newFy;

        await StorageService.updateCompanyLocally(companyData: updated);
        _notifyUpdated(updated);

        if (context.mounted) {
          NotificationService.show(
            context,
            message: 'Added and switched to F.Y. $newFy',
            type: NotificationType.success,
          );
        }
      }, message: 'Creating and Partitioning F.Y. $newFy...');
    }
  }

  @override
  Widget build(BuildContext context) {
    final map = _companyMap;
    final companyName = (map['companyName'] ?? 'Untitled Company').toString();
    final gstin = (map['gstin'] != null && map['gstin'].toString().isNotEmpty)
        ? map['gstin'].toString()
        : 'Unregistered';
    final folderId = (map['companyId'] ?? map['folderName'] ?? 'FIN-0001').toString();
    final activeFy = (map['activeFinancialYear'] ?? AppDateUtils.defaultFinancialYear).toString();
    final availableFys = _getAvailableFinancialYears(activeFy);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.2)),
        boxShadow: [
          BoxShadow(color: AppColors.shadowColor, blurRadius: 10, offset: Offset(0, -3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: AppColors.brandBadgeGradient,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderFocus, width: 1.2),
            ),
            child: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    companyName,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      folderId,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Text('GSTIN: ', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  Text(
                    gstin,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: gstin == 'Unregistered' ? AppColors.textMuted : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(width: 24),

          // Interactive Financial Year Dropdown
          Theme(
            data: Theme.of(context).copyWith(
              hoverColor: AppColors.primaryLight,
            ),
            child: PopupMenuButton<String>(
              tooltip: 'Switch or Add Financial Year',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.border, width: 1.2),
              ),
              color: AppColors.surface,
              elevation: 8,
              offset: const Offset(0, -10),
              onSelected: (value) {
                if (value == '__add_new_fy__') {
                  _showAddFinancialYearDialog(context, availableFys);
                } else {
                  _switchFinancialYear(context, value);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem<String>(
                  enabled: false,
                  height: 32,
                  child: Text(
                    'SELECT FINANCIAL YEAR',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const PopupMenuDivider(height: 1),
                ...availableFys.map((fy) {
                  final isCurrent = fy == activeFy;
                  return PopupMenuItem<String>(
                    value: fy,
                    height: 40,
                    child: Row(
                      children: [
                        Icon(
                          isCurrent ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          size: 16,
                          color: isCurrent ? AppColors.success : AppColors.textMuted,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'F.Y. $fy',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                            color: isCurrent ? AppColors.successDark : AppColors.textPrimary,
                          ),
                        ),
                        if (isCurrent) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.successBorder),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.successDark),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                const PopupMenuDivider(height: 1),
                const PopupMenuItem<String>(
                  value: '__add_new_fy__',
                  height: 42,
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline_rounded, size: 17, color: AppColors.primary),
                      SizedBox(width: 10),
                      Text(
                        'Add New Financial Year...',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.successBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.date_range_rounded, size: 16, color: AppColors.successDark),
                    const SizedBox(width: 6),
                    Text(
                      'F.Y. $activeFy',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.successDark),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.successDark),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 15, color: AppColors.success),
                SizedBox(width: 6),
                Text(
                  'Dhandas Accounting Engine Active',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Enforces the strict 20__-__ format mask without blocking natural backspaces.
class _FinancialYearMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 6) {
      digits = digits.substring(0, 6);
    }

    if (!digits.startsWith('20') && digits.isNotEmpty) {
      if (digits.length <= 2) {
        digits = '20$digits';
      }
    }

    String formatted = digits;
    if (digits.length >= 4) {
      final start = digits.substring(0, 4);
      final rest = digits.substring(4);

      if (rest.isNotEmpty) {
        formatted = '$start-$rest';
      } else if (digits.length == 4) {
        final startYearNum = int.tryParse(digits.substring(2, 4));
        if (startYearNum != null) {
          final nextYear = (startYearNum + 1) % 100;
          formatted = '$start-${nextYear.toString().padLeft(2, '0')}';
        } else {
          formatted = '$start-';
        }
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}