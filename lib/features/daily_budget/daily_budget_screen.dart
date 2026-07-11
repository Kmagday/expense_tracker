import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/expense_repository.dart';
import '../../blocs/currency_cubit.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class DailyBudgetScreen extends StatefulWidget {
  const DailyBudgetScreen({super.key});

  @override
  State<DailyBudgetScreen> createState() => _DailyBudgetScreenState();
}

class _DailyBudgetScreenState extends State<DailyBudgetScreen> {
  final _amountCtl = TextEditingController();
  double _target = 0;
  double _todaySpent = 0;
  List<_DaySpending> _recentDays = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    _target = prefs.getDouble(PrefKeys.dailyBudgetTarget) ?? 0;

    final repo = RepositoryProvider.of<ExpenseRepository>(context);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final allExpenses = await repo.getExpenses();

    _todaySpent = allExpenses
        .where((e) => !e.date.isBefore(todayStart))
        .fold(0.0, (s, e) => s + e.amount);

    _recentDays = [];
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));
      final spent = allExpenses
          .where((e) => !e.date.isBefore(start) && e.date.isBefore(end))
          .fold(0.0, (s, e) => s + e.amount);
      _recentDays.add(_DaySpending(date: start, spent: spent));
    }

    if (mounted) {
      _amountCtl.text = _target > 0 ? _target.toStringAsFixed(2) : '';
      setState(() => _loading = false);
    }
  }

  Future<void> _saveTarget() async {
    final amount = double.tryParse(_amountCtl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(PrefKeys.dailyBudgetTarget, amount);
    setState(() => _target = amount);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Daily budget set to \$${amount.toStringAsFixed(2)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = context.watch<CurrencyCubit>().state.formatter;
    final ratio = _target > 0 ? (_todaySpent / _target).clamp(0.0, 1.0) : 0.0;
    final remaining = _target - _todaySpent;
    final onTrack = remaining >= 0;
    final statusColor = ratio > 0.9 ? Colors.red : ratio > 0.7 ? Colors.orange : Colors.green;

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Budget')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text("Today's Budget",
                              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text(
                            _target > 0 ? fmt.format(_target) : 'Not set',
                            style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 120, height: 120,
                                  child: CircularProgressIndicator(
                                    value: ratio,
                                    strokeWidth: 10,
                                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation(statusColor),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _target > 0
                                          ? '${(_todaySpent / _target * 100).toStringAsFixed(0)}%'
                                          : '--',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                                    ),
                                    Text('used', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatItem(label: 'Spent', value: fmt.format(_todaySpent), color: Colors.red),
                              _StatItem(
                                label: onTrack ? 'Left' : 'Over',
                                value: fmt.format(remaining.abs()),
                                color: onTrack ? Colors.green : Colors.red,
                              ),
                            ],
                          ),
                          if (_target > 0) ...[
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 8,
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation(statusColor),
                              ),
                            ),
                            Text(
                              onTrack
                                  ? _getEncouragement(ratio)
                                  : _getWarning(ratio),
                              style: TextStyle(
                                fontSize: 13,
                                color: onTrack ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Set Daily Target', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _amountCtl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Daily budget',
                                    prefixText: '${context.read<CurrencyCubit>().state.symbol} ',
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              FilledButton(
                                onPressed: _saveTarget,
                                child: const Text('Set'),
                              ),
                            ],
                          ),
                          if (_target > 0) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  _amountCtl.clear();
                                  _saveTarget();
                                  setState(() => _target = 0);
                                  _load();
                                },
                                child: const Text('Clear Daily Budget'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Last 7 Days', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 12),
                          ..._recentDays.map((d) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    DateFormat.E().format(d.date),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                SizedBox(
                                  width: 50,
                                  child: Text(
                                    DateFormat.Md().format(d.date),
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: _target > 0 ? (d.spent / _target).clamp(0.0, 1.0) : 0,
                                      minHeight: 6,
                                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                      valueColor: AlwaysStoppedAnimation(
                                        _target > 0 && d.spent > _target
                                            ? Colors.red
                                            : _target > 0 && d.spent > _target * 0.7
                                                ? Colors.orange
                                                : Colors.green,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    fmt.format(d.spent),
                                    style: const TextStyle(fontSize: 12),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _getEncouragement(double ratio) {
    if (ratio < 0.3) return '🌟 Great start! You\'re saving well today.';
    if (ratio < 0.5) return '👍 Halfway there — you\'re on track!';
    if (ratio < 0.7) return '💪 Doing well, still under budget!';
    return '⚠️ Approaching your daily limit.';
  }

  String _getWarning(double ratio) {
    if (ratio < 1.2) return '📈 Just over budget — watch those last expenses.';
    return '🔴 Over budget today. Tomorrow\'s a fresh start!';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _DaySpending {
  final DateTime date;
  final double spent;
  _DaySpending({required this.date, required this.spent});
}
