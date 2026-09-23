// desktop/lib/services/gstr2b_reconciliation_service.dart
import 'dart:convert';
import '../utils/extensions.dart';

class ReconciliationResult {
  final int totalPortalInvoices;
  final int matchedCount;
  final int mismatchedCount;
  final int missingInBooksCount;
  final int missingInPortalCount;
  final List<Map<String, dynamic>> discrepancies;

  const ReconciliationResult({
    required this.totalPortalInvoices,
    required this.matchedCount,
    required this.mismatchedCount,
    required this.missingInBooksCount,
    required this.missingInPortalCount,
    required this.discrepancies,
  });
}

class Gstr2bReconciliationService {
  /// Normalizes invoice numbers by stripping slashes, dashes, spaces, and leading zeros.
  /// E.g. "INV/2026/001" and "INV-2026-1" both become "INV20261".
  static String normalizeInvoiceNo(String raw) {
    return raw
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '')
        .replaceFirst(RegExp(r'^0+'), '');
  }

  /// Extracts GSTIN from voucher root fields or parses from party text.
  static String extractGstin(Map<String, dynamic> v) {
    if (v['gstin'] != null && v['gstin'].toString().trim().isNotEmpty) {
      return v['gstin'].toString().trim().toUpperCase();
    }
    if (v['partyGstin'] != null && v['partyGstin'].toString().trim().isNotEmpty) {
      return v['partyGstin'].toString().trim().toUpperCase();
    }

    final partyStr = (v['party'] ?? '').toString().trim();
    final match = RegExp(r'\[\s*([^\]]+)\s*\]').firstMatch(partyStr);
    if (match != null) {
      return match.group(1)!.trim().toUpperCase();
    }

    // Direct 15-character GSTIN regex check
    if (RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$')
        .hasMatch(partyStr.toUpperCase())) {
      return partyStr.toUpperCase();
    }

    return '';
  }

  static double parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString().replaceAll(',', '').trim()) ?? 0.0;
  }

  /// Compares local purchase vouchers against downloaded GSTR-2B JSON export data
  static Future<ReconciliationResult> reconcile({
    required List<Map<String, dynamic>> localPurchases,
    required String gstr2bJsonString,
  }) async {
    Map<String, dynamic> portalData;
    try {
      portalData = jsonDecode(gstr2bJsonString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Invalid GSTR-2B JSON file structure: $e');
    }

    // 1. Extract B2B Invoices from official GSTR-2B JSON structure
    final List<Map<String, dynamic>> portalInvoices = [];
    final b2bSection = portalData['b2b'] ?? portalData['data']?['b2b'] ?? [];

    if (b2bSection is List) {
      for (final supplier in b2bSection) {
        if (supplier is Map) {
          final supplierGstin = (supplier['ctin'] ?? supplier['gstin'] ?? '').toString().trim().toUpperCase();
          final invoices = supplier['inv'] ?? supplier['invoices'] ?? [];
          if (invoices is List) {
            for (final inv in invoices) {
              if (inv is Map) {
                portalInvoices.add({
                  'gstin': supplierGstin,
                  'invoiceNo': (inv['inum'] ?? inv['invoiceNumber'] ?? '').toString().trim(),
                  'date': (inv['idt'] ?? inv['date'] ?? '').toString().trim(),
                  'taxableValue': parseDouble(inv['val'] ?? inv['taxableValue']),
                  'totalTax': parseDouble(inv['igst']) + parseDouble(inv['cgst']) + parseDouble(inv['sgst']),
                });
              }
            }
          }
        }
      }
    }

    int matchedCount = 0;
    int mismatchedCount = 0;
    int missingInBooksCount = 0;
    final List<Map<String, dynamic>> discrepancies = [];

    // Track matched local vouchers by their persistent ID to avoid false "missing" flags
    final Set<String> matchedLocalVoucherIds = {};

    // 2. Match Portal Invoices against Local Books
    for (final portalInv in portalInvoices) {
      final pGstin = portalInv['gstin'] as String;
      final pInvNo = portalInv['invoiceNo'] as String;
      final normPInvNo = normalizeInvoiceNo(pInvNo);
      final pTaxable = portalInv['taxableValue'] as double;

      final localMatch = localPurchases.where((v) {
        final lInvNo = (v['voucherNumber'] ?? '').toString().trim();
        final normLInvNo = normalizeInvoiceNo(lInvNo);
        final lGstin = extractGstin(v);

        final numberMatches = normLInvNo == normPInvNo || lInvNo.equalsIgnoreCase(pInvNo);
        final gstinMatches = lGstin.isEmpty || lGstin == pGstin;

        return numberMatches && gstinMatches;
      }).firstOrNull;

      if (localMatch == null) {
        missingInBooksCount++;
        discrepancies.add({
          'invoiceNo': pInvNo,
          'gstin': pGstin,
          'issue': 'Missing in Local Books',
          'portalValue': pTaxable,
          'localValue': 0.0,
        });
      } else {
        // Tag local voucher as matched using its unique ID (or voucherNumber + index)
        final uniqueLocalId = (localMatch['id'] ?? localMatch['voucherNumber']).toString();
        matchedLocalVoucherIds.add(uniqueLocalId);

        final lTaxable = parseDouble(localMatch['subTotal']);

        // Allow up to ₹1.00 tolerance for rounding variances
        if ((lTaxable - pTaxable).abs() > 1.0) {
          mismatchedCount++;
          discrepancies.add({
            'invoiceNo': pInvNo,
            'gstin': pGstin,
            'issue': 'Taxable Value Mismatch',
            'portalValue': pTaxable,
            'localValue': lTaxable,
          });
        } else {
          matchedCount++;
        }
      }
    }

    // 3. Identify local purchases missing in GSTR-2B (IMS Action Required)
    int missingInPortalCount = 0;
    for (final localVch in localPurchases) {
      final uniqueLocalId = (localVch['id'] ?? localVch['voucherNumber']).toString();

      // Skip local vouchers already matched or accounted for in Step 2
      if (matchedLocalVoucherIds.contains(uniqueLocalId)) {
        continue;
      }

      missingInPortalCount++;
      final lInvNo = (localVch['voucherNumber'] ?? '').toString().trim();
      final lGstin = extractGstin(localVch);

      discrepancies.add({
        'invoiceNo': lInvNo,
        'gstin': lGstin.isNotEmpty ? lGstin : 'Unspecified',
        'issue': 'Missing in GSTR-2B Portal (IMS Action Required)',
        'portalValue': 0.0,
        'localValue': parseDouble(localVch['subTotal']),
      });
    }

    return ReconciliationResult(
      totalPortalInvoices: portalInvoices.length,
      matchedCount: matchedCount,
      mismatchedCount: mismatchedCount,
      missingInBooksCount: missingInBooksCount,
      missingInPortalCount: missingInPortalCount,
      discrepancies: discrepancies,
    );
  }
}