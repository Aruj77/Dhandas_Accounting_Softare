import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../database/database_manager.dart';
import '../utils/app_date_utils.dart';

class StorageService {
  static const String _prefDirectoryKey = 'dhandas_data_directory_path';
  static final Map<String, Map<String, dynamic>> _mastersMemoryCache = {};

  static const Map<String, dynamic> defaultCompanyMasters = {
    'debtors': [
      {'name': 'Cash', 'gstin': '', 'group': 'Cash and Cash Equivalents - Petty Cash Vault'},
    ],
    'creditors': [
      {'name': 'Cash', 'gstin': '', 'group': 'Cash and Cash Equivalents - Petty Cash Vault'},
    ],
    'items': [],
    'series': ['Main'],
    'seriesSettings': {
      'Main': {
        'name': 'Main',
        'numberingType': 'Manual',
        'renumberingFreq': 'None',
        'yearFormat': 'YY-YY',
        'yearPosition': 'As Prefix',
        'separator': '/',
        'prefix': '',
        'suffix': '',
        'startNumber': 1,
        'endNumber': 99999999,
      }
    },
    'saleTypes': [
      'Local Itemwise',
      'InterState Itemwise',
      'Local Multirate',
      'InterState Multirate',
      'Local Exempt',
      'InterState Exempt',
    ],
    'units': [
      'BAG', 'BAL', 'BDL', 'BOX', 'BTL', 'BUN', 'CAN', 'CBM', 'CCM', 'CMS',
      'CTN', 'DOZ', 'DRM', 'GGK', 'GMS', 'GRS', 'GYD', 'KGS', 'KLR', 'KME',
      'MLT', 'MTR', 'MTS', 'NOS', 'PAC', 'PCS', 'PRS', 'QTL', 'ROL', 'SET',
      'SQF', 'SQM', 'SQY', 'TBS', 'TGM', 'THD', 'TON', 'TUB', 'UGS', 'UNT', 'YDS',
    ],
    'majorHeads': [
      'Non-Current Assets',
      'Current Assets',
      'Non-Current Liabilities',
      'Current Liabilities',
      'Shareholders\' Funds',
      'Revenue',
      'Other Income',
      'Cost of Goods Sold',
      'Operating Expenses',
    ],
    'accountGroups': [
      // ==========================================
      // 10000 - NON-CURRENT ASSETS
      // ==========================================
      {'name': 'Land - Freehold', 'majorHead': 'Non-Current Assets', 'id': '11100'},
      {'name': 'Land - Leasehold', 'majorHead': 'Non-Current Assets', 'id': '11150'},
      {'name': 'Buildings - Office Premises', 'majorHead': 'Non-Current Assets', 'id': '11200'},
      {'name': 'Buildings - Factory Structures', 'majorHead': 'Non-Current Assets', 'id': '11210'},
      {'name': 'Buildings - Warehouses', 'majorHead': 'Non-Current Assets', 'id': '11220'},
      {'name': 'Accumulated Depreciation - Buildings', 'majorHead': 'Non-Current Assets', 'id': '11250'},
      {'name': 'Plant and Machinery - Heavy Production Equipment', 'majorHead': 'Non-Current Assets', 'id': '11300'},
      {'name': 'Plant and Machinery - Assembly Lines', 'majorHead': 'Non-Current Assets', 'id': '11310'},
      {'name': 'Plant and Machinery - Electrical Installations', 'majorHead': 'Non-Current Assets', 'id': '11320'},
      {'name': 'Accumulated Depreciation - Plant and Machinery', 'majorHead': 'Non-Current Assets', 'id': '11350'},
      {'name': 'Office Equipment - Computers & Laptops', 'majorHead': 'Non-Current Assets', 'id': '11400'},
      {'name': 'Office Equipment - Servers & Networking Gear', 'majorHead': 'Non-Current Assets', 'id': '11410'},
      {'name': 'Office Equipment - Printers & Copiers', 'majorHead': 'Non-Current Assets', 'id': '11420'},
      {'name': 'Accumulated Depreciation - Office Equipment', 'majorHead': 'Non-Current Assets', 'id': '11450'},
      {'name': 'Furniture and Fixtures - Office Desks & Chairs', 'majorHead': 'Non-Current Assets', 'id': '11500'},
      {'name': 'Furniture and Fixtures - Retail Displays & Shelving', 'majorHead': 'Non-Current Assets', 'id': '11510'},
      {'name': 'Accumulated Depreciation - Furniture and Fixtures', 'majorHead': 'Non-Current Assets', 'id': '11550'},
      {'name': 'Vehicles - Executive Cars', 'majorHead': 'Non-Current Assets', 'id': '11600'},
      {'name': 'Vehicles - Delivery Lorries & Trucks', 'majorHead': 'Non-Current Assets', 'id': '11610'},
      {'name': 'Vehicles - Forklifts & Material Handlers', 'majorHead': 'Non-Current Assets', 'id': '11620'},
      {'name': 'Accumulated Depreciation - Vehicles', 'majorHead': 'Non-Current Assets', 'id': '11650'},
      {'name': 'Capital Work-in-Progress (CWIP) - Building Construction', 'majorHead': 'Non-Current Assets', 'id': '11700'},
      {'name': 'Capital Work-in-Progress (CWIP) - Machinery Installation', 'majorHead': 'Non-Current Assets', 'id': '11710'},
      {'name': 'Intangible Assets - Goodwill', 'majorHead': 'Non-Current Assets', 'id': '11800'},
      {'name': 'Intangible Assets - Corporate Brand & Trademarks', 'majorHead': 'Non-Current Assets', 'id': '11810'},
      {'name': 'Intangible Assets - Product Patents & Formulas', 'majorHead': 'Non-Current Assets', 'id': '11820'},
      {'name': 'Intangible Assets - ERP Software Licenses', 'majorHead': 'Non-Current Assets', 'id': '11830'},
      {'name': 'Accumulated Amortization - Intangible Assets', 'majorHead': 'Non-Current Assets', 'id': '11850'},
      {'name': 'Intangible Assets Under Development', 'majorHead': 'Non-Current Assets', 'id': '11900'},
      {'name': 'Long-Term Investments - Equity Shares in Subsidiaries', 'majorHead': 'Non-Current Assets', 'id': '12100'},
      {'name': 'Long-Term Investments - Government Bonds & Securities', 'majorHead': 'Non-Current Assets', 'id': '12110'},
      {'name': 'Long-Term Investments - Real Estate Properties', 'majorHead': 'Non-Current Assets', 'id': '12120'},
      {'name': 'Deferred Tax Assets (Net)', 'majorHead': 'Non-Current Assets', 'id': '12200'},
      {'name': 'Long-Term Loans and Advances - Security Deposits for Rent', 'majorHead': 'Non-Current Assets', 'id': '12300'},
      {'name': 'Long-Term Loans and Advances - Electricity & Utility Deposits', 'majorHead': 'Non-Current Assets', 'id': '12310'},
      {'name': 'Long-Term Loans and Advances - Capital Advances to Machinery Vendors', 'majorHead': 'Non-Current Assets', 'id': '12320'},
      {'name': 'Other Non-Current Assets - Long-Term Trade Receivables', 'majorHead': 'Non-Current Assets', 'id': '12400'},
      {'name': 'Other Non-Current Assets - Unamortized Preliminary Expenses', 'majorHead': 'Non-Current Assets', 'id': '12410'},

      // ==========================================
      // 13000 - CURRENT ASSETS
      // ==========================================
      {'name': 'Current Investments - Liquid Mutual Funds', 'majorHead': 'Current Assets', 'id': '13100'},
      {'name': 'Current Investments - Short-Term Treasury Bills', 'majorHead': 'Current Assets', 'id': '13110'},
      {'name': 'Inventory - Raw Materials', 'majorHead': 'Current Assets', 'id': '13200'},
      {'name': 'Inventory - Work-in-Progress (WIP)', 'majorHead': 'Current Assets', 'id': '13210'},
      {'name': 'Inventory - Finished Goods', 'majorHead': 'Current Assets', 'id': '13220'},
      {'name': 'Inventory - Stores, Spares & Loose Tools', 'majorHead': 'Current Assets', 'id': '13230'},
      {'name': 'Inventory - Goods-in-Transit', 'majorHead': 'Current Assets', 'id': '13240'},
      {'name': 'Sundry Debtors', 'majorHead': 'Current Assets', 'id': '13300'},
      {'name': 'Trade Receivables - Export Customers', 'majorHead': 'Current Assets', 'id': '13310'},
      {'name': 'Provision for Bad & Doubtful Debts', 'majorHead': 'Current Assets', 'id': '13350'},
      {'name': 'Cash and Cash Equivalents - Petty Cash Vault', 'majorHead': 'Current Assets', 'id': '13400'},
      {'name': 'Cash and Cash Equivalents - Bank Current Account (Local)', 'majorHead': 'Current Assets', 'id': '13410'},
      {'name': 'Cash and Cash Equivalents - Bank Current Account (Foreign Currency)', 'majorHead': 'Current Assets', 'id': '13420'},
      {'name': 'Cash and Cash Equivalents - Fixed Deposits (Maturity < 3 months)', 'majorHead': 'Current Assets', 'id': '13430'},
      {'name': 'Short-Term Loans and Advances - Employee Salary Loans', 'majorHead': 'Current Assets', 'id': '13500'},
      {'name': 'Short-Term Loans and Advances - Supplier Advances', 'majorHead': 'Current Assets', 'id': '13510'},
      {'name': 'Short-Term Loans and Advances - Prepaid Insurance Premiums', 'majorHead': 'Current Assets', 'id': '13520'},
      {'name': 'Short-Term Loans and Advances - Prepaid Rent', 'majorHead': 'Current Assets', 'id': '13530'},
      {'name': 'Short-Term Loans and Advances - Prepaid Software Subscriptions', 'majorHead': 'Current Assets', 'id': '13540'},
      {'name': 'Other Current Assets - Interest Accrued on Bank Deposits', 'majorHead': 'Current Assets', 'id': '13600'},
      {'name': 'Other Current Assets - GST Input Tax Credit (ITC) Balance', 'majorHead': 'Current Assets', 'id': '13610'},
      {'name': 'Other Current Assets - Customs Duty Drawback Receivable', 'majorHead': 'Current Assets', 'id': '13620'},

      // ==========================================
      // 21000 - NON-CURRENT LIABILITIES
      // ==========================================
      {'name': 'Long-Term Borrowings - Secured Bank Term Loans', 'majorHead': 'Non-Current Liabilities', 'id': '21100'},
      {'name': 'Long-Term Borrowings - Non-Convertible Debentures (NCDs)', 'majorHead': 'Non-Current Liabilities', 'id': '21110'},
      {'name': 'Long-Term Borrowings - Unsecured Infrastructure Bonds', 'majorHead': 'Non-Current Liabilities', 'id': '21120'},
      {'name': 'Long-Term Borrowings - Long-Term Loans from Promoters', 'majorHead': 'Non-Current Liabilities', 'id': '21130'},
      {'name': 'Deferred Tax Liabilities (Net)', 'majorHead': 'Non-Current Liabilities', 'id': '21200'},
      {'name': 'Other Long-Term Liabilities - Premium on Redemption of Debentures', 'majorHead': 'Non-Current Liabilities', 'id': '21300'},
      {'name': 'Other Long-Term Liabilities - Long-Term Lease Obligations (IFRS 16)', 'majorHead': 'Non-Current Liabilities', 'id': '21310'},
      {'name': 'Other Long-Term Liabilities - Long-Term Trade Payables', 'majorHead': 'Non-Current Liabilities', 'id': '21320'},
      {'name': 'Long-Term Provisions - Provision for Employee Gratuity', 'majorHead': 'Non-Current Liabilities', 'id': '21400'},
      {'name': 'Long-Term Provisions - Provision for Employee Pension Fund', 'majorHead': 'Non-Current Liabilities', 'id': '21410'},
      {'name': 'Long-Term Provisions - Provision for Asset Decommissioning Costs', 'majorHead': 'Non-Current Liabilities', 'id': '21420'},

      // ==========================================
      // 22000 - CURRENT LIABILITIES
      // ==========================================
      {'name': 'Short-Term Borrowings - Bank Cash Credit facility', 'majorHead': 'Current Liabilities', 'id': '22100'},
      {'name': 'Short-Term Borrowings - Bank Overdraft Account', 'majorHead': 'Current Liabilities', 'id': '22110'},
      {'name': 'Short-Term Borrowings - Commercial Papers (CPs) Issued', 'majorHead': 'Current Liabilities', 'id': '22120'},
      {'name': 'Short-Term Borrowings - Working Capital Demand Loans', 'majorHead': 'Current Liabilities', 'id': '22130'},
      {'name': 'Sundry Creditors', 'majorHead': 'Current Liabilities', 'id': '22200'},
      {'name': 'Trade Payables - Other Domestic Suppliers', 'majorHead': 'Current Liabilities', 'id': '22210'},
      {'name': 'Trade Payables - Foreign Vendors / Overseas Suppliers', 'majorHead': 'Current Liabilities', 'id': '22220'},
      {'name': 'Trade Payables - Bills Payable', 'majorHead': 'Current Liabilities', 'id': '22230'},
      {'name': 'Other Current Liabilities - Current Maturities of Long-Term Debt', 'majorHead': 'Current Liabilities', 'id': '22300'},
      {'name': 'Other Current Liabilities - Interest Accrued but Not Due on Loans', 'majorHead': 'Current Liabilities', 'id': '22310'},
      {'name': 'Other Current Liabilities - Interest Accrued and Due on Loans', 'majorHead': 'Current Liabilities', 'id': '22320'},
      {'name': 'Other Current Liabilities - Income Received in Advance (Unearned Revenue)', 'majorHead': 'Current Liabilities', 'id': '22330'},
      {'name': 'Other Current Liabilities - Unpaid & Unclaimed Dividends', 'majorHead': 'Current Liabilities', 'id': '22340'},
      {'name': 'Other Current Liabilities - Statutory Dues: GST Output Payable', 'majorHead': 'Current Liabilities', 'id': '22350'},
      {'name': 'Other Current Liabilities - Statutory Dues: TDS Deducted Payable', 'majorHead': 'Current Liabilities', 'id': '22360'},
      {'name': 'Other Current Liabilities - Statutory Dues: PF & ESI Payable', 'majorHead': 'Current Liabilities', 'id': '22370'},
      {'name': 'Other Current Liabilities - Accrued Office Rent Expense', 'majorHead': 'Current Liabilities', 'id': '22380'},
      {'name': 'Other Current Liabilities - Accrued Employee Salaries & Bonus', 'majorHead': 'Current Liabilities', 'id': '22390'},
      {'name': 'Short-Term Provisions - Provision for Corporate Income Tax', 'majorHead': 'Current Liabilities', 'id': '22400'},
      {'name': 'Short-Term Provisions - Proposed Dividend to Shareholders', 'majorHead': 'Current Liabilities', 'id': '22410'},
      {'name': 'Short-Term Provisions - Provision for Product Warranties', 'majorHead': 'Current Liabilities', 'id': '22420'},
      {'name': 'Short-Term Provisions - Provision for Compensated Leave Absences', 'majorHead': 'Current Liabilities', 'id': '22430'},

      // ==========================================
      // 30000 - EQUITY / CAPITAL
      // ==========================================
      {'name': 'Share Capital - Authorised Equity Share Capital', 'majorHead': 'Shareholders\' Funds', 'id': '31100'},
      {'name': 'Share Capital - Subscribed and Fully Paid Equity Capital', 'majorHead': 'Shareholders\' Funds', 'id': '31110'},
      {'name': 'Share Capital - Preference Share Capital', 'majorHead': 'Shareholders\' Funds', 'id': '31120'},
      {'name': 'Share Capital - Share Forfeiture Account', 'majorHead': 'Shareholders\' Funds', 'id': '31130'},
      {'name': 'Reserves and Surplus - Capital Reserve Account', 'majorHead': 'Shareholders\' Funds', 'id': '32100'},
      {'name': 'Reserves and Surplus - Capital Redemption Reserve (CRR)', 'majorHead': 'Shareholders\' Funds', 'id': '32110'},
      {'name': 'Reserves and Surplus - Securities Premium Account', 'majorHead': 'Shareholders\' Funds', 'id': '32120'},
      {'name': 'Reserves and Surplus - General Reserve Account', 'majorHead': 'Shareholders\' Funds', 'id': '32130'},
      {'name': 'Reserves and Surplus - Revaluation Reserve', 'majorHead': 'Shareholders\' Funds', 'id': '32140'},
      {'name': 'Reserves and Surplus - Foreign Currency Translation Reserve', 'majorHead': 'Shareholders\' Funds', 'id': '32150'},
      {'name': 'Reserves and Surplus - Profit & Loss Account Balance (Surplus)', 'majorHead': 'Shareholders\' Funds', 'id': '32160'},
      {'name': 'Share Application Money Pending Allotment', 'majorHead': 'Shareholders\' Funds', 'id': '33100'},

      // ==========================================
      // 40000 - INCOME / REVENUE
      // ==========================================
      {'name': 'Operating Revenue - Domestic Product Sales', 'majorHead': 'Revenue', 'id': '41100'},
      {'name': 'Operating Revenue - Export Product Sales', 'majorHead': 'Revenue', 'id': '41110'},
      {'name': 'Operating Revenue - Technical Services Rendered', 'majorHead': 'Revenue', 'id': '41120'},
      {'name': 'Operating Revenue - SaaS Subscription Revenues', 'majorHead': 'Revenue', 'id': '41130'},
      {'name': 'Operating Revenue - Less: Sales Returns and Rebates', 'majorHead': 'Revenue', 'id': '41190'},
      {'name': 'Other Income - Interest Income on Bank Deposits', 'majorHead': 'Other Income', 'id': '42100'},
      {'name': 'Other Income - Dividend Income from Long-Term Stocks', 'majorHead': 'Other Income', 'id': '42110'},
      {'name': 'Other Income - Net Realized Foreign Exchange Gains', 'majorHead': 'Other Income', 'id': '42120'},
      {'name': 'Other Income - Net Gain on Disposal of Property, Plant & Equipment', 'majorHead': 'Other Income', 'id': '42130'},
      {'name': 'Other Income - Scrap and Waste Material Sales', 'majorHead': 'Other Income', 'id': '42140'},
      {'name': 'Other Income - Insurance Claim Settlements Received', 'majorHead': 'Other Income', 'id': '42150'},

      // ==========================================
      // 50000 - COGS / DIRECT COSTS
      // ==========================================
      {'name': 'Direct Production Costs - Raw Material Purchases', 'majorHead': 'Cost of Goods Sold', 'id': '51100'},
      {'name': 'Direct Production Costs - Import Freight and Inward Logistics', 'majorHead': 'Cost of Goods Sold', 'id': '51110'},
      {'name': 'Direct Production Costs - Customs Duties & Clearing Charges', 'majorHead': 'Cost of Goods Sold', 'id': '51120'},
      {'name': 'Direct Production Costs - Factory Workers Direct Wages', 'majorHead': 'Cost of Goods Sold', 'id': '51200'},
      {'name': 'Direct Production Costs - Sub-Contracting & Job Work Outsource Fees', 'majorHead': 'Cost of Goods Sold', 'id': '51210'},
      {'name': 'Direct Production Costs - Factory Electricity Power & Water Utilities', 'majorHead': 'Cost of Goods Sold', 'id': '51300'},
      {'name': 'Direct Production Costs - Fuel, Gas, and Boiler Consumables', 'majorHead': 'Cost of Goods Sold', 'id': '51310'},
      {'name': 'Direct Production Costs - Factory Stores, Spares & Consumable Tools', 'majorHead': 'Cost of Goods Sold', 'id': '51400'},
      {'name': 'Direct Production Costs - Repair & Maintenance of Plant Machinery', 'majorHead': 'Cost of Goods Sold', 'id': '51410'},

      // ==========================================
      // 60000 - OPERATING EXPENSES (OPEX)
      // ==========================================
      {'name': 'Employee Benefit Expenses - Administrative Staff Salaries', 'majorHead': 'Operating Expenses', 'id': '61100'},
      {'name': 'Employee Benefit Expenses - Management Remuneration & Bonuses', 'majorHead': 'Operating Expenses', 'id': '61110'},
      {'name': 'Employee Benefit Expenses - Employer Contribution to Provident Fund (PF)', 'majorHead': 'Operating Expenses', 'id': '61120'},
      {'name': 'Employee Benefit Expenses - Corporate Group Medical Insurance', 'majorHead': 'Operating Expenses', 'id': '61130'},
      {'name': 'Employee Benefit Expenses - Staff Welfare, Catering & Office Pantry', 'majorHead': 'Operating Expenses', 'id': '61140'},
      {'name': 'Employee Benefit Expenses - Recruitment, Headhunting & Interview Costs', 'majorHead': 'Operating Expenses', 'id': '61150'},
      {'name': 'Employee Benefit Expenses - Workforce Training & Skill Upgrade Courses', 'majorHead': 'Operating Expenses', 'id': '61160'},
      {'name': 'Administrative Expenses - Head Office Building Rental', 'majorHead': 'Operating Expenses', 'id': '62100'},
      {'name': 'Administrative Expenses - Office Power, Water & Housekeeping', 'majorHead': 'Operating Expenses', 'id': '62110'},
      {'name': 'Administrative Expenses - Office Stationery, Printing & Courier', 'majorHead': 'Operating Expenses', 'id': '62120'},
      {'name': 'Administrative Expenses - Broadband, Leased Lines & Mobile Connections', 'majorHead': 'Operating Expenses', 'id': '62130'},
      {'name': 'Administrative Expenses - Software Subscriptions & IT Cloud Infrastructure', 'majorHead': 'Operating Expenses', 'id': '62140'},
      {'name': 'Administrative Expenses - Legal Fees, Court Costs & Litigation Expenses', 'majorHead': 'Operating Expenses', 'id': '62200'},
      {'name': 'Administrative Expenses - Company Secretarial & Filing Fees', 'majorHead': 'Operating Expenses', 'id': '62210'},
      {'name': 'Administrative Expenses - Statutory, Tax, and Internal Audit Fees', 'majorHead': 'Operating Expenses', 'id': '62220'},
      {'name': 'Administrative Expenses - Repair & Maintenance of Corporate Office Buildings', 'majorHead': 'Operating Expenses', 'id': '62300'},
      {'name': 'Administrative Expenses - IT Hardware & Software AMC / Support Fees', 'majorHead': 'Operating Expenses', 'id': '62310'},
      {'name': 'Administrative Expenses - Commercial Property and Liability Insurance', 'majorHead': 'Operating Expenses', 'id': '62400'},
      {'name': 'Administrative Expenses - Bank Processing Charges & Transaction Fees', 'majorHead': 'Operating Expenses', 'id': '62500'},
      {'name': 'Administrative Expenses - Credit Card Processing Commissions', 'majorHead': 'Operating Expenses', 'id': '62510'},
      {'name': 'Selling & Distribution Expenses - Advertisement and Media Placements', 'majorHead': 'Operating Expenses', 'id': '63100'},
      {'name': 'Selling & Distribution Expenses - Digital Marketing, SEO & Performance Ads', 'majorHead': 'Operating Expenses', 'id': '63110'},
      {'name': 'Selling & Distribution Expenses - Exhibition Stalls and Trade Fair Costs', 'majorHead': 'Operating Expenses', 'id': '63120'},
      {'name': 'Selling & Distribution Expenses - Sales Force Field Incentives and Commissions', 'majorHead': 'Operating Expenses', 'id': '63200'},
      {'name': 'Selling & Distribution Expenses - Outward Freight, Shipping & Warehouse Dispatch', 'majorHead': 'Operating Expenses', 'id': '63300'},
      {'name': 'Selling & Distribution Expenses - Sales Team Travel, Lodging & Conveyance', 'majorHead': 'Operating Expenses', 'id': '63400'},
      {'name': 'Selling & Distribution Expenses - Client Entertainment, Gifting & Customer Relations', 'majorHead': 'Operating Expenses', 'id': '63500'},
      {'name': 'Selling & Distribution Expenses - Customer Bad Debts Written Off', 'majorHead': 'Operating Expenses', 'id': '63600'},
      {'name': 'Non-Cash Expenses - Depreciation on Tangible Fixed Assets', 'majorHead': 'Operating Expenses', 'id': '64100'},
      {'name': 'Non-Cash Expenses - Amortization on Intangible Assets', 'majorHead': 'Operating Expenses', 'id': '64200'},
      {'name': 'Financial Expenses - Interest Paid on Secured Bank Term Loans', 'majorHead': 'Operating Expenses', 'id': '64300'},
      {'name': 'Financial Expenses - Interest Paid on Working Capital Bank Overdrafts', 'majorHead': 'Operating Expenses', 'id': '64310'},
      {'name': 'Financial Expenses - Coupon Payouts on Corporate Bonds & Debentures', 'majorHead': 'Operating Expenses', 'id': '64320'},
    ],
    'materialCenters': [
      'Main Store',
      'Warehouse',
      'Godown',
    ],
    'billSundries': [
      'CGST', 'SGST', 'IGST', 'Discount', 'Freight & Forwarding Charges', 'Round Off+', 'Round Off-'
    ],
    'taxCategories': [
      '0% Exempt', 'GST 5%', 'GST 12%', 'GST 18%', 'GST 28%',
    ],
  };

  static Future<String?> getSavedDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_prefDirectoryKey);
    if (path != null && await Directory(path).exists()) {
      return path;
    }
    return null;
  }

  static Future<void> saveDirectory(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefDirectoryKey, path);
  }

  static String normalizeFySlug(String fy) {
    return fy.replaceAll(' ', '_').replaceAll('/', '-');
  }

  static Future<String> getNextCompanyFolderId(String baseDirectoryPath) async {
    final baseDir = Directory(baseDirectoryPath);
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }

    final folderRegex = RegExp(r'^DHAN-(\d{3,}$)$', caseSensitive: false);
    int highestIndex = 0;

    await for (final entity in baseDir.list()) {
      if (entity is Directory) {
        final folderName = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
        final match = folderRegex.firstMatch(folderName);
        if (match != null) {
          final parsedIndex = int.tryParse(match.group(1)!) ?? 0;
          if (parsedIndex > highestIndex) {
            highestIndex = parsedIndex;
          }
        }
      }
    }

    return 'DHAN-${(highestIndex + 1).toString().padLeft(3, '0')}';
  }

  static Future<String> saveCompanyLocally({
    required String directoryPath,
    required Map<String, dynamic> companyData,
  }) async {
    final baseDir = Directory(directoryPath);
    if (!await baseDir.exists()) await baseDir.create(recursive: true);

    final folderId = await getNextCompanyFolderId(directoryPath);
    final companyDir = Directory('${baseDir.path}${Platform.pathSeparator}$folderId');

    if (await companyDir.exists()) {
      await companyDir.delete(recursive: true);
    }
    await companyDir.create(recursive: true);

    final initialFys = ['2024-25', '2025-26', AppDateUtils.defaultFinancialYear];
    final defaultActiveFy = AppDateUtils.defaultFinancialYear;

    final updatedData = Map<String, dynamic>.from(companyData)
      ..['id'] = folderId
      ..['companyId'] = folderId
      ..['folderPath'] = companyDir.path
      ..['financialYears'] = companyData['financialYears'] ?? initialFys
      ..['activeFinancialYear'] = companyData['activeFinancialYear'] ?? defaultActiveFy;

    for (final fy in (updatedData['financialYears'] as List)) {
      final fyDir = Directory('${companyDir.path}${Platform.pathSeparator}${normalizeFySlug(fy.toString())}');
      if (!await fyDir.exists()) await fyDir.create(recursive: true);
    }

    final file = File('${companyDir.path}${Platform.pathSeparator}company.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(updatedData));

    await saveCompanyMasters(folderPath: companyDir.path, mastersData: defaultCompanyMasters);
    return folderId;
  }

  static Future<void> updateCompanyLocally({required Map<String, dynamic> companyData}) async {
    final folderPath = companyData['folderPath']?.toString();
    if (folderPath != null && await Directory(folderPath).exists()) {
      final fys = companyData['financialYears'];
      if (fys is List) {
        for (final fy in fys) {
          final fyDir = Directory('$folderPath${Platform.pathSeparator}${normalizeFySlug(fy.toString())}');
          if (!await fyDir.exists()) await fyDir.create(recursive: true);
        }
      }
      final file = File('$folderPath${Platform.pathSeparator}company.json');
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(companyData));
    }
  }

  static Future<void> deleteCompanyLocally({required Map<String, dynamic> companyData}) async {
    final folderPath = companyData['folderPath']?.toString();
    if (folderPath != null) {
      _mastersMemoryCache.remove(folderPath);
      await DatabaseManager.instance.disposeCompany(folderPath);

      final dir = Directory(folderPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
  }

  static Future<Map<String, dynamic>> loadCompanyMasters({required String folderPath}) async {
    if (folderPath.trim().isEmpty) {
      debugPrint('StorageService: loadCompanyMasters called with empty folderPath!');
      return Map<String, dynamic>.from(defaultCompanyMasters);
    }

    if (_mastersMemoryCache.containsKey(folderPath)) {
      return jsonDecode(jsonEncode(_mastersMemoryCache[folderPath]!)) as Map<String, dynamic>;
    }

    final file = File('$folderPath${Platform.pathSeparator}masters.json');
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        _mastersMemoryCache[folderPath] = data;
        return jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('StorageService: Error parsing masters.json: $e');
      }
    }
    final initial = Map<String, dynamic>.from(defaultCompanyMasters);
    await saveCompanyMasters(folderPath: folderPath, mastersData: initial);
    return initial;
  }

  static Future<void> saveCompanyMasters({
    required String folderPath,
    required Map<String, dynamic> mastersData,
  }) async {
    if (folderPath.trim().isEmpty) {
      debugPrint('StorageService: ERROR - saveCompanyMasters called with empty folderPath!');
      return;
    }
    _mastersMemoryCache[folderPath] = mastersData;
    final file = File('$folderPath${Platform.pathSeparator}masters.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(mastersData));
    debugPrint('StorageService: Successfully saved masters to ${file.path}');
  }

  static VouchersTableCompanion _mapVoucherToCompanion(
    Map<String, dynamic> vch, {
    required String defaultVchType,
    required String defaultSeries,
  }) {
    final id = vch['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
    final series = (vch['series']?.toString().isNotEmpty == true)
        ? vch['series'].toString()
        : defaultSeries;
    final type = (vch['voucherType']?.toString().isNotEmpty == true)
        ? vch['voucherType'].toString()
        : defaultVchType;

    return VouchersTableCompanion(
      id: Value(id),
      hlcTimestamp: vch['hlcTimestamp'] != null
          ? Value(vch['hlcTimestamp'].toString())
          : const Value.absent(),
      originNodeId: vch['originNodeId'] != null
          ? Value(vch['originNodeId'].toString())
          : const Value.absent(),
      isDeleted: Value(vch['isDeleted'] == true),
      voucherNumber: Value(vch['voucherNumber']?.toString() ?? ''),
      voucherType: Value(type),
      date: Value(vch['date']?.toString() ?? ''),
      series: Value(series),
      partyName: Value(vch['party']?.toString() ?? vch['partyName']?.toString() ?? ''),
      grandTotal: Value(double.tryParse(vch['grandTotal']?.toString() ?? '0') ?? 0.0),
      subTotal: Value(double.tryParse(vch['subTotal']?.toString() ?? '0') ?? 0.0),
      totalTax: Value(double.tryParse(vch['totalTax']?.toString() ?? '0') ?? 0.0),
      payloadJson: Value(jsonEncode(vch)),
      irn: vch['irn'] != null ? Value(vch['irn'].toString()) : const Value.absent(),
      ackNo: vch['ackNo'] != null ? Value(vch['ackNo'].toString()) : const Value.absent(),
      signedQrCode: vch['signedQrCode'] != null
          ? Value(vch['signedQrCode'].toString())
          : const Value.absent(),
      isSynced: Value(vch['isSynced'] == true),
    );
  }

  static Future<void> saveVoucher({
    required String folderPath,
    required String financialYear,
    required Map<String, dynamic> voucherData,
  }) async {
    final vchType = voucherData['voucherType']?.toString() ?? 'Sales Invoice';
    final seriesName = voucherData['series']?.toString() ?? 'Main';

    final db = DatabaseManager.instance.getSeriesDatabase(
      companyFolderPath: folderPath,
      financialYear: financialYear,
      voucherType: vchType,
      seriesName: seriesName,
    );

    final companion = _mapVoucherToCompanion(
      voucherData,
      defaultVchType: vchType,
      defaultSeries: seriesName,
    );

    await db.into(db.vouchersTable).insertOnConflictUpdate(companion);
  }

  static Future<void> saveAllVouchers({
    required String folderPath,
    required String financialYear,
    required String voucherType,
    String? seriesName,
    required List<Map<String, dynamic>> vouchers,
  }) async {
    final targetSeries = seriesName ?? 'Main';
    final db = DatabaseManager.instance.getSeriesDatabase(
      companyFolderPath: folderPath,
      financialYear: financialYear,
      voucherType: voucherType,
      seriesName: targetSeries,
    );

    await db.batch((batch) {
      for (final vch in vouchers) {
        final companion = _mapVoucherToCompanion(
          vch,
          defaultVchType: voucherType,
          defaultSeries: targetSeries,
        );
        batch.insert(
          db.vouchersTable,
          companion,
          onConflict: DoUpdate((_) => companion),
        );
      }
    });
  }

  static Future<List<Map<String, dynamic>>> loadVouchers({
    required String folderPath,
    required String financialYear,
    String? voucherType,
    String? seriesName,
  }) async {
    final fySlug = normalizeFySlug(financialYear);
    final fyDir = Directory('$folderPath${Platform.pathSeparator}$fySlug');
    if (!await fyDir.exists()) return [];

    if (voucherType != null && seriesName != null && seriesName.toLowerCase() != 'all') {
      final db = DatabaseManager.instance.getSeriesDatabase(
        companyFolderPath: folderPath,
        financialYear: financialYear,
        voucherType: voucherType,
        seriesName: seriesName,
      );
      return _fetchVouchersFromDb(db);
    }

    final List<Map<String, dynamic>> allVouchers = [];
    await for (final entity in fyDir.list()) {
      if (entity is File && entity.path.endsWith('.sqlite')) {
        final fileName = entity.uri.pathSegments.last.toLowerCase();

        if (voucherType != null && voucherType.toLowerCase() != 'all') {
          final targetBase = voucherType.toLowerCase().contains('sale')
              ? 'sales'
              : voucherType.toLowerCase().contains('purchase')
                  ? 'purchase'
                  : voucherType.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
          if (!fileName.contains(targetBase)) continue;
        }

        if (seriesName != null && seriesName.toLowerCase() != 'all') {
          final cleanSeries = seriesName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
          if (!fileName.contains(cleanSeries)) continue;
        }

        final db = AppDatabase(NativeDatabase.createInBackground(
          entity,
          setup: DatabaseManager.applyOptimizedPragmas,
        ));
        try {
          final vouchers = await _fetchVouchersFromDb(db);
          allVouchers.addAll(vouchers);
        } finally {
          await db.close();
        }
      }
    }
    return allVouchers;
  }

  static Future<List<Map<String, dynamic>>> _fetchVouchersFromDb(AppDatabase db) async {
    final List<Map<String, dynamic>> vouchers = [];
    try {
      final rows = await (db.select(db.vouchersTable)
            ..where((t) => t.isDeleted.equals(false)))
          .get();
      for (final r in rows) {
        try {
          vouchers.add(jsonDecode(r.payloadJson) as Map<String, dynamic>);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('StorageService: Error loading vouchers: $e');
    }
    return vouchers;
  }

  static Future<List<Map<String, dynamic>>> loadCompanies(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) return [];

    final List<Map<String, dynamic>> companies = [];
    await for (final entity in dir.list()) {
      if (entity is Directory) {
        final companyJsonFile = File('${entity.path}${Platform.pathSeparator}company.json');
        if (await companyJsonFile.exists()) {
          try {
            final content = await companyJsonFile.readAsString();
            final data = jsonDecode(content);
            if (data is Map<String, dynamic>) {
              data['folderPath'] = entity.path;
              companies.add(data);
            }
          } catch (_) {}
        }
      }
    }
    return companies;
  }
}