import 'package:flutter/material.dart';

// ──────────────────────────────────────────────
// App Constants — single source of truth for all
// hardcoded values across the codebase.
// ──────────────────────────────────────────────

// ── App Metadata ──

class AppMeta {
  static const String name = 'Expense Tracker';
  static const String version = 'Expense Tracker v1.0.0';
  static const String dbFileName = 'expense_tracker.db';
  static const String dbWebName = 'expense_tracker';
  static const String sqliteWasmUri = 'sqlite3.wasm';
  static const String driftWorkerUri = 'drift_worker.dart.js';
}

// ── Spacing & Sizing ──

class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double section = 24;

  // Icon sizes
  static const double iconSm = 14;
  static const double iconMd = 20;
  static const double iconLg = 28;
  static const double iconXl = 48;
  static const double iconXxl = 64;

  // Avatar / container sizes
  static const double avatarSm = 24;
  static const double avatarMd = 36;
  static const double avatarLg = 48;
  static const double avatarXl = 80;

  // Button sizing
  static const double buttonHeight = 48;
  static const double fabElevation = 4;
  static const double cardElevation = 1;

  // Chart sizing
  static const double chartHeight = 220;
  static const double pieRadius = 50;
  static const double pieCenterRadius = 30;
  static const double pieSectionSpace = 2;

  // Border radius
  static const double radiusXs = 3;
  static const double radiusSm = 4;
  static const double radiusMd = 6;
  static const double radiusLg = 8;
  static const double radiusXl = 12;
  static const double radiusXxl = 16;

  // Progress bar
  static const double progressHeightSm = 8;
  static const double progressHeightMd = 12;

  // Color swatch
  static const double swatchSize = 12;
  static const double swatchSizeLg = 36;
}

// ── Edge Insets (convenience) ──

class AppEdgeInsets {
  static const EdgeInsets allXs = EdgeInsets.all(AppSpacing.xs);
  static const EdgeInsets allSm = EdgeInsets.all(AppSpacing.sm);
  static const EdgeInsets allMd = EdgeInsets.all(AppSpacing.md);
  static const EdgeInsets allLg = EdgeInsets.all(AppSpacing.lg);
  static const EdgeInsets allXl = EdgeInsets.all(AppSpacing.xl);
  static const EdgeInsets allXxl = EdgeInsets.all(AppSpacing.xxl);

  static const EdgeInsets symH = EdgeInsets.symmetric(horizontal: AppSpacing.lg);
  static const EdgeInsets symV = EdgeInsets.symmetric(vertical: AppSpacing.sm);

  static const EdgeInsets lrLg = EdgeInsets.fromLTRB(
    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg,
  );
  static const EdgeInsets lrLgTop = EdgeInsets.fromLTRB(
    AppSpacing.lg, 0, AppSpacing.lg, 0,
  );

  static const EdgeInsets onlyBottomSm = EdgeInsets.only(bottom: AppSpacing.sm);
  static const EdgeInsets onlyRightLg = EdgeInsets.only(right: AppSpacing.lg);
}

// ── Durations ──

class AppDurations {
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration dotAnimation = Duration(milliseconds: 200);
  static const Duration chatScrollDelay = Duration(milliseconds: 100);
  static const Duration chatScrollAnim = Duration(milliseconds: 300);
  static const Duration purgeCutoff = Duration(days: 30);
  static const Duration defaultGoalOffset = Duration(days: 90);
  static const Duration oneDay = Duration(days: 1);
  static const Duration oneWeek = Duration(days: 7);
  static const Duration sixDays = Duration(days: 6);
}

// ── SharedPreferences Keys ──

class PrefKeys {
  static const String currencyCode = 'currency_code';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String savingsGoals = 'savings_goals';
  static const String appPin = 'app_pin';
  static const String biometricEnabled = 'biometric_enabled';
  static const String dailyBudgetTarget = 'daily_budget_target';
}

// ── Date Formats ──

class DateFormats {
  static const String display = 'MMM d, y';
  static const String displayYear = 'MMM d, yyyy';
  static const String displayShort = 'MMM d';
  static const String csv = 'yyyy-MM-dd';
  static const String csvAlt = 'MM/dd/yyyy';
  static const String fileTimestamp = 'yyyyMMdd_HHmmss';
  static const String reportMonth = 'MMMM yyyy';
  static const String chipRange = 'MMMd';
}

// ── Payment Methods ──

class PaymentMethods {
  static const String cash = 'Cash';
  static const String card = 'Card';
  static const String eWallet = 'E-Wallet';

  static const List<String> all = [cash, card, eWallet];
}

// ── Recurring Frequencies ──

class RecurringFrequencies {
  static const String daily = 'daily';
  static const String weekly = 'weekly';
  static const String monthly = 'monthly';
  static const String yearly = 'yearly';

  static const List<String> all = [daily, weekly, monthly, yearly];
}

// ── Account Types ──

class AccountTypes {
  static const String checking = 'Checking';
  static const String savings = 'Savings';
  static const String cash = 'Cash';
  static const String creditCard = 'Credit Card';
  static const String loan = 'Loan';
  static const String personLoan = 'Personal Loan';
  static const String investment = 'Investment';

  static const List<String> all = [checking, savings, cash, creditCard, loan, personLoan, investment];
}

// ── Account Icons ──

class AccountIcons {
  static const String bank = 'account_balance';
  static const String savings = 'savings';
  static const String creditCard = 'credit_card';
  static const String payments = 'payments';
  static const String wallet = 'wallet';

  static const List<String> all = [bank, savings, creditCard, payments, wallet];
}

// ── Category Types ──

class CategoryTypes {
  static const String expense = 'expense';
  static const String income = 'income';

  static const List<String> all = [expense, income];
}

// ── Default Colors ──

class AppColors {
  static const int categoryDefault = 0xFF757575;
  static const int accountDefault = 0xFF1E88E5;
  static const int primary = 0xFF6750A4;
  static const int primaryLight = 0xFFD0BCFF;
  static const int surface = 0xFFFEF7FF;
  static const int error = 0xFFE53935;
  static const int success = 0xFF43A047;

  // Named colors for common use
  static const Color grey = Colors.grey;
  static const Color green = Colors.green;
  static const Color red = Colors.red;
  static const Color orange = Colors.orange;
  static const Color blue = Colors.blue;
  static const Color amber = Colors.amber;
  static const Color purple = Colors.purple;
  static const Color white = Colors.white;
  static const Color black54 = Colors.black54;

  // Category color options
  static const List<int> categoryColors = [
    0xFFE53935, 0xFF1E88E5, 0xFF43A047, 0xFF8E24AA,
    0xFFFB8C00, 0xFF00897B, 0xFFD81B60, 0xFF3949AB,
    0xFFC0CA33, 0xFF8D6E63,
  ];

  // Account color options
  static const List<int> accountColors = [
    0xFF1E88E5, 0xFF43A047, 0xFFE53935, 0xFFFB8C00,
    0xFF8E24AA, 0xFF00ACC1, 0xFF6D4C41, 0xFF546E7A,
  ];
}

// ── File Extensions & Names ──

class AppFiles {
  static const String backupExtension = '.etb';
  static const String csvExtension = '.csv';
  static const String pdfExtension = '.pdf';
  static const String backupPrefix = 'expense_tracker_backup_';
  static const String csvPrefix = 'expenses_';
  static const String pdfPrefix = 'expense_report_';
  static const String backupShareText = 'Expense Tracker Backup';
  static const String pdfShareText = 'Expense Report';
}

// ── SnackBar Messages ──

class AppMessages {
  // Expense
  static const String expenseAdded = 'Expense added';
  static const String expenseUpdated = 'Expense updated';
  static const String expenseDeleted = 'Expense moved to trash';
  static const String expensePermDeleted = 'Expense permanently deleted';
  static const String noExpenses = 'No expenses yet. Tap + to add one!';
  static const String noExpensesFilter = 'No expenses match your filters.';
  static const String noExpensesMonth = 'No expenses this month. Add some!';

  // Income
  static const String incomeAdded = 'Income added';
  static const String incomeUpdated = 'Income updated';
  static const String incomeDeleted = 'Income moved to trash';
  static const String incomePermDeleted = 'Income permanently deleted';
  static const String noIncomes = 'No incomes yet.';

  // Accounts
  static const String accountCreated = 'Account created';
  static const String accountUpdated = 'Account updated';
  static const String accountDeleted = 'Account deleted';
  static const String noAccounts = 'No accounts';
  static const String addAccountsInSettings = 'Add accounts in Settings';

  // Transfers
  static const String transferPrefix = 'Transferred ';

  // Categories
  static const String categoryAdded = 'Category added';
  static const String categoryUpdated = 'Category updated';
  static const String categoryDeleted = 'Category deleted';
  static const String categoryDefaultCannotDelete = 'Default categories cannot be deleted.';
  static const String nameRequired = 'Name is required.';

  // Budget
  static const String budgetUpdated = 'Budget updated!';
  static const String categoryBudgetSet = 'Category budget set!';
  static const String budgetDeleted = 'Budget deleted';

  // Backup
  static const String enterPassphrase = 'Enter a passphrase';
  static const String passphraseTooShort = 'Passphrase must be at least 4 characters';
  static const String backupExported = 'Backup exported successfully';
  static const String enterPassphraseAndData = 'Enter passphrase and paste backup data';
  static const String pasteCsvFirst = 'Paste CSV content first';

  // PIN
  static const String pinEnabled = 'PIN lock enabled';
  static const String pinDisabled = 'PIN lock disabled';
  static const String pinsDoNotMatch = 'PINs do not match';
  static const String pinSetSuccess = 'PIN set successfully!';
  static const String incorrectPin = 'Incorrect PIN';
  static const String enterPin = 'Enter PIN';
  static const String biometricReason = 'Unlock Expense Tracker';

  // Dialogs
  static const String areYouSure = 'Are you sure?';
  static const String cancel = 'Cancel';
  static const String deleteLabel = 'Delete';
  static const String deleteForever = 'Delete Forever';
  static const String save = 'Save';
  static const String update = 'Update';
  static const String add = 'Add';
  static const String next = 'Next';
  static const String getStarted = 'Get Started';
  static const String skip = 'Skip';
  static const String none = 'None';
  static const String all = 'All';
  static const String reset = 'Reset';
  static const String apply = 'Apply';
  static const String undo = 'Undo';
  static const String import = 'Import';
  static const String importing = 'Importing...';
  static const String export = 'Export';
  static const String ok = 'OK';

  // Trash
  static const String trashEmptied = 'Trash emptied — ';
  static const String itemsRemoved = ' items removed';
  static const String trashIsEmptyTitle = 'Trash is empty';
  static const String trashRetentionNote = 'Deleted items appear here for 30 days';
  static const String noDeletedExpenses = 'No deleted expenses';
  static const String noDeletedIncomes = 'No deleted incomes';

  // Data
  static const String allDataCleared = 'All data cleared.';
  static const String noDataForPeriod = 'No data found for this period.';

  // CSV
  static const String csvHeaders = 'Date,Amount,Category,Note,Payment Method';
}

// ── Default Categories (expense) ──

class DefaultCategories {
  static const List<Map<String, dynamic>> expense = [
    {'name': 'Food', 'icon': 'restaurant', 'color': 0xFFE53935},
    {'name': 'Transport', 'icon': 'directions_car', 'color': 0xFF1E88E5},
    {'name': 'Bills', 'icon': 'receipt', 'color': 0xFF43A047},
    {'name': 'Shopping', 'icon': 'shopping_bag', 'color': 0xFFFB8C00},
    {'name': 'Entertainment', 'icon': 'movie', 'color': 0xFF8E24AA},
    {'name': 'Health', 'icon': 'local_hospital', 'color': 0xFF00897B},
    {'name': 'Education', 'icon': 'school', 'color': 0xFF3949AB},
    {'name': 'Other', 'icon': 'more_horiz', 'color': 0xFF757575},
  ];

  static const List<Map<String, dynamic>> income = [
    {'name': 'Salary', 'icon': 'work', 'color': 0xFF43A047},
    {'name': 'Freelance', 'icon': 'computer', 'color': 0xFF1E88E5},
    {'name': 'Investment', 'icon': 'trending_up', 'color': 0xFF8E24AA},
    {'name': 'Gift', 'icon': 'card_giftcard', 'color': 0xFFE53935},
  ];
}

// ── Category Icon Names ──

class CategoryIcons {
  static const List<String> names = [
    'restaurant', 'directions_car', 'shopping_bag', 'receipt', 'movie',
    'local_hospital', 'school', 'work', 'computer', 'trending_up',
    'card_giftcard', 'more_horiz', 'savings', 'fitness_center', 'flight',
    'pets', 'music_note', 'photo_camera',
  ];
}

// ── Currencies ──

class Currencies {
  static const Map<String, String> all = {
    'USD': r'$',
    'PHP': '₱',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'INR': '₹',
    'KRW': '₩',
    'BRL': r'R$',
  };
}

// ── Default Accounts ──

class DefaultAccounts {
  static const String cash = 'Cash';
  static const String bankAccount = 'Bank Account';
  static const String creditCard = 'Credit Card';
}

// ── Limits & Thresholds ──

class AppLimits {
  static const int pinLength = 4;
  static const int passphraseMinLength = 4;
  static const int minSuggestionsData = 5;
  static const int minDiningOutThreshold = 3;
  static const int minAnomalyData = 3;
  static const int recentExpensesLimit = 5;
  static const int chartLegendLimit = 6;
  static const int tagsDisplayLimit = 3;
  static const int upcomingBillsDaysDefault = 30;
  static const int whatIfDefaultReduction = 20;
  static const int encryptionKeyLength = 32;

  // AI thresholds
  static const double foodThreshold = 0.3;
  static const double transportThreshold = 0.2;
  static const double savingFraction = 0.2;
  static const double anomalyStdDev = 2.0;

  // Date range boundary for queries
  static const int dayBoundary = 1;
}

// ── Navigation Labels ──

class NavLabels {
  static const String home = 'Home';
  static const String analytics = 'Analytics';
  static const String budget = 'Budget';
  static const String insights = 'Insights';
  static const String settings = 'Settings';
  static const String add = 'Add';
}

// ── Page Titles ──

class PageTitles {
  static const String dashboard = 'Expense Tracker';
  static const String allExpenses = 'All Expenses';
  static const String allIncomes = 'All Incomes';
  static const String analytics = 'Analytics';
  static const String budget = 'Budget';
  static const String insights = 'AI Insights';
  static const String settings = 'Settings';
  static const String accounts = 'Accounts';
  static const String addAccount = 'Add Account';
  static const String editAccount = 'Edit Account';
  static const String accountDetail = 'Account Details';
  static const String transfer = 'Transfer Money';
  static const String categories = 'Categories';
  static const String trash = 'Trash';
  static const String upcomingBills = 'Upcoming Bills';
  static const String backup = 'Backup & Restore';
  static const String savingsGoals = 'Savings Goals';
  static const String newGoal = 'New Savings Goal';
  static const String importCsv = 'Import CSV';
  static const String pdfReport = 'PDF Report';
  static const String addExpense = 'Add Expense';
  static const String editExpense = 'Edit Expense';
  static const String addIncome = 'Add Income';
  static const String editIncome = 'Edit Income';
  static const String setPin = 'Set PIN';
  static const String changePin = 'Change PIN';
  static const String addCategory = 'Add Category';
  static const String editCategory = 'Edit Category';
}

// ── UI Labels (Section Titles, Card Titles) ──

class UiLabels {
  static const String today = 'Today';
  static const String thisWeek = 'This Week';
  static const String thisMonth = 'This Month';
  static const String income = 'Income';
  static const String netBalance = 'Net Balance';
  static const String remainingBudget = 'Remaining Budget';
  static const String topCategory = 'Top Category';
  static const String wallets = 'Wallets';
  static const String recentExpenses = 'Recent Expenses';
  static const String spendingByCategory = 'Spending by Category';
  static const String dailyTrend = 'Daily Spending Trend';
  static const String categoryBreakdown = 'Category Breakdown';
  static const String overallBudget = 'Overall Budget';
  static const String categoryBudgets = 'Category Budgets';
  static const String appearance = 'Appearance';
  static const String data = 'Data';
  static const String security = 'Security';
  static const String recurring = 'Recurring';
  static const String aiAssistant = 'AI Assistant';
  static const String darkMode = 'Dark Mode';
  static const String currency = 'Currency';
  static const String manageCategories = 'Manage Categories';
  static const String manageAccounts = 'Manage Accounts';
  static const String generatePdf = 'Generate PDF Report';
  static const String exportCsv = 'Export as CSV';
  static const String importCsv = 'Import CSV';
  static const String backupRestore = 'Backup & Restore';
  static const String pinLock = 'PIN Lock';
  static const String changePin = 'Change PIN';
  static const String biometricLock = 'Biometric Lock';
  static const String onDeviceAi = 'On-Device AI';
  static const String savingsGoals = 'Savings Goals';
  static const String forecast = 'End-of-Month Forecast';
  static const String anomalies = 'Unusual Expenses Detected';
  static const String patterns = 'Spending Patterns';
  static const String suggestions = 'Saving Suggestions';
  static const String chatAssistant = 'AI Chat Assistant';
  static const String edit = 'Edit';
  static const String delete = 'Delete';
  static const String filters = 'Filters';
  static const String searchHint = 'Search notes or categories...';
  static const String tagHint = 'comma-separated, e.g. groceries, household';
  static const String tagHintIncome = 'comma-separated, e.g. freelance, one-time';
  static const String passphrase = 'Passphrase';
  static const String passphraseHint = 'min 4 characters';
  static const String restoreFromBackup = 'Restore from backup:';
  static const String pasteBackupHere = 'Paste backup data here';
  static const String pasteCsvHere = 'Paste your CSV data below:';
  static const String selectCategory = 'Select category';
  static const String noAccount = 'None';
  static const String accountOptional = 'Account (optional)';
  static const String account = 'Account';
  static const String paymentMethodOptional = 'Payment Method (optional)';
  static const String noteOptional = 'Note (optional)';
  static const String sourceOptional = 'Source (optional)';
  static const String tagsOptional = 'Tags (optional)';
  static const String amount = 'Amount';
  static const String category = 'Category';
  static const String date = 'Date';

  // Settings descriptions
  static const String accDesc = 'Add, edit, or transfer between accounts';
  static const String csvDesc = 'Import expenses from a CSV file';
  static const String backupDesc = 'Encrypted backup for device migration';
  static const String trashDesc = 'View and restore deleted items';
  static const String recurringDesc = 'View and manage recurring bills';
  static const String aiDesc = 'Works offline. No setup needed.';
  static const String goalDesc = 'Track savings toward a target';

  // Trash
  static const String emptyTrash = 'Empty Trash';
  static const String restore = 'Restore';
  static const String emptyTrashTitle = 'Empty Trash?';
  static const String permanentlyDelete = 'Permanently Delete?';
  static const String itemsWillBeRemoved = ' items will be permanently removed';
  static const String deleteExpenseTitle = 'Delete Expense';
  static const String deleteIncomeTitle = 'Delete Income';
  static const String deleteCategoryTitle = 'Delete Category';
  static const String deleteAccountTitle = 'Delete Account';
  static const String deleteGoalTitle = 'Delete Goal';
  static const String deleteBudgetTitle = 'Delete Budget';
  static const String clearAllData = 'Clear All Data';
  static const String importBackup = 'Import Backup';

  // Backup
  static const String exportBackup = 'Export Encrypted Backup';
  static const String restoreBackup = 'Restore from Backup';
  static const String backupPrivacy = 'Your data stays on-device. Use an encrypted backup to move between devices.';
  static const String restoreWarning = 'This will replace ALL current data. Continue?';
  static const String clearDataWarning = 'This will permanently delete all expenses, incomes, budgets, and custom categories. Continue?';

  // Category type display labels
  static const String expenseLabel = 'Expense';
  static const String incomeLabel = 'Income';

  // Misc
  static const String enabled = 'Enabled';
  static const String disabled = 'Disabled';
  static const String noAccountFound = 'No accounts. Add one in Settings.';
  static const String invalidBackup = 'Invalid backup format';
  static const String backupImported = 'Backup imported successfully';
  static const String csvExample = '2024-01-15,42.50,Groceries,Food\n01/15/2024,12.00,Coffee,Food';
  static const String defaultCurrencyCode = 'PHP';
  static const String fallbackCurrencySymbol = '\$';
  static const String noIncomeToDelete = 'No incomes to delete';
  static const String noExpenseToDelete = 'No expenses to delete';
  static const String transferPrefix = 'Transfer';
  static const String editOverallBudget = 'Edit Overall Budget';
}

// ── Error Message Patterns ──

class ErrorMessages {
  static const String errorPrefix = 'Error: ';
  static const String exportFailed = 'Export failed: ';
  static const String importFailed = 'Import failed: ';
  static const String transferFailed = 'Transfer failed: ';
  static const String loadFailed = 'Failed to load deleted items: ';
  static const String pdfFailed = 'Failed to generate PDF: ';
  static const String failedToFindParentToInsert = 'Could not find CategoryCategory to insert before';

  static String error(dynamic e) => '$errorPrefix$e';
  static String exportError(dynamic e) => '$exportFailed$e';
  static String importError(dynamic e) => '$importFailed$e';
  static String transferError(dynamic e) => '$transferFailed$e';
  static String loadError(dynamic e) => '$loadFailed$e';
  static String pdfError(dynamic e) => '$pdfFailed$e';
  static String restored(dynamic name) => 'Restored $name';
  static String trashEmptied(int count) => 'Trash emptied — $count items removed';
  static String importedCount(int count) => 'Imported $count records';
  static String transferred(dynamic amount, dynamic to) => 'Transferred $amount to $to';
  static String goalProgress(dynamic surplus) => 'Progress updated (surplus: $surplus)';
}
