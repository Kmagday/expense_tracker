import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Expense Tracker'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get navAnalytics;

  /// No description provided for @navBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get navBudget;

  /// No description provided for @navInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get navInsights;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get navAdd;

  /// No description provided for @pageDashboard.
  ///
  /// In en, this message translates to:
  /// **'Expense Tracker'**
  String get pageDashboard;

  /// No description provided for @pageAllExpenses.
  ///
  /// In en, this message translates to:
  /// **'All Expenses'**
  String get pageAllExpenses;

  /// No description provided for @pageAllIncomes.
  ///
  /// In en, this message translates to:
  /// **'All Incomes'**
  String get pageAllIncomes;

  /// No description provided for @pageAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get pageAnalytics;

  /// No description provided for @pageBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get pageBudget;

  /// No description provided for @pageInsights.
  ///
  /// In en, this message translates to:
  /// **'AI Insights'**
  String get pageInsights;

  /// No description provided for @pageSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get pageSettings;

  /// No description provided for @pageAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get pageAccounts;

  /// No description provided for @pageAddAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get pageAddAccount;

  /// No description provided for @pageEditAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit Account'**
  String get pageEditAccount;

  /// No description provided for @pageAccountDetail.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get pageAccountDetail;

  /// No description provided for @pageTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer Money'**
  String get pageTransfer;

  /// No description provided for @pageCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get pageCategories;

  /// No description provided for @pageTrash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get pageTrash;

  /// No description provided for @pageUpcomingBills.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Bills'**
  String get pageUpcomingBills;

  /// No description provided for @pageBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get pageBackup;

  /// No description provided for @pageSavingsGoals.
  ///
  /// In en, this message translates to:
  /// **'Savings Goals'**
  String get pageSavingsGoals;

  /// No description provided for @pageNewGoal.
  ///
  /// In en, this message translates to:
  /// **'New Savings Goal'**
  String get pageNewGoal;

  /// No description provided for @pageImportCsv.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get pageImportCsv;

  /// No description provided for @pagePdfReport.
  ///
  /// In en, this message translates to:
  /// **'PDF Report'**
  String get pagePdfReport;

  /// No description provided for @pageAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get pageAddExpense;

  /// No description provided for @pageEditExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense'**
  String get pageEditExpense;

  /// No description provided for @pageAddIncome.
  ///
  /// In en, this message translates to:
  /// **'Add Income'**
  String get pageAddIncome;

  /// No description provided for @pageEditIncome.
  ///
  /// In en, this message translates to:
  /// **'Edit Income'**
  String get pageEditIncome;

  /// No description provided for @pageSetPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get pageSetPin;

  /// No description provided for @pageChangePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get pageChangePin;

  /// No description provided for @pageAddCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get pageAddCategory;

  /// No description provided for @pageEditCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get pageEditCategory;

  /// No description provided for @msgExpenseAdded.
  ///
  /// In en, this message translates to:
  /// **'Expense added'**
  String get msgExpenseAdded;

  /// No description provided for @msgExpenseUpdated.
  ///
  /// In en, this message translates to:
  /// **'Expense updated'**
  String get msgExpenseUpdated;

  /// No description provided for @msgExpenseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Expense moved to trash'**
  String get msgExpenseDeleted;

  /// No description provided for @msgExpensePermDeleted.
  ///
  /// In en, this message translates to:
  /// **'Expense permanently deleted'**
  String get msgExpensePermDeleted;

  /// No description provided for @msgIncomeAdded.
  ///
  /// In en, this message translates to:
  /// **'Income added'**
  String get msgIncomeAdded;

  /// No description provided for @msgIncomeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Income updated'**
  String get msgIncomeUpdated;

  /// No description provided for @msgIncomeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Income moved to trash'**
  String get msgIncomeDeleted;

  /// No description provided for @msgIncomePermDeleted.
  ///
  /// In en, this message translates to:
  /// **'Income permanently deleted'**
  String get msgIncomePermDeleted;

  /// No description provided for @msgAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get msgAccountCreated;

  /// No description provided for @msgAccountUpdated.
  ///
  /// In en, this message translates to:
  /// **'Account updated'**
  String get msgAccountUpdated;

  /// No description provided for @msgAccountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get msgAccountDeleted;

  /// No description provided for @msgBudgetUpdated.
  ///
  /// In en, this message translates to:
  /// **'Budget updated!'**
  String get msgBudgetUpdated;

  /// No description provided for @msgCategoryBudgetSet.
  ///
  /// In en, this message translates to:
  /// **'Category budget set!'**
  String get msgCategoryBudgetSet;

  /// No description provided for @msgBudgetDeleted.
  ///
  /// In en, this message translates to:
  /// **'Budget deleted'**
  String get msgBudgetDeleted;

  /// No description provided for @msgCategoryDefaultCannotDelete.
  ///
  /// In en, this message translates to:
  /// **'Default categories cannot be deleted.'**
  String get msgCategoryDefaultCannotDelete;

  /// No description provided for @msgNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get msgNameRequired;

  /// No description provided for @msgPasteCsvFirst.
  ///
  /// In en, this message translates to:
  /// **'Paste CSV content first'**
  String get msgPasteCsvFirst;

  /// No description provided for @msgEnterPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Enter a passphrase'**
  String get msgEnterPassphrase;

  /// No description provided for @msgPassphraseTooShort.
  ///
  /// In en, this message translates to:
  /// **'Passphrase must be at least 4 characters'**
  String get msgPassphraseTooShort;

  /// No description provided for @msgEnterPassphraseAndData.
  ///
  /// In en, this message translates to:
  /// **'Enter passphrase and paste backup data'**
  String get msgEnterPassphraseAndData;

  /// No description provided for @msgPinEnabled.
  ///
  /// In en, this message translates to:
  /// **'PIN lock enabled'**
  String get msgPinEnabled;

  /// No description provided for @msgPinDisabled.
  ///
  /// In en, this message translates to:
  /// **'PIN lock disabled'**
  String get msgPinDisabled;

  /// No description provided for @msgPinsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get msgPinsDoNotMatch;

  /// No description provided for @msgPinSetSuccess.
  ///
  /// In en, this message translates to:
  /// **'PIN set successfully!'**
  String get msgPinSetSuccess;

  /// No description provided for @msgIncorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get msgIncorrectPin;

  /// No description provided for @msgEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get msgEnterPin;

  /// No description provided for @msgBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Expense Tracker'**
  String get msgBiometricReason;

  /// No description provided for @msgAllDataCleared.
  ///
  /// In en, this message translates to:
  /// **'All data cleared.'**
  String get msgAllDataCleared;

  /// No description provided for @msgBackupExported.
  ///
  /// In en, this message translates to:
  /// **'Backup exported successfully'**
  String get msgBackupExported;

  /// No description provided for @labelToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get labelToday;

  /// No description provided for @labelThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get labelThisWeek;

  /// No description provided for @labelThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get labelThisMonth;

  /// No description provided for @labelIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get labelIncome;

  /// No description provided for @labelExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get labelExpense;

  /// No description provided for @labelNetBalance.
  ///
  /// In en, this message translates to:
  /// **'Net Balance'**
  String get labelNetBalance;

  /// No description provided for @labelRemainingBudget.
  ///
  /// In en, this message translates to:
  /// **'Remaining Budget'**
  String get labelRemainingBudget;

  /// No description provided for @labelTopCategory.
  ///
  /// In en, this message translates to:
  /// **'Top Category'**
  String get labelTopCategory;

  /// No description provided for @labelWallets.
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get labelWallets;

  /// No description provided for @labelRecentExpenses.
  ///
  /// In en, this message translates to:
  /// **'Recent Expenses'**
  String get labelRecentExpenses;

  /// No description provided for @labelSpendingByCategory.
  ///
  /// In en, this message translates to:
  /// **'Spending by Category'**
  String get labelSpendingByCategory;

  /// No description provided for @labelDailyTrend.
  ///
  /// In en, this message translates to:
  /// **'Daily Spending Trend'**
  String get labelDailyTrend;

  /// No description provided for @labelCategoryBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Category Breakdown'**
  String get labelCategoryBreakdown;

  /// No description provided for @labelOverallBudget.
  ///
  /// In en, this message translates to:
  /// **'Overall Budget'**
  String get labelOverallBudget;

  /// No description provided for @labelCategoryBudgets.
  ///
  /// In en, this message translates to:
  /// **'Category Budgets'**
  String get labelCategoryBudgets;

  /// No description provided for @labelAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get labelAppearance;

  /// No description provided for @labelData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get labelData;

  /// No description provided for @labelSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get labelSecurity;

  /// No description provided for @labelRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get labelRecurring;

  /// No description provided for @labelAiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get labelAiAssistant;

  /// No description provided for @labelDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get labelDarkMode;

  /// No description provided for @labelCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get labelCurrency;

  /// No description provided for @labelManageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get labelManageCategories;

  /// No description provided for @labelManageAccounts.
  ///
  /// In en, this message translates to:
  /// **'Manage Accounts'**
  String get labelManageAccounts;

  /// No description provided for @labelGeneratePdf.
  ///
  /// In en, this message translates to:
  /// **'Generate PDF Report'**
  String get labelGeneratePdf;

  /// No description provided for @labelExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export as CSV'**
  String get labelExportCsv;

  /// No description provided for @labelImportCsv.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get labelImportCsv;

  /// No description provided for @labelBackupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get labelBackupRestore;

  /// No description provided for @labelPinLock.
  ///
  /// In en, this message translates to:
  /// **'PIN Lock'**
  String get labelPinLock;

  /// No description provided for @labelChangePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get labelChangePin;

  /// No description provided for @labelBiometricLock.
  ///
  /// In en, this message translates to:
  /// **'Biometric Lock'**
  String get labelBiometricLock;

  /// No description provided for @labelOnDeviceAi.
  ///
  /// In en, this message translates to:
  /// **'On-Device AI'**
  String get labelOnDeviceAi;

  /// No description provided for @labelSavingsGoals.
  ///
  /// In en, this message translates to:
  /// **'Savings Goals'**
  String get labelSavingsGoals;

  /// No description provided for @labelForecast.
  ///
  /// In en, this message translates to:
  /// **'End-of-Month Forecast'**
  String get labelForecast;

  /// No description provided for @labelAnomalies.
  ///
  /// In en, this message translates to:
  /// **'Unusual Expenses Detected'**
  String get labelAnomalies;

  /// No description provided for @labelPatterns.
  ///
  /// In en, this message translates to:
  /// **'Spending Patterns'**
  String get labelPatterns;

  /// No description provided for @labelSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Saving Suggestions'**
  String get labelSuggestions;

  /// No description provided for @labelChatAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Chat Assistant'**
  String get labelChatAssistant;

  /// No description provided for @labelEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get labelEdit;

  /// No description provided for @labelDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get labelDelete;

  /// No description provided for @labelFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get labelFilters;

  /// No description provided for @labelSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search notes or categories...'**
  String get labelSearchHint;

  /// No description provided for @labelTagHint.
  ///
  /// In en, this message translates to:
  /// **'comma-separated, e.g. groceries, household'**
  String get labelTagHint;

  /// No description provided for @labelTagHintIncome.
  ///
  /// In en, this message translates to:
  /// **'comma-separated, e.g. freelance, one-time'**
  String get labelTagHintIncome;

  /// No description provided for @labelPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get labelPassphrase;

  /// No description provided for @labelPassphraseHint.
  ///
  /// In en, this message translates to:
  /// **'min 4 characters'**
  String get labelPassphraseHint;

  /// No description provided for @labelRestoreFromBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup:'**
  String get labelRestoreFromBackup;

  /// No description provided for @labelPasteBackupHere.
  ///
  /// In en, this message translates to:
  /// **'Paste backup data here'**
  String get labelPasteBackupHere;

  /// No description provided for @labelPasteCsvHere.
  ///
  /// In en, this message translates to:
  /// **'Paste your CSV data below:'**
  String get labelPasteCsvHere;

  /// No description provided for @labelSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get labelSelectCategory;

  /// No description provided for @labelNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get labelNone;

  /// No description provided for @labelAccountOptional.
  ///
  /// In en, this message translates to:
  /// **'Account (optional)'**
  String get labelAccountOptional;

  /// No description provided for @labelPaymentMethodOptional.
  ///
  /// In en, this message translates to:
  /// **'Payment Method (optional)'**
  String get labelPaymentMethodOptional;

  /// No description provided for @labelNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get labelNoteOptional;

  /// No description provided for @labelSourceOptional.
  ///
  /// In en, this message translates to:
  /// **'Source (optional)'**
  String get labelSourceOptional;

  /// No description provided for @labelTagsOptional.
  ///
  /// In en, this message translates to:
  /// **'Tags (optional)'**
  String get labelTagsOptional;

  /// No description provided for @labelAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get labelAmount;

  /// No description provided for @labelCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get labelCategory;

  /// No description provided for @labelDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get labelDate;

  /// No description provided for @labelEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get labelEnabled;

  /// No description provided for @labelDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get labelDisabled;

  /// No description provided for @labelEmptyTrash.
  ///
  /// In en, this message translates to:
  /// **'Empty Trash'**
  String get labelEmptyTrash;

  /// No description provided for @labelRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get labelRestore;

  /// No description provided for @labelExportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export Encrypted Backup'**
  String get labelExportBackup;

  /// No description provided for @labelRestoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from Backup'**
  String get labelRestoreBackup;

  /// No description provided for @labelImportBackup.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get labelImportBackup;

  /// No description provided for @labelClearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get labelClearAllData;

  /// No description provided for @labelEditOverallBudget.
  ///
  /// In en, this message translates to:
  /// **'Edit Overall Budget'**
  String get labelEditOverallBudget;

  /// No description provided for @labelDeleteExpense.
  ///
  /// In en, this message translates to:
  /// **'Delete Expense'**
  String get labelDeleteExpense;

  /// No description provided for @labelDeleteIncome.
  ///
  /// In en, this message translates to:
  /// **'Delete Income'**
  String get labelDeleteIncome;

  /// No description provided for @labelDeleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get labelDeleteCategory;

  /// No description provided for @labelDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get labelDeleteAccount;

  /// No description provided for @labelDeleteGoal.
  ///
  /// In en, this message translates to:
  /// **'Delete Goal'**
  String get labelDeleteGoal;

  /// No description provided for @labelDeleteBudget.
  ///
  /// In en, this message translates to:
  /// **'Delete Budget'**
  String get labelDeleteBudget;

  /// No description provided for @labelNoAccountFound.
  ///
  /// In en, this message translates to:
  /// **'No accounts. Add one in Settings.'**
  String get labelNoAccountFound;

  /// No description provided for @btnSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get btnSave;

  /// No description provided for @btnCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get btnCancel;

  /// No description provided for @btnDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get btnDelete;

  /// No description provided for @btnDeleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete Forever'**
  String get btnDeleteForever;

  /// No description provided for @btnUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get btnUpdate;

  /// No description provided for @btnAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get btnAdd;

  /// No description provided for @btnNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get btnNext;

  /// No description provided for @btnGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get btnGetStarted;

  /// No description provided for @btnSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get btnSkip;

  /// No description provided for @btnReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get btnReset;

  /// No description provided for @btnApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get btnApply;

  /// No description provided for @btnUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get btnUndo;

  /// No description provided for @btnImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get btnImport;

  /// No description provided for @btnImporting.
  ///
  /// In en, this message translates to:
  /// **'Importing...'**
  String get btnImporting;

  /// No description provided for @btnExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get btnExport;

  /// No description provided for @btnOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get btnOk;

  /// No description provided for @btnSetPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get btnSetPin;

  /// No description provided for @btnChangePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get btnChangePin;

  /// No description provided for @titleAreYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get titleAreYouSure;

  /// No description provided for @titleEmptyTrash.
  ///
  /// In en, this message translates to:
  /// **'Empty Trash?'**
  String get titleEmptyTrash;

  /// No description provided for @titlePermanentlyDelete.
  ///
  /// In en, this message translates to:
  /// **'Permanently Delete?'**
  String get titlePermanentlyDelete;

  /// No description provided for @titleClearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get titleClearAllData;

  /// No description provided for @descAcc.
  ///
  /// In en, this message translates to:
  /// **'Add, edit, or transfer between accounts'**
  String get descAcc;

  /// No description provided for @descCsv.
  ///
  /// In en, this message translates to:
  /// **'Import expenses from a CSV file'**
  String get descCsv;

  /// No description provided for @descBackup.
  ///
  /// In en, this message translates to:
  /// **'Encrypted backup for device migration'**
  String get descBackup;

  /// No description provided for @descTrash.
  ///
  /// In en, this message translates to:
  /// **'View and restore deleted items'**
  String get descTrash;

  /// No description provided for @descRecurring.
  ///
  /// In en, this message translates to:
  /// **'View and manage recurring bills'**
  String get descRecurring;

  /// No description provided for @descAi.
  ///
  /// In en, this message translates to:
  /// **'Works offline. No setup needed.'**
  String get descAi;

  /// No description provided for @descGoal.
  ///
  /// In en, this message translates to:
  /// **'Track savings toward a target'**
  String get descGoal;

  /// No description provided for @backupPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Your data stays on-device. Use an encrypted backup to move between devices.'**
  String get backupPrivacy;

  /// No description provided for @restoreWarning.
  ///
  /// In en, this message translates to:
  /// **'This will replace ALL current data. Continue?'**
  String get restoreWarning;

  /// No description provided for @clearDataWarning.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all expenses, incomes, budgets, and custom categories. Continue?'**
  String get clearDataWarning;

  /// No description provided for @csvExample.
  ///
  /// In en, this message translates to:
  /// **'2024-01-15,42.50,Groceries,Food\n01/15/2024,12.00,Coffee,Food'**
  String get csvExample;

  /// No description provided for @chatHint.
  ///
  /// In en, this message translates to:
  /// **'Ask about your finances...'**
  String get chatHint;

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'Ask questions about your spending in natural language.\nExample: \"How much did I spend on food last week?\"'**
  String get chatEmpty;

  /// No description provided for @chatThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking...'**
  String get chatThinking;

  /// No description provided for @noExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet. Tap + to add one!'**
  String get noExpenses;

  /// No description provided for @noIncomes.
  ///
  /// In en, this message translates to:
  /// **'No incomes yet.'**
  String get noIncomes;

  /// No description provided for @noAccounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts'**
  String get noAccounts;

  /// No description provided for @trashEmpty.
  ///
  /// In en, this message translates to:
  /// **'Trash is empty'**
  String get trashEmpty;

  /// No description provided for @trashRetention.
  ///
  /// In en, this message translates to:
  /// **'Deleted items appear here for 30 days'**
  String get trashRetention;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @spent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spent;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Detected Subscriptions'**
  String get subscriptions;

  /// No description provided for @recurringFixed.
  ///
  /// In en, this message translates to:
  /// **'Recurring (fixed)'**
  String get recurringFixed;

  /// No description provided for @variableProjected.
  ///
  /// In en, this message translates to:
  /// **'Variable (projected)'**
  String get variableProjected;

  /// No description provided for @forecastProjected.
  ///
  /// In en, this message translates to:
  /// **'Projected'**
  String get forecastProjected;

  /// No description provided for @spentSoFar.
  ///
  /// In en, this message translates to:
  /// **'Spent so far'**
  String get spentSoFar;

  /// No description provided for @dayOf.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of {total}'**
  String dayOf(int day, int total);

  /// No description provided for @categoryBudgetBased.
  ///
  /// In en, this message translates to:
  /// **'Based on {count} category budget | Based on {count} category budgets'**
  String categoryBudgetBased(int count);

  /// No description provided for @trashEmptied.
  ///
  /// In en, this message translates to:
  /// **'Trash emptied — {count} items removed'**
  String trashEmptied(int count);

  /// No description provided for @importedRecords.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} records'**
  String importedRecords(int count);

  /// No description provided for @moreSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'+ {count} more'**
  String moreSubscriptions(int count);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
