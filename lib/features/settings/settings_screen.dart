import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../data/repositories/expense_repository.dart';
import '../../blocs/theme_cubit.dart';
import '../../blocs/currency_cubit.dart';
import '../../blocs/auth_cubit.dart';
import '../../blocs/expense_bloc.dart';
import '../trash/trash_screen.dart';
import '../recurring/upcoming_bills_screen.dart';
import '../import/csv_import_screen.dart';
import '../daily_budget/daily_budget_screen.dart';
import '../backup/backup_screen.dart';
import '../goals/goals_screen.dart';
import '../accounts/accounts_screen.dart';
import '../../blocs/income_bloc.dart';
import '../../blocs/budget_bloc.dart';
import '../../blocs/dashboard_bloc.dart';
import '../../blocs/ai_bloc.dart';
import '../auth/pin_set_screen.dart';
import '../categories/category_list_screen.dart';
import '../reports/pdf_report_screen.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Appearance', style: theme.textTheme.titleSmall),
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Theme', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 12),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto)),
                          ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
                          ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
                        ],
                        selected: {themeMode},
                        onSelectionChanged: (v) => context.read<ThemeCubit>().setTheme(v.first),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          BlocBuilder<CurrencyCubit, CurrencyState>(
            builder: (context, currency) {
              final currencies = CurrencyCubit.currencies;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Currency'),
                  subtitle: Text('${currency.symbol} ${currency.code}'),
                  trailing: DropdownButton<String>(
                    value: currency.code,
                    underline: const SizedBox(),
                    items: currencies.keys.map((code) => DropdownMenuItem(
                      value: code,
                      child: Text('${currencies[code]} $code'),
                    )).toList(),
                    onChanged: (v) {
                      if (v != null) context.read<CurrencyCubit>().setCurrency(v);
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text('Data', style: theme.textTheme.titleSmall),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.category),
                  title: const Text(UiLabels.manageCategories),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const CategoryListScreen(),
                  )),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet),
                  title: const Text(UiLabels.manageAccounts),
                  subtitle: const Text(UiLabels.accDesc),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const AccountsScreen(),
                  )),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: const Text(UiLabels.generatePdf),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const PdfReportScreen(),
                  )),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_download),
                  title: const Text(UiLabels.exportCsv),
                  onTap: () => _exportCSV(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_upload),
                  title: const Text(PageTitles.importCsv),
                  subtitle: const Text(UiLabels.csvDesc),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const CsvImportScreen(),
                  )),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text(PageTitles.backup),
                  subtitle: const Text(UiLabels.backupDesc),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const BackupScreen(),
                  )),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_sweep),
                  title: const Text('Trash'),
                  subtitle: const Text(UiLabels.trashDesc),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrashScreen())),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text(UiLabels.clearAllData, style: TextStyle(color: Colors.red)),
                  onTap: () => _clearData(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Security', style: theme.textTheme.titleSmall),
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              return Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('PIN Lock'),
                      subtitle: Text(authState.pinEnabled ? 'Enabled' : 'Disabled'),
                      value: authState.pinEnabled,
                      onChanged: (v) async {
                        if (v) {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(builder: (_) => const PinSetScreen()),
                          );
                          if (result == true && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text(AppMessages.pinEnabled)),
                            );
                          }
                        } else {
                          await context.read<AuthCubit>().removePin();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text(AppMessages.pinDisabled)),
                            );
                          }
                        }
                      },
                    ),
                    if (authState.pinEnabled) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.change_circle),
                        title: const Text(PageTitles.changePin),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PinSetScreen(isChange: true)),
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text(UiLabels.biometricLock),
                        subtitle: Text(authState.biometricEnabled ? 'Enabled' : 'Disabled'),
                        value: authState.biometricEnabled,
                        onChanged: (v) {
                          context.read<AuthCubit>().toggleBiometric(v);
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text('Recurring', style: theme.textTheme.titleSmall),
          Card(
            child: ListTile(
              leading: const Icon(Icons.repeat),
              title: const Text(PageTitles.upcomingBills),
              subtitle: const Text(UiLabels.recurringDesc),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const UpcomingBillsScreen(),
              )),
            ),
          ),
          const SizedBox(height: 16),
          Text('Budget', style: theme.textTheme.titleSmall),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Daily Budget'),
              subtitle: const Text('Set and track your daily spending target'),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const DailyBudgetScreen(),
              )),
            ),
          ),
          const SizedBox(height: 16),
          Text('AI Assistant', style: theme.textTheme.titleSmall),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green[600]),
                  title: const Text(UiLabels.onDeviceAi),
                  subtitle: const Text(UiLabels.aiDesc),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.savings),
                  title: const Text(PageTitles.savingsGoals),
                  subtitle: const Text(UiLabels.goalDesc),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const GoalsScreen(),
                  )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(AppMeta.version,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCSV(BuildContext context) async {
    try {
      final repo = RepositoryProvider.of<ExpenseRepository>(context);
      final expenses = await repo.getExpenses();
      debugPrint('[Settings] exporting ${expenses.length} expenses to CSV');
      if (expenses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppMessages.noExpenses)),
        );
        return;
      }

      final rows = <List<String>>[
        ['Date', 'Amount', 'Category', 'Note', 'Payment Method'],
        ...expenses.map((e) => [
          DateFormat(DateFormats.csv).format(e.date),
          e.amount.toStringAsFixed(2),
          e.category?.name ?? 'Other',
          e.note ?? '',
          e.paymentMethod ?? '',
        ]),
      ];

      final csvData = const ListToCsvConverter().convert(rows);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${AppFiles.csvPrefix}${DateFormat('yyyyMMdd').format(DateTime.now())}.csv');
      await file.writeAsString(csvData);
      debugPrint('[Settings] CSV exported to ${file.path}');
      await Share.shareXFiles([XFile(file.path)], text: 'My ${AppFiles.pdfShareText}');
    } catch (e) {
      debugPrint('[Settings] CSV export error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMessages.exportError(e))),
      );
    }
  }

  void _clearData(BuildContext context) async {
    debugPrint('[Settings] clear data requested');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(UiLabels.clearAllData),
        content: const Text(UiLabels.clearDataWarning),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(UiLabels.clearAllData, style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    debugPrint('[Settings] clear data confirmed: $confirm');
    if (confirm == true) {
      if (!context.mounted) return;
      RepositoryProvider.of<ExpenseRepository>(context).clearAllData();
      context.read<ExpenseBloc>().add(LoadExpenses());
      context.read<IncomeBloc>().add(LoadIncomes());
      context.read<BudgetBloc>().add(LoadBudgets());
      context.read<DashboardBloc>().add(LoadDashboard());
      context.read<AIBloc>().add(LoadAIInsights());
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppMessages.allDataCleared)),
      );
    }
  }
}
