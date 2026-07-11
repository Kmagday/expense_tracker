import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../data/models/expense_models.dart';
import '../../data/repositories/expense_repository.dart';
import 'expense_query_engine.dart';

class AIInsightsService {
  /// Forecast that separates recurring (fixed) expenses from discretionary (variable) spending.
  /// Gives a more accurate projection because fixed costs don't follow daily trends.
  double forecastEndOfMonth(
    List<ExpenseModel> monthExpenses,
    int daysInMonth, {
    List<ExpenseModel>? allExpenses,
  }) {
    if (monthExpenses.isEmpty) {
      debugPrint('[AIInsights] forecast: no expenses this month');
      return 0;
    }

    final recurring = monthExpenses.where((e) => e.isRecurring).toList();
    final discretionary = monthExpenses.where((e) => !e.isRecurring).toList();

    // 1. Add recurring that has already occurred this month
    double total = recurring.fold(0.0, (s, e) => s + e.amount);

    // 2. Add future recurring charges detected from history
    if (allExpenses != null && allExpenses.length > monthExpenses.length) {
      final detected = _detectFutureRecurring(allExpenses, monthExpenses, daysInMonth);
      total += detected;
    }

    // 3. Project discretionary spending via linear regression
    if (discretionary.length < 2) {
      return total + discretionary.fold(0.0, (s, e) => s + e.amount);
    }

    final dailyTotals = <int, double>{};
    for (final e in discretionary) {
      dailyTotals[e.date.day] = (dailyTotals[e.date.day] ?? 0) + e.amount;
    }

    final days = dailyTotals.keys.toList()..sort();
    final dayNumbers = days.map((d) => d.toDouble()).toList();
    final amounts = days.map((d) => dailyTotals[d]!).toList();

    final n = dayNumbers.length;
    final sumX = dayNumbers.fold(0.0, (a, b) => a + b);
    final sumY = amounts.fold(0.0, (a, b) => a + b);
    final sumXY = _zipWith(dayNumbers, amounts, (a, b) => a * b);
    final sumX2 = dayNumbers.fold(0.0, (a, b) => a + b * b);

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    final lastDay = days.last.toDouble();
    final spentSoFar = amounts.fold(0.0, (a, b) => a + b);

    if (lastDay < daysInMonth) {
      final remainingDays = daysInMonth - lastDay.toInt();
      final avgDailyRate = slope * lastDay + intercept;
      total += spentSoFar + (avgDailyRate / lastDay) * remainingDays;
    } else {
      total += spentSoFar;
    }

    debugPrint('[AIInsights] forecast result: $total (recurring: ${recurring.length}, discretionary: ${discretionary.length})');
    return total;
  }

  /// Detect expenses with subscription-like patterns from full history.
  /// Looks at: isRecurring flag, keywords in notes, same-amount patterns across months.
  List<ExpenseModel> detectSubscriptions(List<ExpenseModel> allExpenses) {
    if (allExpenses.length < 3) return [];

    final subscriptions = <ExpenseModel>[];
    final seen = <int>{};

    // 1. Flagged recurring
    for (final e in allExpenses) {
      if (e.isRecurring && seen.add(e.id)) {
        subscriptions.add(e);
      }
    }

    // 2. Keyword match
    final keywords = ['subscription', 'netflix', 'spotify', 'patreon', 'disney+',
      'hulu', 'dropbox', 'i cloud', 'icloud', 'google one', 'amazon prime',
      'apple music', 'youtube premium', 'medium', 'notion'];
    for (final e in allExpenses) {
      if (!seen.contains(e.id) && e.note != null) {
        final note = e.note!.toLowerCase();
        if (keywords.any((k) => note.contains(k))) {
          subscriptions.add(e);
          seen.add(e.id);
        }
      }
    }

    // 3. Pattern detection: same category + same amount across 3+ different months
    final byCatAmount = <String, List<ExpenseModel>>{};
    for (final e in allExpenses) {
      if (seen.contains(e.id)) continue;
      final key = '${e.categoryId}_${e.amount.toStringAsFixed(2)}';
      byCatAmount.putIfAbsent(key, () => []).add(e);
    }
    for (final entry in byCatAmount.entries) {
      if (entry.value.length >= 3) {
        final months = entry.value.map((e) => e.date.month).toSet();
        if (months.length >= 3) {
          for (final e in entry.value) {
            if (seen.add(e.id)) {
              subscriptions.add(e);
            }
          }
        }
      }
    }

    debugPrint('[AIInsights] subscriptions: found ${subscriptions.length} from ${allExpenses.length} expenses');
    return subscriptions;
  }

  /// Detect anomalies: expenses more than 2 standard deviations above category mean.
  List<ExpenseModel> detectAnomalies(List<ExpenseModel> expenses) {
    if (expenses.length < 3) return [];

    final byCategory = _groupBy(expenses, (e) => e.categoryId);
    final anomalies = <ExpenseModel>[];

    for (final entry in byCategory.entries) {
      final amounts = entry.value.map((e) => e.amount).toList();
      if (amounts.length < 3) continue;
      final mean = amounts.fold(0.0, (a, b) => a + b) / amounts.length;
      final variance = amounts.fold(0.0, (a, b) => a + (b - mean) * (b - mean)) / amounts.length;
      final stdDev = sqrt(variance);

      for (final expense in entry.value) {
        if (expense.amount > mean + 2 * stdDev) {
          anomalies.add(expense);
        }
      }
    }
    debugPrint('[AIInsights] anomalies: found ${anomalies.length} from ${expenses.length} expenses');
    return anomalies;
  }

  /// Pattern detection: identify spending patterns by day of week.
  Map<String, dynamic> analyzePatterns(List<ExpenseModel> expenses) {
    if (expenses.isEmpty) return {'summary': 'No data to analyze.'};

    final byWeekday = <int, List<double>>{};
    for (final e in expenses) {
      byWeekday.putIfAbsent(e.date.weekday, () => []).add(e.amount);
    }

    final weekdayNames = {
      1: 'Monday', 2: 'Tuesday', 3: 'Wednesday', 4: 'Thursday',
      5: 'Friday', 6: 'Saturday', 7: 'Sunday',
    };

    final averages = <String, double>{};
    for (final entry in byWeekday.entries) {
      final avg = entry.value.fold(0.0, (a, b) => a + b) / entry.value.length;
      averages[weekdayNames[entry.key]!] = avg;
    }

    final maxEntry = averages.entries.fold(averages.entries.first,
        (a, b) => a.value > b.value ? a : b);
    final minEntry = averages.entries.fold(averages.entries.first,
        (a, b) => a.value < b.value ? a : b);

    final weekdayAvg = averages.entries
        .where((e) => !e.key.contains('Saturday') && !e.key.contains('Sunday'))
        .fold(0.0, (s, e) => s + e.value) /
        max(1, averages.entries.where((e) => !e.key.contains('Saturday') && !e.key.contains('Sunday')).length);
    final weekendAvg = averages.entries
        .where((e) => e.key.contains('Saturday') || e.key.contains('Sunday'))
        .fold(0.0, (s, e) => s + e.value) /
        max(1, averages.entries.where((e) => e.key.contains('Saturday') || e.key.contains('Sunday')).length);

    final weekendDiff = weekendAvg - weekdayAvg;
    final weekendPct = weekdayAvg > 0 ? (weekendDiff / weekdayAvg * 100) : 0;

    return {
      'dailyAverages': averages,
      'highestSpendingDay': maxEntry.key,
      'highestSpendingAmount': maxEntry.value,
      'lowestSpendingDay': minEntry.key,
      'lowestSpendingAmount': minEntry.value,
      'weekdayAverage': weekdayAvg,
      'weekendAverage': weekendAvg,
      'weekendPremiumPercent': weekendPct,
      'weekendSpendingHigher': weekendDiff > 0,
    };
  }

  /// Generate personalized saving suggestions.
  List<String> generateSuggestions(List<ExpenseModel> expenses) {
    debugPrint('[AIInsights] generateSuggestions from ${expenses.length} expenses');
    final suggestions = <String>[];
    if (expenses.length < 5) {
      suggestions.add('Add more expenses to receive personalized suggestions.');
      return suggestions;
    }

    final byCategory = _groupBy(expenses, (e) => e.category?.name ?? 'Other');
    final totals = <String, double>{};
    for (final entry in byCategory.entries) {
      totals[entry.key] = entry.value.fold(0.0, (s, e) => s + e.amount);
    }

    final totalSpend = totals.values.fold(0.0, (a, b) => a + b);

    if (totals.containsKey('Food') && totals['Food']! > totalSpend * 0.3) {
      final foodAmount = totals['Food']!;
      final potentialSaving = foodAmount * 0.2;
      suggestions.add('You spend ${foodAmount.toStringAsFixed(0)} on food. '
          'Cutting 20% could save ~\$${potentialSaving.toStringAsFixed(0)} this month.');
    }

    final diningOut = expenses.where((e) =>
        e.category?.name == 'Food' && (e.note?.toLowerCase().contains('delivery') == true ||
            e.note?.toLowerCase().contains('restaurant') == true ||
            e.note?.toLowerCase().contains('uber') == true ||
            e.note?.toLowerCase().contains('doordash') == true ||
            e.note?.toLowerCase().contains('grubhub') == true));
    if (diningOut.length >= 3) {
      final total = diningOut.fold(0.0, (s, e) => s + e.amount);
      suggestions.add('You\'ve spent \$${total.toStringAsFixed(0)} on food delivery. '
          'Cooking at home 3x/week could save ~\$50/month.');
    }

    if (totals.containsKey('Transport')) {
      final transport = totals['Transport']!;
      if (transport > totalSpend * 0.2) {
        suggestions.add('Transport costs are ${(transport / totalSpend * 100).toStringAsFixed(0)}% '
            'of your spending. Consider public transit or carpooling.');
      }
    }

    final subs = detectSubscriptions(expenses);
    if (subs.length >= 2) {
      final subTotal = subs.fold(0.0, (s, e) => s + e.amount);
      suggestions.add('You have ${subs.length} potential subscriptions totaling '
          '\$${subTotal.toStringAsFixed(0)}/mo. Review and cancel unused ones.');
    }

    if (suggestions.isEmpty) {
      suggestions.add('You\'re doing well! No major saving opportunities detected.');
    }

    return suggestions;
  }

  /// Estimate future recurring charges that haven't occurred yet this month.
  double _detectFutureRecurring(
    List<ExpenseModel> allExpenses,
    List<ExpenseModel> monthExpenses,
    int daysInMonth,
  ) {
    final now = DateTime.now();
    final thisMonth = now.month;
    final thisYear = now.year;

    // Get recurring from history that hasn't happened yet this month
    final historicalRecurring = allExpenses
        .where((e) => e.isRecurring && !(e.date.month == thisMonth && e.date.year == thisYear))
        .toList();

    if (historicalRecurring.isEmpty) return 0;

    double futureTotal = 0;

    // Group by category ID to find the monthly amount
    final byCategory = <int, double>{};
    for (final e in historicalRecurring) {
      byCategory.update(
        e.categoryId,
        (v) => v + e.amount,
        ifAbsent: () => e.amount,
      );
    }

    // For each category with recurring, check if it's already occurred this month
    for (final entry in byCategory.entries) {
      final alreadyThisMonth = monthExpenses.any((e) =>
          e.categoryId == entry.key && e.isRecurring);
      if (!alreadyThisMonth) {
        // Average monthly amount for this recurring category
        final count = historicalRecurring
            .where((e) => e.categoryId == entry.key)
            .length;
        futureTotal += entry.value / max(1, count);
      }
    }

    return futureTotal;
  }

  final _engine = ExpenseQueryEngine();

  Future<String> chatWithAI(String userMessage, ExpenseRepository repo) async {
    return _engine.answer(userMessage, repo);
  }

  // ── Helpers ──

  Map<K, List<V>> _groupBy<K, V>(List<V> list, K Function(V) keyFn) {
    final map = <K, List<V>>{};
    for (final item in list) {
      final key = keyFn(item);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  double _zipWith<T>(List<double> a, List<double> b, double Function(double, double) fn) {
    double result = 0;
    final len = min(a.length, b.length);
    for (int i = 0; i < len; i++) {
      result += fn(a[i], b[i]);
    }
    return result;
  }

  // ── What-If Simulator ──

  Map<String, dynamic> simulateWhatIf({
    required List<ExpenseModel> monthExpenses,
    required int daysInMonth,
    required Map<int, double> categoryReductions,
  }) {
    debugPrint('[AIInsights] simulateWhatIf: ${categoryReductions.length} category reductions');
    final currentForecast = forecastEndOfMonth(monthExpenses, daysInMonth);
    final byCategory = _groupBy(monthExpenses, (e) => e.categoryId);
    double totalReduction = 0;

    for (final entry in categoryReductions.entries) {
      final catExpenses = byCategory[entry.key] ?? [];
      final catTotal = catExpenses.fold(0.0, (s, e) => s + e.amount);
      totalReduction += catTotal * entry.value;
    }

    final adjustedForecast = currentForecast - totalReduction;
    return {
      'currentForecast': currentForecast,
      'adjustedForecast': adjustedForecast,
      'reduction': totalReduction,
      'difference': currentForecast - adjustedForecast,
    };
    debugPrint('[AIInsights] simulateWhatIf result - current: $currentForecast, adjusted: $adjustedForecast, reduction: $totalReduction');
  }
}
