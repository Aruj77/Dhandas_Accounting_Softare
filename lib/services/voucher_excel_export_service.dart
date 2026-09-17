import 'dart:io';
import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoucherExcelExportService {
  static const String _prefExportDirectoryKey = 'dhandas_last_export_dir_path';

  static Future<String?> getOrChooseExportDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedPath = prefs.getString(_prefExportDirectoryKey);

    if (savedPath != null && await Directory(savedPath).exists()) {
      return savedPath;
    }

    final String? pickedDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Default Directory to Save Exports',
    );

    if (pickedDir != null && pickedDir.isNotEmpty) {
      await prefs.setString(_prefExportDirectoryKey, pickedDir);
      return pickedDir;
    }

    return null;
  }

  static String resolveRegisterTitle(String voucherType) {
    final lower = voucherType.toLowerCase();
    if (lower.contains('sale')) {
      return 'Supply Outward (Sales) Register';
    } else if (lower.contains('purchase')) {
      return 'Supply Inward (Purchase) Register';
    }
    return '$voucherType Register';
  }

  static Future<String?> exportToExcel({
    required Map<String, dynamic> company,
    required String voucherType,
    required DateTime fromDate,
    required DateTime toDate,
    required List<Map<String, dynamic>> filteredVouchers,
    required List<String> activeKeys,
    required Map<String, String> columnLabels,
    required String Function(String) extractPartyName,
    required String Function(String) extractPartyGstin,
    required String Function(String, bool) getPlaceOfSupply,
    required double Function(Map<String, dynamic>) extractCessAmount,
    required String Function(DateTime) formatDate,
    required double totalQuantity,
    required double totalInvoiceValue,
    required double totalTaxable,
    required double totalIgst,
    required double totalCgst,
    required double totalSgst,
    required double totalCess,
    required Future<bool> Function(String) onConfirmOverwrite,
  }) async {
    final exportDir = await getOrChooseExportDirectory();
    if (exportDir == null) return null;

    final fileName = '${voucherType.replaceAll(' ', '_').toLowerCase()}_register.xlsx';
    final filePath = '$exportDir${Platform.pathSeparator}$fileName';

    if (!await onConfirmOverwrite(filePath)) return null;

    final excel = xls.Excel.createExcel();
    final defaultSheetName = excel.getDefaultSheet() ?? 'Sheet1';
    final xls.Sheet sheet = excel[defaultSheetName];

    final int totalCols = activeKeys.length;
    if (totalCols == 0) return null;

    final lastColIndex = totalCols - 1;

    final companyName = (company['name'] ?? company['companyName'] ?? 'Business Firm').toString().trim();
    final companyAddress = (company['address'] ?? '').toString().trim();
    final dateRangeStr = 'F.Y. ${company['activeFinancialYear'] ?? '2026-27'} (${formatDate(fromDate)} to ${formatDate(toDate)})';
    final registerSubtitle = resolveRegisterTitle(voucherType);

    final thinBlackBorder = xls.Border(
      borderStyle: xls.BorderStyle.Thin,
      borderColorHex: xls.ExcelColor.fromHexString('#000000'),
    );

    final noBorder = xls.Border(borderStyle: xls.BorderStyle.None);

    final gridCellStyle = xls.CellStyle(
      fontSize: 10,
      leftBorder: thinBlackBorder,
      rightBorder: thinBlackBorder,
      topBorder: thinBlackBorder,
      bottomBorder: thinBlackBorder,
      verticalAlign: xls.VerticalAlign.Center,
    );

    final headerCellStyle = xls.CellStyle(
      bold: true,
      fontSize: 11,
      horizontalAlign: xls.HorizontalAlign.Center,
      verticalAlign: xls.VerticalAlign.Center,
      leftBorder: thinBlackBorder,
      rightBorder: thinBlackBorder,
      topBorder: thinBlackBorder,
      bottomBorder: thinBlackBorder,
    );

    final footerCellStyle = xls.CellStyle(
      bold: true,
      fontSize: 11,
      verticalAlign: xls.VerticalAlign.Center,
      leftBorder: thinBlackBorder,
      rightBorder: thinBlackBorder,
      topBorder: thinBlackBorder,
      bottomBorder: thinBlackBorder,
    );

    int currentRow = 0;

    // ROW 1: COMPANY NAME
    sheet.updateCell(
      xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      xls.TextCellValue(companyName),
      cellStyle: xls.CellStyle(
        bold: true,
        underline: xls.Underline.Single,
        fontSize: 16,
        horizontalAlign: xls.HorizontalAlign.Center,
        verticalAlign: xls.VerticalAlign.Center,
        leftBorder: noBorder,
        rightBorder: noBorder,
        topBorder: noBorder,
        bottomBorder: noBorder,
      ),
    );
    if (lastColIndex > 0) {
      sheet.merge(
        xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        xls.CellIndex.indexByColumnRow(columnIndex: lastColIndex, rowIndex: currentRow),
      );
    }
    currentRow++;

    // ROW 2: ADDRESS (Omitted if empty)
    if (companyAddress.isNotEmpty) {
      sheet.updateCell(
        xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        xls.TextCellValue(companyAddress),
        cellStyle: xls.CellStyle(
          bold: true,
          fontSize: 11,
          horizontalAlign: xls.HorizontalAlign.Center,
          verticalAlign: xls.VerticalAlign.Center,
          leftBorder: noBorder,
          rightBorder: noBorder,
          topBorder: noBorder,
          bottomBorder: noBorder,
        ),
      );
      if (lastColIndex > 0) {
        sheet.merge(
          xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
          xls.CellIndex.indexByColumnRow(columnIndex: lastColIndex, rowIndex: currentRow),
        );
      }
      currentRow++;
    }

    // ROW 3: DATE RANGE
    sheet.updateCell(
      xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      xls.TextCellValue(dateRangeStr),
      cellStyle: xls.CellStyle(
        bold: true,
        italic: true,
        fontSize: 11,
        horizontalAlign: xls.HorizontalAlign.Center,
        verticalAlign: xls.VerticalAlign.Center,
        leftBorder: noBorder,
        rightBorder: noBorder,
        topBorder: noBorder,
        bottomBorder: noBorder,
      ),
    );
    if (lastColIndex > 0) {
      sheet.merge(
        xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        xls.CellIndex.indexByColumnRow(columnIndex: lastColIndex, rowIndex: currentRow),
      );
    }
    currentRow++;

    // ROW 4: REGISTER TYPE SUBTITLE (Merged across table width)
    sheet.updateCell(
      xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      xls.TextCellValue(registerSubtitle),
      cellStyle: xls.CellStyle(
        bold: true,
        fontSize: 12,
        horizontalAlign: xls.HorizontalAlign.Center,
        verticalAlign: xls.VerticalAlign.Center,
        leftBorder: noBorder,
        rightBorder: noBorder,
        topBorder: noBorder,
        bottomBorder: noBorder,
      ),
    );
    if (lastColIndex > 0) {
      sheet.merge(
        xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        xls.CellIndex.indexByColumnRow(columnIndex: lastColIndex, rowIndex: currentRow),
      );
    }
    currentRow++;

    // TABLE HEADERS
    for (int c = 0; c < activeKeys.length; c++) {
      sheet.updateCell(
        xls.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: currentRow),
        xls.TextCellValue(columnLabels[activeKeys[c]]!),
        cellStyle: headerCellStyle,
      );
    }
    currentRow++;

    // DATA ROWS
    int snoCount = 0;
    for (final v in filteredVouchers) {
      final vchNo = (v['voucherNumber'] ?? '').toString();
      final date = (v['date'] ?? '').toString();
      final fullParty = (v['party'] ?? '').toString();
      final partyName = extractPartyName(fullParty);
      final gstin = extractPartyGstin(fullParty);
      final isInterState = v['isInterState'] == true;
      final pos = getPlaceOfSupply(gstin, isInterState);
      final invoiceTotal = double.tryParse(v['grandTotal']?.toString() ?? '0') ?? 0.0;
      final cessTotal = extractCessAmount(v);
      final items = v['items'] as List? ?? [];

      if (items.isEmpty) {
        snoCount++;
        for (int c = 0; c < activeKeys.length; c++) {
          xls.CellValue cellVal;
          switch (activeKeys[c]) {
            case 'sno':
              cellVal = xls.TextCellValue('$snoCount');
              break;
            case 'party':
              cellVal = xls.TextCellValue(partyName);
              break;
            case 'gstin':
              cellVal = xls.TextCellValue(gstin);
              break;
            case 'pos':
              cellVal = xls.TextCellValue(pos);
              break;
            case 'vchNo':
              cellVal = xls.TextCellValue(vchNo);
              break;
            case 'date':
              cellVal = xls.TextCellValue(date);
              break;
            case 'qty':
              cellVal = xls.DoubleCellValue(0.0);
              break;
            case 'unit':
              cellVal = xls.TextCellValue('Pcs');
              break;
            case 'hsn':
              cellVal = xls.TextCellValue('');
              break;
            case 'invoiceVal':
              cellVal = xls.DoubleCellValue(invoiceTotal);
              break;
            case 'taxable':
              cellVal = xls.DoubleCellValue(0.0);
              break;
            case 'taxRate':
              cellVal = xls.TextCellValue('0%');
              break;
            case 'igst':
              cellVal = xls.DoubleCellValue(double.tryParse(v['igst']?.toString() ?? '0') ?? 0.0);
              break;
            case 'cgst':
              cellVal = xls.DoubleCellValue(double.tryParse(v['cgst']?.toString() ?? '0') ?? 0.0);
              break;
            case 'sgst':
              cellVal = xls.DoubleCellValue(double.tryParse(v['sgst']?.toString() ?? '0') ?? 0.0);
              break;
            case 'cess':
              cellVal = xls.DoubleCellValue(cessTotal);
              break;
            default:
              cellVal = xls.TextCellValue('');
          }
          sheet.updateCell(
            xls.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: currentRow),
            cellVal,
            cellStyle: gridCellStyle,
          );
        }
        currentRow++;
      } else {
        for (int i = 0; i < items.length; i++) {
          if (i == 0) snoCount++;
          final item = items[i];
          final qty = double.tryParse(item['qty']?.toString() ?? '0') ?? 0.0;
          final unit = (item['unit'] ?? 'Pcs').toString();
          final hsn = (item['hsn'] ?? '').toString();
          final taxable = double.tryParse(item['taxable']?.toString() ?? '0') ?? 0.0;
          final taxRate = '${item['gstRate'] ?? 0}%';
          final igstVal = double.tryParse(item['igst']?.toString() ?? '0') ?? 0.0;
          final cgstVal = double.tryParse(item['cgst']?.toString() ?? '0') ?? 0.0;
          final sgstVal = double.tryParse(item['sgst']?.toString() ?? '0') ?? 0.0;

          for (int c = 0; c < activeKeys.length; c++) {
            xls.CellValue cellVal;
            switch (activeKeys[c]) {
              case 'sno':
                cellVal = xls.TextCellValue(i == 0 ? '$snoCount' : '');
                break;
              case 'party':
                cellVal = xls.TextCellValue(i == 0 ? partyName : '');
                break;
              case 'gstin':
                cellVal = xls.TextCellValue(i == 0 ? gstin : '');
                break;
              case 'pos':
                cellVal = xls.TextCellValue(i == 0 ? pos : '');
                break;
              case 'vchNo':
                cellVal = xls.TextCellValue(i == 0 ? vchNo : '');
                break;
              case 'date':
                cellVal = xls.TextCellValue(i == 0 ? date : '');
                break;
              case 'qty':
                cellVal = xls.DoubleCellValue(qty);
                break;
              case 'unit':
                cellVal = xls.TextCellValue(unit);
                break;
              case 'hsn':
                cellVal = xls.TextCellValue(hsn);
                break;
              case 'invoiceVal':
                cellVal = i == 0 ? xls.DoubleCellValue(invoiceTotal) : xls.TextCellValue('');
                break;
              case 'taxable':
                cellVal = xls.DoubleCellValue(taxable);
                break;
              case 'taxRate':
                cellVal = xls.TextCellValue(taxRate);
                break;
              case 'igst':
                cellVal = xls.DoubleCellValue(igstVal);
                break;
              case 'cgst':
                cellVal = xls.DoubleCellValue(cgstVal);
                break;
              case 'sgst':
                cellVal = xls.DoubleCellValue(sgstVal);
                break;
              case 'cess':
                cellVal = i == 0 ? xls.DoubleCellValue(cessTotal) : xls.TextCellValue('');
                break;
              default:
                cellVal = xls.TextCellValue('');
            }
            sheet.updateCell(
              xls.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: currentRow),
              cellVal,
              cellStyle: gridCellStyle,
            );
          }
          currentRow++;
        }
      }
    }

    // FOOTER TOTAL ROW
    for (int c = 0; c < activeKeys.length; c++) {
      xls.CellValue cellVal;
      switch (activeKeys[c]) {
        case 'sno':
          cellVal = xls.TextCellValue('');
          break;
        case 'party':
          cellVal = xls.TextCellValue('TOTAL');
          break;
        case 'qty':
          cellVal = xls.DoubleCellValue(totalQuantity);
          break;
        case 'invoiceVal':
          cellVal = xls.DoubleCellValue(totalInvoiceValue);
          break;
        case 'taxable':
          cellVal = xls.DoubleCellValue(totalTaxable);
          break;
        case 'igst':
          cellVal = xls.DoubleCellValue(totalIgst);
          break;
        case 'cgst':
          cellVal = xls.DoubleCellValue(totalCgst);
          break;
        case 'sgst':
          cellVal = xls.DoubleCellValue(totalSgst);
          break;
        case 'cess':
          cellVal = xls.DoubleCellValue(totalCess);
          break;
        default:
          cellVal = xls.TextCellValue('');
      }

      sheet.updateCell(
        xls.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: currentRow),
        cellVal,
        cellStyle: footerCellStyle,
      );
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
      return filePath;
    }
    return null;
  }
}