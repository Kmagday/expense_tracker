import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/expense_models.dart';
import '../../blocs/expense_bloc.dart';
import '../../core/utils/icons_helper.dart';
import '../../blocs/currency_cubit.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        final expenses = state.expenses;
        final theme = Theme.of(context);
        final now = DateTime.now();
        final monthExpenses = expenses.where((e) =>
          e.date.month == now.month && e.date.year == now.year
        ).toList();
        final hasData = monthExpenses.isNotEmpty;

        return Scaffold(
          appBar: AppBar(title: const Text('Analytics')),
          body: !hasData
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('No expenses this month',
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('Add some expenses to see charts and breakdowns',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.pie_chart, color: Colors.blue),
                              ),
                              const SizedBox(width: 12),
                              Text(UiLabels.spendingByCategory, style: theme.textTheme.titleSmall),
                            ]),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 220,
                              child: _CategoryPieChart(expenses: monthExpenses),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.bar_chart, color: Colors.green),
                              ),
                              const SizedBox(width: 12),
                              Text(UiLabels.dailyTrend, style: theme.textTheme.titleSmall),
                            ]),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 220,
                              child: _DailyTrendChart(expenses: monthExpenses),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.list_alt, color: Colors.amber),
                              ),
                              const SizedBox(width: 12),
                              Text(UiLabels.categoryBreakdown, style: theme.textTheme.titleSmall),
                            ]),
                            const SizedBox(height: 16),
                            _CategoryBreakdown(expenses: monthExpenses),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  final List<ExpenseModel> expenses;
  const _CategoryPieChart({required this.expenses});

  @override
  Widget build(BuildContext context) {
    final byCategory = <String, double>{};
    final catColors = <String, Color>{};
    for (final e in expenses) {
      final name = e.category?.name ?? 'Other';
      byCategory[name] = (byCategory[name] ?? 0) + e.amount;
      catColors[name] = Color(e.category?.color ?? 0xFF757575);
    }

    final total = byCategory.values.fold(0.0, (a, b) => a + b);
    final currencyFormat = context.watch<CurrencyCubit>().state.formatter;
    final entries = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Row(
      children: [
        Expanded(
          child: Semantics(
            label: 'Spending by category chart. ${entries.take(3).map((e) => "${e.key}: ${currencyFormat.format(e.value)}").join(", ")}',
            child: PieChart(
            PieChartData(
              sections: entries.map((e) => PieChartSectionData(
                value: e.value,
                title: total > 0 ? '${(e.value / total * 100).toStringAsFixed(0)}%' : '0%',
                color: catColors[e.key],
                radius: 50,
                titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              )).toList(),
              centerSpaceRadius: 30,
              sectionsSpace: 2,
            ),
          ),
        ),
      ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: entries.take(6).map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(
                  color: catColors[e.key], borderRadius: BorderRadius.circular(3),
                )),
                const SizedBox(width: 6),
                Text('${e.key}: ${currencyFormat.format(e.value)}', style: const TextStyle(fontSize: 12)),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }
}

class _DailyTrendChart extends StatelessWidget {
  final List<ExpenseModel> expenses;
  const _DailyTrendChart({required this.expenses});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dailyTotals = <int, double>{};
    for (final e in expenses) {
      dailyTotals[e.date.day] = (dailyTotals[e.date.day] ?? 0) + e.amount;
    }

    final maxY = dailyTotals.values.fold(0.0, (a, b) => a > b ? a : b);
    final currencyFormat = context.watch<CurrencyCubit>().state.formatter;

    return Semantics(
      label: 'Daily spending bar chart. Highest: ${maxY > 0 ? currencyFormat.format(maxY) : "no data"}',
      child: BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
        barGroups: List.generate(daysInMonth, (i) {
          final day = i + 1;
          final amount = dailyTotals[day] ?? 0;
          return BarChartGroupData(
            x: day,
            barRods: [
              BarChartRodData(
                toY: amount,
                color: amount > 0 ? Theme.of(context).colorScheme.primary : Colors.transparent,
                width: daysInMonth > 28 ? 6 : 10,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                currencyFormat.format(value).replaceAll('.00', ''),
                style: const TextStyle(fontSize: 9),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: daysInMonth > 28 ? 5 : 1,
              getTitlesWidget: (value, meta) {
                if (value % (daysInMonth > 28 ? 5 : 1) != 0 && value != daysInMonth.toDouble()) {
                  return const SizedBox.shrink();
                }
                return Text('${value.toInt()}', style: const TextStyle(fontSize: 9));
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 4 : 1,
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                'Day ${group.x}: ${currencyFormat.format(rod.toY)}',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
        ),
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final List<ExpenseModel> expenses;
  const _CategoryBreakdown({required this.expenses});

  @override
  Widget build(BuildContext context) {
    final byCategory = <String, _CatTotal>{};
    for (final e in expenses) {
      final name = e.category?.name ?? 'Other';
      final existing = byCategory[name];
      if (existing != null) {
        byCategory[name] = _CatTotal(
          amount: existing.amount + e.amount,
          color: Color(e.category?.color ?? 0xFF757575),
          icon: e.category?.icon ?? 'receipt',
        );
      } else {
        byCategory[name] = _CatTotal(
          amount: e.amount,
          color: Color(e.category?.color ?? 0xFF757575),
          icon: e.category?.icon ?? 'receipt',
        );
      }
    }

    final total = byCategory.values.fold(0.0, (a, b) => a + b.amount);
    final currencyFormat = context.watch<CurrencyCubit>().state.formatter;
    final sorted = byCategory.entries.toList()..sort((a, b) => b.value.amount.compareTo(a.value.amount));

    return Column(
      children: sorted.map((e) {
        final pct = total > 0 ? (e.value.amount / total * 100) : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(iconFromString(e.value.icon), size: 20, color: e.value.color),
              const SizedBox(width: 8),
              SizedBox(width: 80, child: Text(e.key, style: const TextStyle(fontSize: 13))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    backgroundColor: e.value.color.withValues(alpha: 0.15),
                    color: e.value.color,
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 70,
                child: Text(currencyFormat.format(e.value.amount),
                    style: const TextStyle(fontSize: 12), textAlign: TextAlign.right),
              ),
              SizedBox(
                width: 40,
                child: Text('${pct.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.right),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CatTotal {
  final double amount;
  final Color color;
  final String icon;
  _CatTotal({required this.amount, required this.color, required this.icon});
}
