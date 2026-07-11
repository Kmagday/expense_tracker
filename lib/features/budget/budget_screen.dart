import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/models/expense_models.dart';
import '../../blocs/budget_bloc.dart';
import '../../core/utils/icons_helper.dart';
import '../../blocs/currency_cubit.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  void _prevMonth() {
    final state = context.read<BudgetBloc>().state;
    final m = state.selectedMonth > 0 ? state.selectedMonth : DateTime.now().month;
    final y = state.selectedYear > 0 ? state.selectedYear : DateTime.now().year;
    if (m == 1) {
      context.read<BudgetBloc>().add(ChangeBudgetMonth(month: 12, year: y - 1));
    } else {
      context.read<BudgetBloc>().add(ChangeBudgetMonth(month: m - 1, year: y));
    }
  }

  void _nextMonth() {
    final state = context.read<BudgetBloc>().state;
    final m = state.selectedMonth > 0 ? state.selectedMonth : DateTime.now().month;
    final y = state.selectedYear > 0 ? state.selectedYear : DateTime.now().year;
    if (m == 12) {
      context.read<BudgetBloc>().add(ChangeBudgetMonth(month: 1, year: y + 1));
    } else {
      context.read<BudgetBloc>().add(ChangeBudgetMonth(month: m + 1, year: y));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetBloc, BudgetState>(
      builder: (context, state) {
        final budgets = state.budgets;
        final theme = Theme.of(context);
        final cubit = context.watch<CurrencyCubit>();
        final currencyFormat = cubit.state.formatter;
        final displayMonth = state.selectedMonth > 0 ? state.selectedMonth : DateTime.now().month;
        final displayYear = state.selectedYear > 0 ? state.selectedYear : DateTime.now().year;
        final now = DateTime.now();
        final isCurrentMonth = displayMonth == now.month && displayYear == now.year;

        final catBudgets = budgets.where((b) => b.categoryId != null).toList();
        final overallBudget = budgets.where((b) => b.categoryId == null).fold(0.0, (s, b) => s + b.budgetAmount);
        final overallSpent = catBudgets.fold(0.0, (s, b) => s + b.spentAmount);
        final overallRemaining = overallBudget - overallSpent;
        final overallPct = overallBudget > 0 ? overallSpent / overallBudget : 0.0;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _prevMonth,
                ),
                Text(DateFormat.yMMM().format(DateTime(displayYear, displayMonth))),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: isCurrentMonth ? null : _nextMonth,
                ),
              ],
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<BudgetBloc>().add(LoadBudgets());
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(UiLabels.overallBudget, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(currencyFormat.format(overallBudget),
                                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text('Spent: ${currencyFormat.format(overallSpent)}',
                                      style: theme.textTheme.bodySmall),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    'Remaining: ${currencyFormat.format(overallRemaining)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: overallRemaining >= 0 ? Colors.green : Colors.red,
                                      fontSize: 13,
                                    ),
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
                                width: 72, height: 72,
                                child: CircularProgressIndicator(
                                  value: overallPct.clamp(0.0, 1.0),
                                  strokeWidth: 6,
                                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation(
                                    overallPct > 0.9 ? Colors.red :
                                    overallPct > 0.7 ? Colors.orange : Colors.green,
                                  ),
                                ),
                              ),
                              Text('${(overallPct * 100).toInt()}%',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(UiLabels.categoryBudgets, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (catBudgets.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('No category budgets set',
                                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text('Set a budget for each spending category',
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...catBudgets.map((b) => _CategoryBudgetCard(
                    budget: b,
                    currencyFormat: currencyFormat,
                    onDelete: () {
                      context.read<BudgetBloc>().add(DeleteBudgetEvent(b.id));
                    },
                  )),
                const SizedBox(height: 16),
                _SetCategoryBudgetWidget(currencyFormat: currencyFormat),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CategoryBudgetCard extends StatelessWidget {
  final BudgetModel budget;
  final NumberFormat currencyFormat;
  final VoidCallback onDelete;

  const _CategoryBudgetCard({
    required this.budget,
    required this.currencyFormat,
    required this.onDelete,
  });

  void _edit(BuildContext context) {
    final ctl = TextEditingController(text: budget.budgetAmount.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${budget.category?.name ?? 'Overall'} Budget'),
        content: TextField(
          controller: ctl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Budget amount', prefixText: '${context.read<CurrencyCubit>().state.symbol} '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            final amount = double.tryParse(ctl.text);
            if (amount == null || amount <= 0) return;
            debugPrint('[BudgetScreen] editing budget id=${budget.id}, new amount: \$$amount');
            final now = DateTime.now();
            context.read<BudgetBloc>().add(SetBudgetEvent(
              categoryId: budget.categoryId,
              month: now.month,
              year: now.year,
              amount: amount,
            ));
            Navigator.pop(ctx);
          }, child: const Text('Save')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pct = budget.percentage;
    final barColor = pct > 90 ? Colors.red : pct > 75 ? Colors.orange : Colors.green;

    return Dismissible(
      key: ValueKey('budget_${budget.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(UiLabels.deleteBudgetTitle),
            content: Text('Delete ${budget.category?.name ?? 'this'} budget?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _edit(context),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (budget.category != null) ...[
                      Icon(iconFromString(budget.category!.icon), size: 18, color: Color(budget.category!.color)),
                      const SizedBox(width: 8),
                    ],
                    Text(budget.category?.name ?? 'Overall', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Icon(Icons.edit, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(currencyFormat.format(budget.budgetAmount)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: budget.budgetAmount > 0 ? budget.spentAmount / budget.budgetAmount : 0,
                    minHeight: 8,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    color: barColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${budget.percentage.toStringAsFixed(0)}% used — ${currencyFormat.format(budget.remaining)} remaining',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetCategoryBudgetWidget extends StatefulWidget {
  final NumberFormat currencyFormat;
  const _SetCategoryBudgetWidget({required this.currencyFormat});

  @override
  State<_SetCategoryBudgetWidget> createState() => _SetCategoryBudgetWidgetState();
}

class _SetCategoryBudgetWidgetState extends State<_SetCategoryBudgetWidget> {
  int? _selectedCategoryId;
  final _amountCtl = TextEditingController();

  @override
  void dispose() {
    _amountCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.read<BudgetBloc>().state.categories;
    final symbol = context.read<CurrencyCubit>().state.symbol;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set Category Budget', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: categories.map((c) => DropdownMenuItem(
                value: c.id,
                child: Row(children: [
                  Icon(iconFromString(c.icon), size: 18, color: Color(c.color)),
                  const SizedBox(width: 8),
                  Text(c.name),
                ]),
              )).toList(),
              onChanged: (v) => setState(() => _selectedCategoryId = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountCtl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Budget amount',
                      prefixText: '$symbol ',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _set,
                  child: const Text('Set'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _set() {
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a category first')),
      );
      return;
    }
    final amount = double.tryParse(_amountCtl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    final state = context.read<BudgetBloc>().state;
    final month = state.selectedMonth > 0 ? state.selectedMonth : DateTime.now().month;
    final year = state.selectedYear > 0 ? state.selectedYear : DateTime.now().year;
    context.read<BudgetBloc>().add(SetBudgetEvent(
      categoryId: _selectedCategoryId, month: month, year: year, amount: amount,
    ));
    _amountCtl.clear();
    setState(() => _selectedCategoryId = null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppMessages.categoryBudgetSet)),
      );
    }
  }
}
