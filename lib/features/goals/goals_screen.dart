import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/models/expense_models.dart';
import '../../data/repositories/expense_repository.dart';
import '../../core/utils/icons_helper.dart';
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
    debugPrint('[Goals] loading goals');
    final repo = RepositoryProvider.of<ExpenseRepository>(context);
    _goals = await repo.getGoals();
    debugPrint('[Goals] loaded ${_goals.length} goals');
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addGoal() async {
    debugPrint('[Goals] opening add form');
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const _GoalFormScreen()),
    );
    debugPrint('[Goals] add form returned: $result');
    if (result == true) _load();
  }

  Future<void> _showTransferDialog(SavingsGoal goal) async {
    final repo = RepositoryProvider.of<ExpenseRepository>(context);
    final accounts = await repo.getAccounts();
    final nonDebt = accounts.where((a) => !a.isDebt).toList();
    if (nonDebt.isEmpty || !mounted) return;

    final amountCtl = TextEditingController();
    int? selectedAccountId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Transfer to "${goal.description}"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedAccountId,
                decoration: const InputDecoration(labelText: 'From Account'),
                items: nonDebt.map((a) => DropdownMenuItem(
                  value: a.id,
                  child: Row(children: [
                    Icon(iconFromString(a.icon), size: 18, color: Color(a.color)),
                    const SizedBox(width: 8),
                    Text('${a.name} (${a.balance.toStringAsFixed(0)})'),
                  ]),
                )).toList(),
                onChanged: (v) => setDialogState(() => selectedAccountId = v),
                validator: (v) => v == null ? 'Select account' : null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () {
              if (selectedAccountId == null || amountCtl.text.isEmpty) return;
              Navigator.pop(ctx, true);
            }, child: const Text('Transfer')),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    final amount = double.tryParse(amountCtl.text);
    if (amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid amount'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final account = nonDebt.firstWhere((a) => a.id == selectedAccountId);
    if (account.balance < amount) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insufficient balance'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final remaining = goal.targetAmount - goal.savedAmount;
    if (amount > remaining) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Only ${context.read<CurrencyCubit>().state.symbol}${remaining.toStringAsFixed(2)} needed to complete this goal'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    debugPrint('[Goals] transferring $amount from account $selectedAccountId to goal ${goal.id}');

    try {
      await repo.updateAccountBalance(selectedAccountId!, -amount);
      final updated = SavingsGoal(
        id: goal.id, targetAmount: goal.targetAmount, targetDate: goal.targetDate,
        description: goal.description,
        savedAmount: goal.savedAmount + amount,
        createdAt: goal.createdAt,
      );
      await repo.saveGoal(updated);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transferred ${context.read<CurrencyCubit>().state.symbol}${amount.toStringAsFixed(2)} to "${goal.description}"')),
        );
      }
    } catch (e) {
      debugPrint('[Goals] transfer error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transfer failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<bool> _showRefundDialog(SavingsGoal goal) async {
    final repo = RepositoryProvider.of<ExpenseRepository>(context);
    final accounts = await repo.getAccounts();
    final nonDebt = accounts.where((a) => !a.isDebt).toList();
    if (!mounted) return false;

    final savedAmount = goal.savedAmount;
    int? refundAccountId;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Refund "${goal.description}"?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This goal has ${savedAmount.toStringAsFixed(0)} saved. Choose an account to refund to, or cancel to keep the money in the goal.'),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: refundAccountId,
                decoration: const InputDecoration(labelText: 'Refund to Account'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Don\'t refund (delete anyway)')),
                  ...nonDebt.map((a) => DropdownMenuItem(
                    value: a.id,
                    child: Row(children: [
                      Icon(iconFromString(a.icon), size: 18, color: Color(a.color)),
                      const SizedBox(width: 8),
                      Text('${a.name} (${a.balance.toStringAsFixed(0)})'),
                    ]),
                  )),
                ],
                onChanged: (v) => setDialogState(() => refundAccountId = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result != true || !mounted) return false;

    if (refundAccountId != null) {
      try {
        await repo.updateAccountBalance(refundAccountId!, savedAmount);
        debugPrint('[Goals] refunded $savedAmount to account $refundAccountId on goal delete');
      } catch (e) {
        debugPrint('[Goals] refund failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Refund failed: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    return true;
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
                                    icon: const Icon(Icons.account_balance_wallet, color: Colors.green, size: 20),
                                    tooltip: 'Transfer from wallet',
                                    onPressed: () => _showTransferDialog(g),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () async {
                                      if (g.savedAmount > 0) {
                                        final refunded = await _showRefundDialog(g);
                                        if (!refunded) return;
                                      } else {
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
                                        if (confirm != true) return;
                                      }
                                      debugPrint('[Goals] deleting goal id=${g.id}, description=${g.description}');
                                      final repo = RepositoryProvider.of<ExpenseRepository>(context);
                                      await repo.deleteGoal(g.id);
                                      _load();
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
              debugPrint('[Goals] saving new goal - description: $desc, target: $amount, date: $_targetDate');
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
