import 'package:flutter/material.dart';
import '../../constants/app_shortcuts.dart';
import '../../models/party_master_model.dart';

class VoucherHeaderCard extends StatelessWidget {
  final TextEditingController seriesController;
  final FocusNode seriesFocus;
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 204, 219, 241), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0x04092B60), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Row 1: Series, Date, Voucher Number (widened), Party (placed before taxation)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldWithAction(
                label: 'Series',
                controller: seriesController,
                focusNode: seriesFocus,
                width: 140,
                icon: Icons.tag_rounded,
                onAdd: () => onQuickAdd('Series'),
                onSubmitted: () => dateFocus.requestFocus(),
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
                child: _buildPartyField(), // Party placed before Taxation
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: Sale Type (Taxation), Material Centre, Narration
          Row(
            children: [
              Expanded(
                flex: 4,
                child: _buildSaleTypeField(), // Taxation/Sale Type follows Party
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

  Widget _buildSaleTypeField() {
    return Focus(
      onKeyEvent: (node, event) {
        if (AppShortcuts.isQuickAdd(event)) {
          onQuickAdd('Sale Type');
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: SizedBox(
        height: 36,
        child: RawAutocomplete<String>(
          focusNode: saleTypeFocus,
          textEditingController: saleTypeController,
          optionsBuilder: (TextEditingValue textEditingValue) {
            final query = textEditingValue.text.trim().toLowerCase();
            if (query.isEmpty) return taxationSaleTypes;
            return taxationSaleTypes.where((type) => type.toLowerCase().contains(query));
          },
          onSelected: (String selection) {
            saleTypeController.text = selection;
            matCenterFocus.requestFocus();
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                child: Container(
                  width: 280,
                  constraints: const BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD6E4F5), width: 1.2),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5FB)),
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      final isInterState = option.contains('InterState');
                      return InkWell(
                        onTap: () => onSelected(option),
                        hoverColor: const Color(0xFFF4F8FE),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                isInterState ? Icons.alt_route_rounded : Icons.sync_alt_rounded,
                                size: 15,
                                color: isInterState ? const Color(0xFF7E22CE) : const Color(0xFF0F62FE),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                option,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isInterState ? const Color(0xFF7E22CE) : const Color(0xFF101C38),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return ListenableBuilder(
              listenable: focusNode,
              builder: (context, _) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    onFieldSubmitted();
                    matCenterFocus.requestFocus();
                  },
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101B3A),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Taxation / Sale Type',
                    labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7B9B)),
                    prefixIcon: const Icon(Icons.account_tree_outlined, size: 14, color: Color(0xFF0F62FE)),
                    suffixIcon: focusNode.hasFocus
                        ? Focus(
                            canRequestFocus: false,
                            descendantsAreFocusable: false,
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              child: IconButton(
                                icon: const Icon(Icons.add_circle, size: 18, color: Color(0xFF0F62FE)),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(maxWidth: 24, maxHeight: 24),
                                onPressed: () => onQuickAdd('Sale Type'),
                              ),
                            ),
                          )
                        : const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                    suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 24),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFD),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color.fromARGB(255, 204, 219, 241))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.3)),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPartyField() {
    return Focus(
      onKeyEvent: (node, event) {
        if (AppShortcuts.isQuickAdd(event)) {
          onAddParty();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: SizedBox(
        height: 36,
        child: RawAutocomplete<PartyMasterModel>(
          focusNode: partyFocus,
          textEditingController: partyController,
          displayStringForOption: (option) => option.displayName,
          optionsBuilder: (TextEditingValue textEditingValue) {
            final query = textEditingValue.text.trim().toLowerCase();
            if (query.isEmpty) return availableParties;
            return availableParties.where((p) {
              return p.name.toLowerCase().contains(query) ||
                  p.gstin.toLowerCase().contains(query) ||
                  p.group.toLowerCase().contains(query);
            });
          },
          onSelected: (PartyMasterModel selection) {
            partyController.text = selection.displayName;
            saleTypeFocus.requestFocus();
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                child: Container(
                  width: 420,
                  constraints: const BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD6E4F5), width: 1.2),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5FB)),
                    itemBuilder: (BuildContext context, int index) {
                      final PartyMasterModel option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        hoverColor: const Color(0xFFF4F8FE),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FE),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.business_rounded, size: 15, color: Color(0xFF0F62FE)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option.name,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF101C38)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        if (option.gstin.isNotEmpty) ...[
                                          Text(
                                            option.gstin,
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Text(
                                          option.group,
                                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return ListenableBuilder(
              listenable: focusNode,
              builder: (context, _) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    onFieldSubmitted();
                    saleTypeFocus.requestFocus();
                  },
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101B3A),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Party / Account Ledger',
                    labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7B9B)),
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF0F62FE)),
                    suffixIcon: focusNode.hasFocus
                        ? Focus(
                            canRequestFocus: false,
                            descendantsAreFocusable: false,
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              child: IconButton(
                                icon: const Icon(Icons.add_circle, size: 18, color: Color(0xFF0F62FE)),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(maxWidth: 24, maxHeight: 24),
                                onPressed: onAddParty,
                              ),
                            ),
                          )
                        : null,
                    suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 24),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFD),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color.fromARGB(255, 204, 219, 241))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.3)),
                  ),
                );
              },
            );
          },
        ),
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
        if (AppShortcuts.isQuickAdd(event)) {
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
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF101B3A)),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7B9B)),
                prefixIcon: Icon(icon, size: 14, color: const Color(0xFF0F62FE)),
                suffixIcon: focusNode.hasFocus
                    ? Focus(
                        canRequestFocus: false,
                        descendantsAreFocusable: false,
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          child: IconButton(
                            icon: const Icon(Icons.add_circle, size: 18, color: Color(0xFF0F62FE)),
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
                fillColor: const Color(0xFFF8FAFD),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color.fromARGB(255, 204, 219, 241))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.3)),
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
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF101B3A)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7B9B)),
          prefixIcon: const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF0F62FE)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          filled: true,
          fillColor: const Color(0xFFF8FAFD),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: errorText != null ? const Color(0xFFEE4343) : const Color.fromARGB(255, 204, 219, 241)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: errorText != null ? const Color(0xFFEE4343) : const Color(0xFF0F62FE), width: 1.3),
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
                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFFEE4343)),
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
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF101B3A)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7B9B)),
          prefixIcon: Icon(icon, size: 14, color: const Color(0xFF0F62FE)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          filled: true,
          fillColor: const Color(0xFFF8FAFD),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color.fromARGB(255, 204, 219, 241))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.3)),
        ),
      ),
    );

    return width != null ? SizedBox(width: width, child: field) : field;
  }
}