import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/models/expense_models.dart';
import '../../data/repositories/expense_repository.dart';
import '../../blocs/currency_cubit.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<SavingsGoal> _goals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = RepositoryProvider.of<ExpenseRepository>(context);
    _goals = await repo.getGoals();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addGoal() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const _GoalFormScreen()),
    );
    if (result == true) _load();
  }

  Future<void> _updateProgress() async {
    final repo = RepositoryProvider.of<ExpenseRepository>(context);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final incomes = await repo.getIncomes(from: monthStart, to: monthEnd);
    final expenses = await repo.getExpenses(from: monthStart, to: monthEnd);
    final totalIncome = incomes.fold(0.0, (s, e) => s + e.amount);
    final totalExpense = expenses.fold(0.0, (s, e) => s + e.amount);
    final surplus = totalIncome - totalExpense;

    for (final g in _goals) {
      final newSaved = (g.savedAmount + surplus).clamp(0.0, g.targetAmount).toDouble();
      final updated = SavingsGoal(
        id: g.id, targetAmount: g.targetAmount, targetDate: g.targetDate,
        description: g.description, savedAmount: newSaved, createdAt: g.createdAt,
      );
      await repo.saveGoal(updated);
    }
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMessages.goalProgress(surplus))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = context.watch<CurrencyCubit>().state.formatter;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(PageTitles.savingsGoals)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _goals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.savings_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('No savings goals yet', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('Create a goal to track your savings progress',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _addGoal,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Goal'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ..._goals.map((g) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(g.description, style: theme.textTheme.titleMedium),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text(UiLabels.deleteGoalTitle),
                                          content: Text('Delete "${g.description}"?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        final repo = RepositoryProvider.of<ExpenseRepository>(context);
                                        await repo.deleteGoal(g.id);
                                        _load();
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: g.progress / 100,
                                  minHeight: 12,
                                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${fmt.format(g.savedAmount)} / ${fmt.format(g.targetAmount)}'),
                                  Text('${g.progress.toStringAsFixed(0)}%', style: TextStyle(color: theme.colorScheme.primary)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('${g.daysLeft > 0 ? "${g.daysLeft} days overdue" : "${-g.daysLeft} days left"} — Save ${fmt.format(g.monthlyTarget)}/mo',
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                            ],
                          ),
                        ),
                      )),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _addGoal,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Goal'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _updateProgress,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Update Progress from This Month'),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _GoalFormScreen extends StatefulWidget {
  const _GoalFormScreen();

  @override
  State<_GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<_GoalFormScreen> {
  final _descCtl = TextEditingController();
  final _amountCtl = TextEditingController();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 90));

  @override
  void dispose() {
    _descCtl.dispose();
    _amountCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final symbol = context.watch<CurrencyCubit>().state.symbol;
    return Scaffold(
      appBar: AppBar(title: const Text(PageTitles.newGoal)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _descCtl,
            decoration: const InputDecoration(labelText: 'What are you saving for?', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountCtl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Target Amount', prefixText: '$symbol ', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text('Target Date: ${DateFormat.yMMMd().format(_targetDate)}'),
            trailing: const Icon(Icons.edit),
            onTap: () async {
              final picked = await showDatePicker(
                context: context, initialDate: _targetDate,
                firstDate: DateTime.now(), lastDate: DateTime(2035),
              );
              if (picked != null) setState(() => _targetDate = picked);
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              final desc = _descCtl.text.trim();
              final amount = double.tryParse(_amountCtl.text.trim());
              if (desc.isEmpty || amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a description and valid amount')),
                );
                return;
              }
              final goal = SavingsGoal(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                targetAmount: amount, targetDate: _targetDate,
                description: desc, createdAt: DateTime.now(),
              );
              final repo = RepositoryProvider.of<ExpenseRepository>(context);
              await repo.saveGoal(goal);
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Create Goal'),
          ),
        ],
      ),
    );
  }
}
