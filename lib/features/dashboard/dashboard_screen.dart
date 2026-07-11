import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/models/expense_models.dart';
import '../../data/repositories/expense_repository.dart';
import '../../core/utils/icons_helper.dart';
import '../../blocs/dashboard_bloc.dart';
import '../expense/expense_form_screen.dart';
import '../expense/expense_list_screen.dart';
import '../income/income_list_screen.dart';
import '../accounts/account_detail_screen.dart';
import '../accounts/account_form_screen.dart';
import '../../blocs/currency_cubit.dart';
import '../../widgets/garden_widget.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../goals/goals_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _dailyBudgetTarget = 0;
  List<SavingsGoal> _goals = [];

  bool get _hasGoals => _goals.isNotEmpty;

  double get _goalProgress {
    if (_goals.isEmpty) return 0;
    final total = _goals.fold(0.0, (s, g) => s + g.progress);
    return (total / _goals.length) / 100;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPrefs());
  }

  Future<void> _loadPrefs() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final repo = RepositoryProvider.of<ExpenseRepository>(context);
    _goals = await repo.getGoals();
    if (mounted) {
      setState(() {
        _dailyBudgetTarget = prefs.getDouble(PrefKeys.dailyBudgetTarget) ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final summary = state.summary;
        final theme = Theme.of(context);
        final currencyFormat = context.watch<CurrencyCubit>().state.formatter;

        if (state.isLoading && summary == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final monthTotal = summary?.totalThisMonth ?? 0;
        final incomeTotal = summary?.totalIncomeThisMonth ?? 0;
        final budgetRemaining = summary?.remainingBudget ?? 0;
        final budgetTotal = budgetRemaining + monthTotal;
        final now = DateTime.now();

        return Scaffold(
          appBar: AppBar(
            title: const Text(PageTitles.dashboard),
            actions: [
              IconButton(
                icon: const Icon(Icons.attach_money),
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const IncomeListScreen(),
                )),
                tooltip: PageTitles.allIncomes,
              ),
              IconButton(
                icon: const Icon(Icons.list_alt),
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const ExpenseListScreen(),
                )),
                tooltip: PageTitles.allExpenses,
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<DashboardBloc>().add(LoadDashboard());
              await _loadPrefs();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeroHeader(
                  monthTotal: monthTotal,
                  incomeTotal: incomeTotal,
                  budgetRemaining: budgetRemaining,
                  budgetTotal: budgetTotal,
                  currencyFormat: currencyFormat,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStatCard(
                        title: UiLabels.today,
                        amount: summary?.totalToday ?? 0,
                        icon: Icons.today,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MiniStatCard(
                        title: UiLabels.thisWeek,
                        amount: summary?.totalThisWeek ?? 0,
                        icon: Icons.date_range,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MiniStatCard(
                        title: UiLabels.income,
                        amount: incomeTotal,
                        icon: Icons.trending_up,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MiniStatCard(
                        title: UiLabels.netBalance,
                        amount: incomeTotal - monthTotal,
                        icon: Icons.account_balance,
                        color: (incomeTotal - monthTotal) >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (budgetTotal > 0)
                  _BudgetSection(
                    budgetRemaining: budgetRemaining,
                    monthTotal: monthTotal,
                    budgetTotal: budgetTotal,
                    currencyFormat: currencyFormat,
                  ),
                const SizedBox(height: 12),
                GardenWidget(
                  data: GardenData(
                    growthLevel: _goalProgress,
                    showFlowers: _goals.isNotEmpty && _goalProgress > 0,
                    showBirds: _hasGoals,
                    dailyBudget: _dailyBudgetTarget > 0
                        ? _dailyBudgetTarget
                        : budgetTotal > 0
                            ? budgetTotal / DateTime(now.year, now.month + 1, 0).day
                            : 0,
                    dailySpent: summary?.totalToday ?? 0,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GoalsScreen()),
                  ),
                ),
                if (summary?.topCategory != null && summary!.topCategory != 'None') ...[
                  const SizedBox(height: 12),
                  _TopCategoryCard(
                    category: summary.topCategory,
                    amount: summary.topCategoryAmount,
                    currencyFormat: currencyFormat,
                  ),
                ],
                const SizedBox(height: 16),
                Text(UiLabels.wallets, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (state.accounts.isEmpty)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.account_balance_wallet, color: Colors.grey),
                      title: const Text('No accounts'),
                      subtitle: const Text('Add accounts in Settings'),
                    ),
                  )
                else
                  ...state.accounts.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AccountCard(account: a),
                  )),
                const SizedBox(height: 16),
                Text(UiLabels.recentExpenses, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                _RecentExpensesList(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAccountMenu(BuildContext context, AccountModel account) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text(UiLabels.edit),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AccountFormScreen(account: account),
                )).then((_) {
                  if (context.mounted) {
                    context.read<DashboardBloc>().add(LoadDashboard());
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                showDialog<bool>(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    title: const Text(UiLabels.deleteAccountTitle),
                    content: Text('Are you sure you want to delete "${account.name}"?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ).then((confirmed) {
                  if (confirmed == true && context.mounted) {
                    RepositoryProvider.of<ExpenseRepository>(context).deleteAccount(account.id);
                    context.read<DashboardBloc>().add(LoadDashboard());
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final double monthTotal;
  final double incomeTotal;
  final double budgetRemaining;
  final double budgetTotal;
  final NumberFormat currencyFormat;

  const _HeroHeader({
    required this.monthTotal,
    required this.incomeTotal,
    required this.budgetRemaining,
    required this.budgetTotal,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budgetPercent = budgetTotal > 0 ? (monthTotal / budgetTotal).clamp(0.0, 1.0) : 0.0;
    final netBalance = incomeTotal - monthTotal;
    final isSurplus = netBalance >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This Month', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(monthTotal),
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(isSurplus ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 16, color: isSurplus ? Colors.green : Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        '${isSurplus ? '+' : ''}${currencyFormat.format(netBalance)} net',
                        style: TextStyle(color: isSurplus ? Colors.green : Colors.red, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      value: budgetPercent,
                      strokeWidth: 6,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        budgetPercent > 0.9 ? Colors.red :
                        budgetPercent > 0.7 ? Colors.orange : Colors.green,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${(budgetPercent * 100).toInt()}%',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('used', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                    ],
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

class _MiniStatCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = context.watch<CurrencyCubit>().state.formatter;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              currencyFormat.format(amount),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class _BudgetSection extends StatelessWidget {
  final double budgetRemaining;
  final double monthTotal;
  final double budgetTotal;
  final NumberFormat currencyFormat;

  const _BudgetSection({
    required this.budgetRemaining,
    required this.monthTotal,
    required this.budgetTotal,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = budgetTotal > 0 ? (monthTotal / budgetTotal).clamp(0.0, 1.0) : 0.0;
    final barColor = ratio > 0.9 ? Colors.red : ratio > 0.7 ? Colors.orange : Colors.green;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(UiLabels.remainingBudget, style: theme.textTheme.bodyMedium),
                Text(currencyFormat.format(budgetRemaining),
                    style: TextStyle(fontWeight: FontWeight.bold, color: barColor)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${currencyFormat.format(monthTotal)} spent of ${currencyFormat.format(budgetTotal)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopCategoryCard extends StatelessWidget {
  final String category;
  final double amount;
  final NumberFormat currencyFormat;

  const _TopCategoryCard({
    required this.category,
    required this.amount,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.trending_up, color: Colors.orange, size: 20),
        ),
        title: const Text('Top Category'),
        subtitle: Text('$category: ${currencyFormat.format(amount)}'),
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final AccountModel account;

  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = context.watch<CurrencyCubit>().state.formatter;
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(account.color).withValues(alpha: 0.2),
          child: Icon(iconFromString(account.icon), color: Color(account.color), size: 20),
        ),
        title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currencyFormat.format(account.balance),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: account.balance >= 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AccountFormScreen(account: account),
                  )).then((_) {
                    if (context.mounted) {
                      context.read<DashboardBloc>().add(LoadDashboard());
                    }
                  });
                } else if (value == 'delete') {
                  showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: const Text(UiLabels.deleteAccountTitle),
                      content: Text('Are you sure you want to delete "${account.name}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ).then((confirmed) async {
                    if (confirmed == true && context.mounted) {
                      await RepositoryProvider.of<ExpenseRepository>(context).deleteAccount(account.id);
                      if (context.mounted) {
                        context.read<DashboardBloc>().add(LoadDashboard());
                      }
                    }
                  });
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: ListTile(
                  leading: Icon(Icons.edit, size: 20),
                  title: Text('Edit'),
                  dense: true,
                )),
                const PopupMenuItem(value: 'delete', child: ListTile(
                  leading: Icon(Icons.delete, size: 20, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                  dense: true,
                )),
              ],
            ),
          ],
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => AccountDetailScreen(account: account),
        )).then((_) {
          if (context.mounted) {
            context.read<DashboardBloc>().add(LoadDashboard());
          }
        }),
      ),
    );
  }
}

class _RecentExpensesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final recent = state.recentExpenses;
        if (recent.isEmpty) {
          return const Card(child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No expenses yet. Tap + to add one!')),
          ));
        }
        return Column(
          children: recent.map((e) => _ExpenseTile(expense: e)).toList(),
        );
      },
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final ExpenseModel expense;
  const _ExpenseTile({required this.expense});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = context.watch<CurrencyCubit>().state.formatter;
    final dateFormat = DateFormat(DateFormats.displayShort);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(expense.category?.color ?? 0xFF757575).withValues(alpha: 0.2),
          child: Icon(iconFromString(expense.category?.icon ?? 'receipt'),
              color: Color(expense.category?.color ?? 0xFF757575), size: 20),
        ),
        title: Text(expense.category?.name ?? 'Other'),
        subtitle: Text(dateFormat.format(expense.date)),
        trailing: Text(
          currencyFormat.format(expense.amount),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        onTap: () => _openEdit(context, expense),
      ),
    );
  }

  void _openEdit(BuildContext context, ExpenseModel expense) async {
    debugPrint('[Dashboard] opening edit for expense id=${expense.id}');
    await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => ExpenseFormScreen(expense: expense),
    ));
    debugPrint('[Dashboard] edit returned');
  }
}
