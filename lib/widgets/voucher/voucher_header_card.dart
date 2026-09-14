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
  final TextEditingController partyGstinController;
  final FocusNode partyGstinFocus;
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
    required this.partyGstinController,
    required this.partyGstinFocus,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAF5), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04092B60),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
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
                width: 130,
                icon: Icons.tag_rounded,
                masterType: 'Series',
                onSubmitted: () => dateFocus.requestFocus(),
              ),
              const SizedBox(width: 14),
              _buildDateInput(
                label: 'Voucher Date',
                controller: dateController,
                focusNode: dateFocus,
                errorText: dateError,
                width: 170,
                onSubmitted: () {
                  onValidateDate();
                  vchNoFocus.requestFocus();
                },
              ),
              const SizedBox(width: 14),
              _buildPlainField(
                label: 'Voucher Number',
                controller: vchNoController,
                focusNode: vchNoFocus,
                width: 170,
                icon: Icons.confirmation_number_outlined,
                onSubmitted: () => saleTypeFocus.requestFocus(),
              ),
              const SizedBox(width: 14),
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildFieldWithFocus(
                  label: 'Party / Account Ledger',
                  controller: partyController,
                  focusNode: partyFocus,
                  icon: Icons.person_outline_rounded,
                  masterType: 'Account Ledger',
                  onSubmitted: () => partyGstinFocus.requestFocus(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: _buildPlainField(
                  label: 'Party GSTIN',
                  controller: partyGstinController,
                  focusNode: partyGstinFocus,
                  icon: Icons.badge_outlined,
                  onSubmitted: () => matCenterFocus.requestFocus(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: _buildFieldWithFocus(
                  label: 'Material Centre',
                  controller: matCenterController,
                  focusNode: matCenterFocus,
                  icon: Icons.storefront_outlined,
                  masterType: 'Material Centre',
                  onSubmitted: () => narrationFocus.requestFocus(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildPlainField(
            label: 'Narration / Remarks',
            controller: narrationController,
            focusNode: narrationFocus,
            icon: Icons.notes_rounded,
            onSubmitted: onNarrationSubmitted,
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
      height: 42,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => onSubmitted(),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF101B3A)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7B9B)),
          prefixIcon: const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF0F62FE)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          filled: true,
          fillColor: const Color(0xFFF8FAFD),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: errorText != null ? const Color(0xFFEE4343) : const Color(0xFFE2EAF5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
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
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: SizedBox(
              width: width ?? 200,
              child: Text(
                errorText,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFFEE4343)),
                maxLines: 2,
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
      height: 42,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => onSubmitted?.call(),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF101B3A)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7B9B)),
          prefixIcon: Icon(icon, size: 16, color: const Color(0xFF0F62FE)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          filled: true,
          fillColor: const Color(0xFFF8FAFD),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2EAF5))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.3)),
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
            height: 42,
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => onSubmitted?.call(),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF101B3A)),
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7B9B)),
                    prefixIcon: Icon(icon, size: 16, color: const Color(0xFF0F62FE)),
                    contentPadding: EdgeInsets.only(left: 12, right: isFocused ? 32 : 12, top: 0, bottom: 0),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFD),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2EAF5))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.3)),
                  ),
                ),
                if (isFocused)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: InkWell(
                      onTap: () => onQuickAdd(masterType),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(color: const Color(0xFF0F62FE), borderRadius: BorderRadius.circular(4)),
                        child: const Icon(Icons.add, size: 13, color: Colors.white),
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