import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../constants/app_colors.dart';

/// Configuration values controlled by the Print Studio sidebar.
class PrintStudioConfig {
  final bool isLandscape;
  final bool isLegal;
  final double margin;
  final double columnScale;
  final double tableFontSize;
  final double borderWidth;
  final bool showAddress;
  final bool showDateRange;
  final bool showSubtitle;
  final bool alternateRowColors;

  const PrintStudioConfig({
    required this.isLandscape,
    required this.isLegal,
    required this.margin,
    required this.columnScale,
    required this.tableFontSize,
    required this.borderWidth,
    required this.showAddress,
    required this.showDateRange,
    required this.showSubtitle,
    required this.alternateRowColors,
  });

  PdfPageFormat get activeFormat {
    final base = isLegal ? PdfPageFormat.legal : PdfPageFormat.a4;
    return isLandscape ? base.landscape : base.portrait;
  }
}

typedef PrintPdfGenerator = FutureOr<Uint8List> Function(
  PdfPageFormat format,
  PrintStudioConfig config,
);

class PrintStudioDialog extends StatefulWidget {
  final String title;
  final String pdfFileName;
  final PrintPdfGenerator onBuildPdf;
  final bool initialLandscape;
  final bool initialLegal;
  final double initialMargin;
  final double initialColumnScale;
  final double initialTableFontSize;
  final double initialBorderWidth;
  final bool showTableScaling;
  final bool showDocumentToggles;

  const PrintStudioDialog({
    super.key,
    required this.title,
    required this.pdfFileName,
    required this.onBuildPdf,
    this.initialLandscape = true,
    this.initialLegal = false,
    this.initialMargin = 20.0,
    this.initialColumnScale = 1.0,
    this.initialTableFontSize = 8.0,
    this.initialBorderWidth = 0.5,
    this.showTableScaling = true,
    this.showDocumentToggles = true,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String pdfFileName,
    required PrintPdfGenerator onBuildPdf,
    bool initialLandscape = true,
    bool initialLegal = false,
    double initialMargin = 20.0,
    double initialColumnScale = 1.0,
    double initialTableFontSize = 8.0,
    double initialBorderWidth = 0.5,
    bool showTableScaling = true,
    bool showDocumentToggles = true,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => PrintStudioDialog(
        title: title,
        pdfFileName: pdfFileName,
        onBuildPdf: onBuildPdf,
        initialLandscape: initialLandscape,
        initialLegal: initialLegal,
        initialMargin: initialMargin,
        initialColumnScale: initialColumnScale,
        initialTableFontSize: initialTableFontSize,
        initialBorderWidth: initialBorderWidth,
        showTableScaling: showTableScaling,
        showDocumentToggles: showDocumentToggles,
      ),
    );
  }

  @override
  State<PrintStudioDialog> createState() => _PrintStudioDialogState();
}

class _PrintStudioDialogState extends State<PrintStudioDialog> {
  late bool _isLandscape = widget.initialLandscape;
  late bool _isLegal = widget.initialLegal;
  late double _selectedMargin = widget.initialMargin;
  late double _columnScale = widget.initialColumnScale;
  late double _tableFontSize = widget.initialTableFontSize;
  late double _borderWidth = widget.initialBorderWidth;

  bool _showAddress = true;
  bool _showDateRange = true;
  bool _showSubtitle = true;
  bool _alternateRowColors = false;

  PrintStudioConfig get _currentConfig => PrintStudioConfig(
        isLandscape: _isLandscape,
        isLegal: _isLegal,
        margin: _selectedMargin,
        columnScale: _columnScale,
        tableFontSize: _tableFontSize,
        borderWidth: _borderWidth,
        showAddress: _showAddress,
        showDateRange: _showDateRange,
        showSubtitle: _showSubtitle,
        alternateRowColors: _alternateRowColors,
      );

  void _resetDefaults() {
    setState(() {
      _isLandscape = widget.initialLandscape;
      _isLegal = widget.initialLegal;
      _selectedMargin = widget.initialMargin;
      _columnScale = widget.initialColumnScale;
      _tableFontSize = widget.initialTableFontSize;
      _borderWidth = widget.initialBorderWidth;
      _showAddress = true;
      _showDateRange = true;
      _showSubtitle = true;
      _alternateRowColors = false;
    });
  }

  Widget _buildSidebarCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeConfig = _currentConfig;
    final activeFormat = activeConfig.activeFormat;

    return Dialog(
      backgroundColor: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: math.min(MediaQuery.of(context).size.width * 0.96, 1380),
        height: math.min(MediaQuery.of(context).size.height * 0.94, 900),
        child: Column(
          children: [
            // Top Bar
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.print_rounded, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Print Studio — ${widget.title}',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_isLegal ? 'Legal' : 'A4'} • ${_isLandscape ? 'Landscape' : 'Portrait'}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _resetDefaults,
                    icon: const Icon(Icons.refresh_rounded, size: 15, color: AppColors.textSecondary),
                    label: const Text(
                      'Reset Defaults',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Studio Workspace
            Expanded(
              child: Row(
                children: [
                  // Left Control Sidebar
                  Container(
                    width: 320,
                    decoration: const BoxDecoration(
                      color: AppColors.cardBg,
                      border: Border(right: BorderSide(color: AppColors.border, width: 1.2)),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildSidebarCard(
                          'PAGE LAYOUT',
                          Icons.description_rounded,
                          [
                            const Text('Orientation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(value: true, label: Text('Landscape', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                ButtonSegment(value: false, label: Text('Portrait', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                              ],
                              selected: {_isLandscape},
                              showSelectedIcon: false,
                              style: SegmentedButton.styleFrom(
                                selectedBackgroundColor: AppColors.primary,
                                selectedForegroundColor: AppColors.surface,
                              ),
                              onSelectionChanged: (val) => setState(() => _isLandscape = val.first),
                            ),
                            const SizedBox(height: 12),
                            const Text('Paper Size', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(value: false, label: Text('A4', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                ButtonSegment(value: true, label: Text('Legal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                              ],
                              selected: {_isLegal},
                              showSelectedIcon: false,
                              style: SegmentedButton.styleFrom(
                                selectedBackgroundColor: AppColors.primary,
                                selectedForegroundColor: AppColors.surface,
                              ),
                              onSelectionChanged: (val) => setState(() => _isLegal = val.first),
                            ),
                          ],
                        ),
                        _buildSidebarCard(
                          'PAGE MARGINS',
                          Icons.border_outer_rounded,
                          [
                            Row(
                              children: [
                                Text('Margin: ${_selectedMargin.toInt()} pt', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                const Spacer(),
                              ],
                            ),
                            Slider(
                              value: _selectedMargin,
                              min: 8.0,
                              max: 45.0,
                              divisions: 37,
                              activeColor: AppColors.primary,
                              onChanged: (val) => setState(() => _selectedMargin = val),
                            ),
                          ],
                        ),
                        if (widget.showTableScaling)
                          _buildSidebarCard(
                            'TABLE SCALING',
                            Icons.tune_rounded,
                            [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Column Flex', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                  Text('${(_columnScale * 100).toInt()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                ],
                              ),
                              Slider(
                                value: _columnScale,
                                min: 0.8,
                                max: 1.6,
                                divisions: 8,
                                activeColor: AppColors.primary,
                                onChanged: (val) => setState(() => _columnScale = val),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Font Size', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                  Text('${_tableFontSize.toStringAsFixed(1)} pt', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                ],
                              ),
                              Slider(
                                value: _tableFontSize,
                                min: 7.0,
                                max: 10.5,
                                divisions: 7,
                                activeColor: AppColors.primary,
                                onChanged: (val) => setState(() => _tableFontSize = val),
                              ),
                            ],
                          ),
                        if (widget.showDocumentToggles)
                          _buildSidebarCard(
                            'DOCUMENT OPTIONS',
                            Icons.tune_rounded,
                            [
                              CheckboxListTile(
                                value: _showAddress,
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                activeColor: AppColors.primary,
                                title: const Text('Header Details', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                onChanged: (val) => setState(() => _showAddress = val ?? true),
                              ),
                              CheckboxListTile(
                                value: _showDateRange,
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                activeColor: AppColors.primary,
                                title: const Text('Show Period / Date Range', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                onChanged: (val) => setState(() => _showDateRange = val ?? true),
                              ),
                              CheckboxListTile(
                                value: _alternateRowColors,
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                activeColor: AppColors.primary,
                                title: const Text('Zebra Striping (Rows)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                onChanged: (val) => setState(() => _alternateRowColors = val ?? false),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Live PDF Preview Canvas
                  Expanded(
                    child: Container(
                      color: AppColors.background,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          appBarTheme: const AppBarTheme(
                            backgroundColor: AppColors.surface,
                            elevation: 0,
                            iconTheme: IconThemeData(color: AppColors.primary),
                          ),
                          primaryColor: AppColors.primary,
                          scaffoldBackgroundColor: AppColors.background,
                        ),
                        child: PdfPreview(
                          build: (format) => widget.onBuildPdf(activeFormat, activeConfig),
                          initialPageFormat: activeFormat,
                          canChangePageFormat: false,
                          canChangeOrientation: false,
                          allowPrinting: true,
                          allowSharing: true,
                          pdfFileName: widget.pdfFileName,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}