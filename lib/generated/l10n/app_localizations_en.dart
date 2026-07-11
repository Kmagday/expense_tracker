// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Expense Tracker';

  @override
  String get navHome => 'Home';

  @override
  String get navAnalytics => 'Analytics';

  @override
  String get navBudget => 'Budget';

  @override
  String get navInsights => 'Insights';

  @override
  String get navSettings => 'Settings';

  @override
  String get navAdd => 'Add';

  @override
  String get pageDashboard => 'Expense Tracker';

  @override
  String get pageAllExpenses => 'All Expenses';

  @override
  String get pageAllIncomes => 'All Incomes';

  @override
  String get pageAnalytics => 'Analytics';

  @override
  String get pageBudget => 'Budget';

  @override
  String get pageInsights => 'AI Insights';

  @override
  String get pageSettings => 'Settings';

  @override
  String get pageAccounts => 'Accounts';

  @override
  String get pageAddAccount => 'Add Account';

  @override
  String get pageEditAccount => 'Edit Account';

  @override
  String get pageAccountDetail => 'Account Details';

  @override
  String get pageTransfer => 'Transfer Money';

  @override
  String get pageCategories => 'Categories';

  @override
  String get pageTrash => 'Trash';

  @override
  String get pageUpcomingBills => 'Upcoming Bills';

  @override
  String get pageBackup => 'Backup & Restore';

  @override
  String get pageSavingsGoals => 'Savings Goals';

  @override
  String get pageNewGoal => 'New Savings Goal';

  @override
  String get pageImportCsv => 'Import CSV';

  @override
  String get pagePdfReport => 'PDF Report';

  @override
  String get pageAddExpense => 'Add Expense';

  @override
  String get pageEditExpense => 'Edit Expense';

  @override
  String get pageAddIncome => 'Add Income';

  @override
  String get pageEditIncome => 'Edit Income';

  @override
  String get pageSetPin => 'Set PIN';

  @override
  String get pageChangePin => 'Change PIN';

  @override
  String get pageAddCategory => 'Add Category';

  @override
  String get pageEditCategory => 'Edit Category';

  @override
  String get msgExpenseAdded => 'Expense added';

  @override
  String get msgExpenseUpdated => 'Expense updated';

  @override
  String get msgExpenseDeleted => 'Expense moved to trash';

  @override
  String get msgExpensePermDeleted => 'Expense permanently deleted';

  @override
  String get msgIncomeAdded => 'Income added';

  @override
  String get msgIncomeUpdated => 'Income updated';

  @override
  String get msgIncomeDeleted => 'Income moved to trash';

  @override
  String get msgIncomePermDeleted => 'Income permanently deleted';

  @override
  String get msgAccountCreated => 'Account created';

  @override
  String get msgAccountUpdated => 'Account updated';

  @override
  String get msgAccountDeleted => 'Account deleted';

  @override
  String get msgBudgetUpdated => 'Budget updated!';

  @override
  String get msgCategoryBudgetSet => 'Category budget set!';

  @override
  String get msgBudgetDeleted => 'Budget deleted';

  @override
  String get msgCategoryDefaultCannotDelete => 'Default categories cannot be deleted.';

  @override
  String get msgNameRequired => 'Name is required.';

  @override
  String get msgPasteCsvFirst => 'Paste CSV content first';

  @override
  String get msgEnterPassphrase => 'Enter a passphrase';

  @override
  String get msgPassphraseTooShort => 'Passphrase must be at least 4 characters';

  @override
  String get msgEnterPassphraseAndData => 'Enter passphrase and paste backup data';

  @override
  String get msgPinEnabled => 'PIN lock enabled';

  @override
  String get msgPinDisabled => 'PIN lock disabled';

  @override
  String get msgPinsDoNotMatch => 'PINs do not match';

  @override
  String get msgPinSetSuccess => 'PIN set successfully!';

  @override
  String get msgIncorrectPin => 'Incorrect PIN';

  @override
  String get msgEnterPin => 'Enter PIN';

  @override
  String get msgBiometricReason => 'Unlock Expense Tracker';

  @override
  String get msgAllDataCleared => 'All data cleared.';

  @override
  String get msgBackupExported => 'Backup exported successfully';

  @override
  String get labelToday => 'Today';

  @override
  String get labelThisWeek => 'This Week';

  @override
  String get labelThisMonth => 'This Month';

  @override
  String get labelIncome => 'Income';

  @override
  String get labelExpense => 'Expense';

  @override
  String get labelNetBalance => 'Net Balance';

  @override
  String get labelRemainingBudget => 'Remaining Budget';

  @override
  String get labelTopCategory => 'Top Category';

  @override
  String get labelWallets => 'Wallets';

  @override
  String get labelRecentExpenses => 'Recent Expenses';

  @override
  String get labelSpendingByCategory => 'Spending by Category';

  @override
  String get labelDailyTrend => 'Daily Spending Trend';

  @override
  String get labelCategoryBreakdown => 'Category Breakdown';

  @override
  String get labelOverallBudget => 'Overall Budget';

  @override
  String get labelCategoryBudgets => 'Category Budgets';

  @override
  String get labelAppearance => 'Appearance';

  @override
  String get labelData => 'Data';

  @override
  String get labelSecurity => 'Security';

  @override
  String get labelRecurring => 'Recurring';

  @override
  String get labelAiAssistant => 'AI Assistant';

  @override
  String get labelDarkMode => 'Dark Mode';

  @override
  String get labelCurrency => 'Currency';

  @override
  String get labelManageCategories => 'Manage Categories';

  @override
  String get labelManageAccounts => 'Manage Accounts';

  @override
  String get labelGeneratePdf => 'Generate PDF Report';

  @override
  String get labelExportCsv => 'Export as CSV';

  @override
  String get labelImportCsv => 'Import CSV';

  @override
  String get labelBackupRestore => 'Backup & Restore';

  @override
  String get labelPinLock => 'PIN Lock';

  @override
  String get labelChangePin => 'Change PIN';

  @override
  String get labelBiometricLock => 'Biometric Lock';

  @override
  String get labelOnDeviceAi => 'On-Device AI';

  @override
  String get labelSavingsGoals => 'Savings Goals';

  @override
  String get labelForecast => 'End-of-Month Forecast';

  @override
  String get labelAnomalies => 'Unusual Expenses Detected';

  @override
  String get labelPatterns => 'Spending Patterns';

  @override
  String get labelSuggestions => 'Saving Suggestions';

  @override
  String get labelChatAssistant => 'AI Chat Assistant';

  @override
  String get labelEdit => 'Edit';

  @override
  String get labelDelete => 'Delete';

  @override
  String get labelFilters => 'Filters';

  @override
  String get labelSearchHint => 'Search notes or categories...';

  @override
  String get labelTagHint => 'comma-separated, e.g. groceries, household';

  @override
  String get labelTagHintIncome => 'comma-separated, e.g. freelance, one-time';

  @override
  String get labelPassphrase => 'Passphrase';

  @override
  String get labelPassphraseHint => 'min 4 characters';

  @override
  String get labelRestoreFromBackup => 'Restore from backup:';

  @override
  String get labelPasteBackupHere => 'Paste backup data here';

  @override
  String get labelPasteCsvHere => 'Paste your CSV data below:';

  @override
  String get labelSelectCategory => 'Select category';

  @override
  String get labelNone => 'None';

  @override
  String get labelAccountOptional => 'Account (optional)';

  @override
  String get labelPaymentMethodOptional => 'Payment Method (optional)';

  @override
  String get labelNoteOptional => 'Note (optional)';

  @override
  String get labelSourceOptional => 'Source (optional)';

  @override
  String get labelTagsOptional => 'Tags (optional)';

  @override
  String get labelAmount => 'Amount';

  @override
  String get labelCategory => 'Category';

  @override
  String get labelDate => 'Date';

  @override
  String get labelEnabled => 'Enabled';

  @override
  String get labelDisabled => 'Disabled';

  @override
  String get labelEmptyTrash => 'Empty Trash';

  @override
  String get labelRestore => 'Restore';

  @override
  String get labelExportBackup => 'Export Encrypted Backup';

  @override
  String get labelRestoreBackup => 'Restore from Backup';

  @override
  String get labelImportBackup => 'Import Backup';

  @override
  String get labelClearAllData => 'Clear All Data';

  @override
  String get labelEditOverallBudget => 'Edit Overall Budget';

  @override
  String get labelDeleteExpense => 'Delete Expense';

  @override
  String get labelDeleteIncome => 'Delete Income';

  @override
  String get labelDeleteCategory => 'Delete Category';

  @override
  String get labelDeleteAccount => 'Delete Account';

  @override
  String get labelDeleteGoal => 'Delete Goal';

  @override
  String get labelDeleteBudget => 'Delete Budget';

  @override
  String get labelNoAccountFound => 'No accounts. Add one in Settings.';

  @override
  String get btnSave => 'Save';

  @override
  String get btnCancel => 'Cancel';

  @override
  String get btnDelete => 'Delete';

  @override
  String get btnDeleteForever => 'Delete Forever';

  @override
  String get btnUpdate => 'Update';

  @override
  String get btnAdd => 'Add';

  @override
  String get btnNext => 'Next';

  @override
  String get btnGetStarted => 'Get Started';

  @override
  String get btnSkip => 'Skip';

  @override
  String get btnReset => 'Reset';

  @override
  String get btnApply => 'Apply';

  @override
  String get btnUndo => 'Undo';

  @override
  String get btnImport => 'Import';

  @override
  String get btnImporting => 'Importing...';

  @override
  String get btnExport => 'Export';

  @override
  String get btnOk => 'OK';

  @override
  String get btnSetPin => 'Set PIN';

  @override
  String get btnChangePin => 'Change PIN';

  @override
  String get titleAreYouSure => 'Are you sure?';

  @override
  String get titleEmptyTrash => 'Empty Trash?';

  @override
  String get titlePermanentlyDelete => 'Permanently Delete?';

  @override
  String get titleClearAllData => 'Clear All Data';

  @override
  String get descAcc => 'Add, edit, or transfer between accounts';

  @override
  String get descCsv => 'Import expenses from a CSV file';

  @override
  String get descBackup => 'Encrypted backup for device migration';

  @override
  String get descTrash => 'View and restore deleted items';

  @override
  String get descRecurring => 'View and manage recurring bills';

  @override
  String get descAi => 'Works offline. No setup needed.';

  @override
  String get descGoal => 'Track savings toward a target';

  @override
  String get backupPrivacy => 'Your data stays on-device. Use an encrypted backup to move between devices.';

  @override
  String get restoreWarning => 'This will replace ALL current data. Continue?';

  @override
  String get clearDataWarning => 'This will permanently delete all expenses, incomes, budgets, and custom categories. Continue?';

  @override
  String get csvExample => '2024-01-15,42.50,Groceries,Food\n01/15/2024,12.00,Coffee,Food';

  @override
  String get chatHint => 'Ask about your finances...';

  @override
  String get chatEmpty => 'Ask questions about your spending in natural language.\nExample: \"How much did I spend on food last week?\"';

  @override
  String get chatThinking => 'Thinking...';

  @override
  String get noExpenses => 'No expenses yet. Tap + to add one!';

  @override
  String get noIncomes => 'No incomes yet.';

  @override
  String get noAccounts => 'No accounts';

  @override
  String get trashEmpty => 'Trash is empty';

  @override
  String get trashRetention => 'Deleted items appear here for 30 days';

  @override
  String get budget => 'Budget';

  @override
  String get spent => 'Spent';

  @override
  String get remaining => 'Remaining';

  @override
  String get subscriptions => 'Detected Subscriptions';

  @override
  String get recurringFixed => 'Recurring (fixed)';

  @override
  String get variableProjected => 'Variable (projected)';

  @override
  String get forecastProjected => 'Projected';

  @override
  String get spentSoFar => 'Spent so far';

  @override
  String dayOf(int day, int total) {
    return 'Day $day of $total';
  }

  @override
  String categoryBudgetBased(int count) {
    return 'Based on $count category budget | Based on $count category budgets';
  }

  @override
  String trashEmptied(int count) {
    return 'Trash emptied — $count items removed';
  }

  @override
  String importedRecords(int count) {
    return 'Imported $count records';
  }

  @override
  String moreSubscriptions(int count) {
    return '+ $count more';
  }
}
