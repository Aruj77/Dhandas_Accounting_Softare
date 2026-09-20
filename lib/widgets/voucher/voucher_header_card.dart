import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/keyboard_shortcut_service.dart';
import '../../models/party_master_model.dart';
import '../common/app_autocomplete_field.dart';

class VoucherHeaderCard extends StatelessWidget {
  final TextEditingController seriesController;
  final FocusNode seriesFocus;
  final List<String> availableSeries;
  final TextEditingController dateController;
  final FocusNode dateFocus;
  final String? dateError;
  final TextEditingController vchNoController;
  final FocusNode vchNoFocus;
  final TextEditingController partyController;
  final FocusNode partyFocus;
  final List<PartyMasterModel> availableParties;
  final TextEditingController saleTypeController;
  final FocusNode saleTypeFocus;
  final TextEditingController matCenterController;
  final FocusNode matCenterFocus;
  final TextEditingController narrationController;
  final FocusNode narrationFocus;
  final VoidCallback onValidateDate;
  final void Function(String masterType) onQuickAdd;
  final VoidCallback onAddParty;
  final VoidCallback onNarrationSubmitted;

  const VoucherHeaderCard({
    super.key,
    required this.seriesController,
    required this.seriesFocus,
    required this.availableSeries,
    required this.dateController,
    required this.dateFocus,
    required this.dateError,
    required this.vchNoController,
    required this.vchNoFocus,
    required this.partyController,
    required this.partyFocus,
    required this.availableParties,
    required this.saleTypeController,
    required this.saleTypeFocus,
    required this.matCenterController,
    required this.matCenterFocus,
    required this.narrationController,
    required this.narrationFocus,
    required this.onValidateDate,
    required this.onQuickAdd,
    required this.onAddParty,
    required this.onNarrationSubmitted,
  });

  static const List<String> taxationSaleTypes = [
    'Local Itemwise',
    'InterState Itemwise',
    'Local Multirate',
    'InterState Multirate',
    'Local Exempt',
    'InterState Exempt',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: const [
          BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Row 1: Series, Date, Voucher Number, Party
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140,
                child: AppAutocompleteField<String>(
                  controller: seriesController,
                  focusNode: seriesFocus,
                  items: availableSeries,
                  label: 'Series',
                  prefixIcon: Icons.tag_rounded,
                  dropdownWidth: 180,
                  labelExtractor: (s) => s,
                  onQuickAdd: () => onQuickAdd('Series'),
                  onSelected: (_) => dateFocus.requestFocus(),
                  optionItemBuilder: (context, option) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.tag_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          option,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _buildDateInput(
                label: 'Voucher Date',
                controller: dateController,
                focusNode: dateFocus,
                errorText: dateError,
                width: 135,
                onSubmitted: () {
                  onValidateDate();
                  vchNoFocus.requestFocus();
                },
              ),
              const SizedBox(width: 10),
              _buildPlainField(
                label: 'Voucher Number',
                controller: vchNoController,
                focusNode: vchNoFocus,
                width: 180,
                icon: Icons.confirmation_number_outlined,
                onSubmitted: () => partyFocus.requestFocus(),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: AppAutocompleteField<PartyMasterModel>(
                  controller: partyController,
                  focusNode: partyFocus,
                  items: availableParties,
                  label: 'Party / Account Ledger',
                  prefixIcon: Icons.person_outline_rounded,
                  dropdownWidth: 420,
                  showDropdownArrow: false,
                  labelExtractor: (p) => p.name,
                  onQuickAdd: onAddParty,
                  onSelected: (_) => saleTypeFocus.requestFocus(),
                  optionItemBuilder: (context, option) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.business_rounded, size: 15, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (option.gstin.isNotEmpty) ...[
                                    Text(
                                      option.gstin,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.successDark,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    option.group,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: Sale Type (Taxation), Material Centre, Narration
          Row(
            children: [
              Expanded(
                flex: 4,
                child: AppAutocompleteField<String>(
                  controller: saleTypeController,
                  focusNode: saleTypeFocus,
                  items: taxationSaleTypes,
                  label: 'Taxation / Sale Type',
                  prefixIcon: Icons.account_tree_outlined,
                  dropdownWidth: 280,
                  labelExtractor: (type) => type,
                  onQuickAdd: () => onQuickAdd('Sale Type'),
                  onSelected: (_) => matCenterFocus.requestFocus(),
                  optionItemBuilder: (context, option) {
                    final isInterState = option.contains('InterState');
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            isInterState ? Icons.alt_route_rounded : Icons.sync_alt_rounded,
                            size: 15,
                            color: isInterState ? AppColors.purple : AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            option,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isInterState ? AppColors.purple : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: _buildFieldWithAction(
                  label: 'Material Centre',
                  controller: matCenterController,
                  focusNode: matCenterFocus,
                  icon: Icons.storefront_outlined,
                  onAdd: () => onQuickAdd('Material Centre'),
                  onSubmitted: () => narrationFocus.requestFocus(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: _buildPlainField(
                  label: 'Narration / Remarks',
                  controller: narrationController,
                  focusNode: narrationFocus,
                  icon: Icons.notes_rounded,
                  onSubmitted: onNarrationSubmitted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldWithAction({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required VoidCallback onAdd,
    VoidCallback? onSubmitted,
    double? width,
  }) {
    return Focus(
      onKeyEvent: (node, event) {
        if (KeyboardShortcutService.isQuickAdd(event)) {
          onAdd();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: ListenableBuilder(
        listenable: focusNode,
        builder: (context, _) {
          final field = SizedBox(
            height: 36,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => onSubmitted?.call(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                prefixIcon: Icon(icon, size: 14, color: AppColors.primary),
                suffixIcon: focusNode.hasFocus
                    ? Focus(
                        canRequestFocus: false,
                        descendantsAreFocusable: false,
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          child: IconButton(
                            icon: const Icon(Icons.add_circle, size: 18, color: AppColors.primary),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(maxWidth: 24, maxHeight: 24),
                            onPressed: onAdd,
                          ),
                        ),
                      )
                    : null,
                suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 24),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true,
                fillColor: AppColors.cardBg,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.3)),
              ),
            ),
          );

          return width != null ? SizedBox(width: width, child: field) : field;
        },
      ),
    );
  }

  Widget _buildDateInput({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String? errorText,
    required VoidCallback onSubmitted,
    double? width,
  }) {
    final field = SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => onSubmitted(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          filled: true,
          fillColor: AppColors.cardBg,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: errorText != null ? AppColors.error : AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: errorText != null ? AppColors.error : AppColors.primary, width: 1.3),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (width != null) SizedBox(width: width, child: field) else field,
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 2),
            child: SizedBox(
              width: width ?? 145,
              child: Text(
                errorText,
                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.error),
                maxLines: 1,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlainField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    VoidCallback? onSubmitted,
    double? width,
  }) {
    final field = SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => onSubmitted?.call(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          prefixIcon: Icon(icon, size: 14, color: AppColors.primary),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          filled: true,
          fillColor: AppColors.cardBg,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.3)),
        ),
      ),
    );

    return width != null ? SizedBox(width: width, child: field) : field;
  }
}