import 'package:flutter/material.dart';

class VoucherHeaderCard extends StatelessWidget {
  final TextEditingController seriesController;
  final FocusNode seriesFocus;
  final TextEditingController dateController;
  final FocusNode dateFocus;
  final String? dateError;
  final TextEditingController vchNoController;
  final FocusNode vchNoFocus;
  final TextEditingController saleTypeController;
  final FocusNode saleTypeFocus;
  final TextEditingController partyController;
  final FocusNode partyFocus;
  final TextEditingController matCenterController;
  final FocusNode matCenterFocus;
  final TextEditingController narrationController;
  final FocusNode narrationFocus;
  final VoidCallback onValidateDate;
  final void Function(String masterType) onQuickAdd;
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
    required this.saleTypeController,
    required this.saleTypeFocus,
    required this.partyController,
    required this.partyFocus,
    required this.matCenterController,
    required this.matCenterFocus,
    required this.narrationController,
    required this.narrationFocus,
    required this.onValidateDate,
    required this.onQuickAdd,
    required this.onNarrationSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF5), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0x04092B60), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldWithFocus(
                label: 'Series',
                controller: seriesController,
                focusNode: seriesFocus,
                width: 110,
                icon: Icons.tag_rounded,
                masterType: 'Series',
                onSubmitted: () => dateFocus.requestFocus(),
              ),
              const SizedBox(width: 10),
              _buildDateInput(
                label: 'Voucher Date',
                controller: dateController,
                focusNode: dateFocus,
                errorText: dateError,
                width: 145,
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
                width: 145,
                icon: Icons.confirmation_number_outlined,
                onSubmitted: () => saleTypeFocus.requestFocus(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFieldWithFocus(
                  label: 'Taxation / Sale Type',
                  controller: saleTypeController,
                  focusNode: saleTypeFocus,
                  icon: Icons.account_tree_outlined,
                  masterType: 'Sale Type',
                  onSubmitted: () => partyFocus.requestFocus(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: _buildFieldWithFocus(
                  label: 'Party / Account Ledger (or GSTIN)',
                  controller: partyController,
                  focusNode: partyFocus,
                  icon: Icons.person_outline_rounded,
                  masterType: 'Account Ledger',
                  onSubmitted: () => matCenterFocus.requestFocus(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: _buildFieldWithFocus(
                  label: 'Material Centre',
                  controller: matCenterController,
                  focusNode: matCenterFocus,
                  icon: Icons.storefront_outlined,
                  masterType: 'Material Centre',
                  onSubmitted: () => narrationFocus.requestFocus(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          filled: true,
          fillColor: const Color(0xFFF8FAFD),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: errorText != null ? const Color(0xFFEE4343) : const Color(0xFFE2EAF5)),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          filled: true,
          fillColor: const Color(0xFFF8FAFD),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2EAF5))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.3)),
        ),
      ),
    );

    return width != null ? SizedBox(width: width, child: field) : field;
  }

  Widget _buildFieldWithFocus({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required String masterType,
    VoidCallback? onSubmitted,
    double? width,
  }) {
    Widget buildField() {
      return ListenableBuilder(
        listenable: focusNode,
        builder: (context, _) {
          final isFocused = focusNode.hasFocus;
          return SizedBox(
            height: 36,
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => onSubmitted?.call(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF101B3A)),
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7B9B)),
                    prefixIcon: Icon(icon, size: 14, color: const Color(0xFF0F62FE)),
                    contentPadding: EdgeInsets.only(left: 8, right: isFocused ? 26 : 8, top: 0, bottom: 0),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFD),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2EAF5))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.3)),
                  ),
                ),
                if (isFocused)
                  Positioned(
                    right: 5,
                    bottom: 5,
                    child: InkWell(
                      onTap: () => onQuickAdd(masterType),
                      borderRadius: BorderRadius.circular(3),
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(color: const Color(0xFF0F62FE), borderRadius: BorderRadius.circular(3)),
                        child: const Icon(Icons.add, size: 10, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }

    return width != null ? SizedBox(width: width, child: buildField()) : buildField();
  }
}