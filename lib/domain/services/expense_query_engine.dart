import 'dart:math';
import 'package:intl/intl.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/models/expense_models.dart';

class ExpenseQueryEngine {
  String _currencySymbol = '\$';

  NumberFormat get _currency => NumberFormat.currency(symbol: _currencySymbol);

  void setCurrencySymbol(String symbol) { _currencySymbol = symbol; }
  final _dateFmt = DateFormat('MMM d');
  final _now = DateTime.now();

  Future<String> answer(String query, ExpenseRepository repo) async {
    final q = query.toLowerCase().trim();

    if (_isAsking('forecast', q) || _isAsking('project', q)) {
      return _answerForecast(repo);
    }
    if (_isAsking('anomal', q) || _isAsking('unusual', q) || _isAsking('suspicious', q)) {
      return _answerAnomalies(repo);
    }
    if (_isAsking('suggest', q) || _isAsking('save', q) || _isAsking('tip', q)) {
      return _answerSuggestions(repo);
    }
    if (_isAsking('pattern', q) || _isAsking('trend', q)) {
      return _answerPatterns(repo);
    }
    if (_isAsking('budget', q) || _isAsking('remaining', q)) {
      return _answerBudget(repo, q);
    }
    if (_isAsking('income', q) || _isAsking('earn', q) || _isAsking('salary', q)) {
      return _answerIncome(repo, q);
    }
    if (_isAsking('compare', q) || _isAsking('difference', q) || q.contains('vs')) {
      return _answerComparison(repo, q);
    }
    if (_isAsking('biggest', q) || _isAsking('largest', q) || _isAsking('most expensive', q) || _isAsking('highest', q)) {
      return _answerLargest(repo, q);
    }
    if (_isAsking('recent', q) || _isAsking('last', q) || q.contains('latest')) {
      return _answerRecent(repo, q);
    }
    if (_isAsking('average', q) || _isAsking('mean', q)) {
      return _answerAverage(repo, q);
    }
    if (_isAsking('count', q) || _isAsking('how many', q) || _isAsking('number of', q)) {
      return _answerCount(repo, q);
    }
    if ((q.contains('what if') || q.contains('whatif') || q.contains('simulate')) && (q.contains('cut') || q.contains('reduce') || q.contains('less'))) {
      return _answerWhatIf(repo, q);
    }
    if (_isAsking('total', q) || q.contains('spend') || q.contains('spent') || q.contains('expense')) {
      return _answerTotal(repo, q);
    }

    return _fallback(repo, q);
  }

  bool _isAsking(String keyword, String q) => q.contains(keyword);

  // ── Helpers ──

  Future<List<ExpenseModel>> _monthExpenses(ExpenseRepository repo) async {
    final all = await repo.getExpenses();
    return all.where((e) => e.date.month == _now.month && e.date.year == _now.year).toList();
  }

  Future<List<ExpenseModel>> _weekExpenses(ExpenseRepository repo) async {
    final start = _now.subtract(Duration(days: _now.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return repo.getExpenses(from: start, to: end);
  }

  Future<List<ExpenseModel>> _todayExpenses(ExpenseRepository repo) async {
    final start = DateTime(_now.year, _now.month, _now.day);
    return repo.getExpenses(from: start, to: start.add(const Duration(days: 1)));
  }

  double _total(List<ExpenseModel> exps) => exps.fold(0.0, (s, e) => s + e.amount);

  String _fmt(double v) => _currency.format(v);

  String _periodFromQuery(String q) {
    if (q.contains('today')) return 'today';
    if (q.contains('this week') || q.contains('this week')) return 'this week';
    if (q.contains('this month') || q.contains('month')) return 'this month';
    if (q.contains('this year') || q.contains('year')) return 'this year';
    if (q.contains('last month') || q.contains('previous month')) return 'last month';
    if (q.contains('last week') || q.contains('previous week')) return 'last week';
    return 'this month';
  }

  Future<String> _catNameFromQuery(String q, ExpenseRepository repo) async {
    final cats = await repo.getCategories(type: 'expense');
    for (final c in cats) {
      if (q.contains(c.name.toLowerCase())) return c.name;
    }
    return '';
  }

  // ── Answers ──

  Future<String> _answerTotal(ExpenseRepository repo, String q) async {
    final period = _periodFromQuery(q);
    final catName = await _catNameFromQuery(q, repo);
    List<ExpenseModel> exps;
    if (period == 'today') exps = await _todayExpenses(repo);
    else if (period == 'this week') exps = await _weekExpenses(repo);
    else if (period == 'last month') {
      final lm = DateTime(_now.year, _now.month - 1, 1);
      exps = await repo.getExpenses(from: lm, to: DateTime(lm.year, lm.month + 1, 0));
    } else if (period == 'last week') {
      final start = _now.subtract(Duration(days: _now.weekday + 6));
      final end = start.add(const Duration(days: 6));
      exps = await repo.getExpenses(from: start, to: end);
    } else {
      exps = await _monthExpenses(repo);
    }

    if (catName.isNotEmpty) exps = exps.where((e) => e.category?.name == catName).toList();
    if (exps.isEmpty) return 'No expenses found for $period${catName.isNotEmpty ? ' in $catName' : ''}.';
    final total = _total(exps);
    final count = exps.length;
    final label = catName.isNotEmpty ? '$catName expenses' : 'Total spending';
    return '$label for $period: ${_fmt(total)} across $count transaction${count == 1 ? '' : 's'}.';
  }

  Future<String> _answerForecast(ExpenseRepository repo) async {
    final exps = await _monthExpenses(repo);
    if (exps.isEmpty) return 'No expenses this month yet, so I can\'t make a forecast.';
    final daysInMonth = DateTime(_now.year, _now.month + 1, 0).day;
    final spent = _total(exps);
    final avgPerDay = spent / max(1, _now.day);
    final projected = avgPerDay * daysInMonth;
    return 'You\'ve spent ${_fmt(spent)} so far this month (day ${_now.day} of $daysInMonth). At this rate, you\'re on track to spend ${_fmt(projected)} by month end.';
  }

  Future<String> _answerAnomalies(ExpenseRepository repo) async {
    final all = await repo.getExpenses();
    if (all.length < 3) return 'Not enough data to detect anomalies (need at least 3 expenses).';
    final byCat = <int, List<ExpenseModel>>{};
    for (final e in all) { byCat.putIfAbsent(e.categoryId, () => []).add(e); }
    final anomalies = <ExpenseModel>[];
    for (final entry in byCat.entries) {
      final amounts = entry.value.map((e) => e.amount).toList();
      if (amounts.length < 3) continue;
      final mean = amounts.fold(0.0, (a, b) => a + b) / amounts.length;
      final variance = amounts.fold(0.0, (a, b) => a + (b - mean) * (b - mean)) / amounts.length;
      final std = sqrt(variance);
      for (final e in entry.value) {
        if (e.amount > mean + 2 * std) anomalies.add(e);
      }
    }
    if (anomalies.isEmpty) return 'No unusual expenses detected.';
    final buf = StringBuffer('Found ${anomalies.length} unusual expense${anomalies.length == 1 ? '' : 's'}:\n');
    for (final a in anomalies.take(5)) {
      buf.writeln('• ${_fmt(a.amount)} on ${a.category?.name ?? 'other'} (${_dateFmt.format(a.date)})${a.note != null ? ' — ${a.note}' : ''}');
    }
    return buf.toString();
  }

  Future<String> _answerSuggestions(ExpenseRepository repo) async {
    final exps = await _monthExpenses(repo);
    if (exps.length < 5) return 'Add more expenses to get personalized saving suggestions.';
    final byCat = <String, List<ExpenseModel>>{};
    for (final e in exps) { byCat.putIfAbsent(e.category?.name ?? 'Other', () => []).add(e); }
    final totals = byCat.map((k, v) => MapEntry(k, _total(v)));
    final total = _total(exps);
    final suggestions = <String>[];
    if ((totals['Food'] ?? 0) > total * 0.3) {
      suggestions.add('Food is ${((totals['Food']! / total) * 100).toStringAsFixed(0)}% of spending. Cutting 20% could save ~${_fmt(totals['Food']! * 0.2)}.');
    }
    if ((totals['Transport'] ?? 0) > total * 0.2) {
      suggestions.add('Transport is ${((totals['Transport']! / total) * 100).toStringAsFixed(0)}% of spending. Consider carpooling or public transit.');
    }
    final subs = exps.where((e) => e.isRecurring || (e.note?.toLowerCase().contains('subscription') ?? false));
    if (subs.length >= 2) {
      suggestions.add('You have ${subs.length} recurring/subscription expenses totaling ${_fmt(_total(subs.toList()))}/mo.');
    }
    if (suggestions.isEmpty) return 'You\'re doing well! No major savings opportunities detected this month.';
    return suggestions.map((s) => '• $s').join('\n');
  }

  Future<String> _answerPatterns(ExpenseRepository repo) async {
    final exps = await repo.getExpenses();
    if (exps.isEmpty) return 'No data to analyze patterns.';
    final byDay = <int, List<double>>{};
    for (final e in exps) { byDay.putIfAbsent(e.date.weekday, () => []).add(e.amount); }
    final names = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
    final avgs = <String, double>{};
    for (final e in byDay.entries) {
      avgs[names[e.key]!] = e.value.fold(0.0, (a, b) => a + b) / e.value.length;
    }
    final highest = avgs.entries.reduce((a, b) => a.value > b.value ? a : b);
    final lowest = avgs.entries.reduce((a, b) => a.value < b.value ? a : b);
    final weekdays = avgs.entries.where((e) => !e.key.contains('Sat') && !e.key.contains('Sun')).toList();
    final weekends = avgs.entries.where((e) => e.key.contains('Sat') || e.key.contains('Sun')).toList();
    final wdAvg = weekdays.isEmpty ? 0 : weekdays.fold(0.0, (s, e) => s + e.value) / weekdays.length;
    final weAvg = weekends.isEmpty ? 0 : weekends.fold(0.0, (s, e) => s + e.value) / weekends.length;
    final diff = weAvg > wdAvg ? ((weAvg - wdAvg) / max(1, wdAvg) * 100).toStringAsFixed(0) : '0';
    return 'Highest spending day: ${highest.key} (${_fmt(highest.value)})\n'
        'Lowest spending day: ${lowest.key} (${_fmt(lowest.value)})\n'
        '${weAvg > wdAvg ? 'You spend $diff% more on weekends.' : 'Weekend spending is lower than weekdays.'}';
  }

  Future<String> _answerBudget(ExpenseRepository repo, String q) async {
    final budgets = await repo.getBudgets(_now.month, _now.year);
    if (budgets.isEmpty) return 'No budgets set for this month. Go to the Budget tab to create one.';
    final buf = StringBuffer();
    for (final b in budgets) {
      final name = b.category?.name ?? 'Overall';
      buf.writeln('• $name: ${_fmt(b.spentAmount)} of ${_fmt(b.budgetAmount)} (${b.percentage.toStringAsFixed(0)}%) — ${_fmt(b.remaining)} remaining');
    }
    return buf.toString();
  }

  Future<String> _answerIncome(ExpenseRepository repo, String q) async {
    final period = _periodFromQuery(q);
    List<IncomeModel> inc;
    if (period == 'this month') {
      inc = await repo.getIncomes(from: DateTime(_now.year, _now.month, 1), to: DateTime(_now.year, _now.month + 1, 0));
    } else if (period == 'today') {
      final start = DateTime(_now.year, _now.month, _now.day);
      inc = await repo.getIncomes(from: start, to: start.add(const Duration(days: 1)));
    } else {
      inc = await repo.getIncomes(from: DateTime(_now.year, _now.month, 1), to: DateTime(_now.year, _now.month + 1, 0));
    }
    if (inc.isEmpty) return 'No income recorded for $period.';
    final total = inc.fold(0.0, (s, i) => s + i.amount);
    final count = inc.length;
    return 'Total income for $period: ${_fmt(total)} across $count entr${count == 1 ? 'y' : 'ies'}.';
  }

  Future<String> _answerComparison(ExpenseRepository repo, String q) async {
    final thisMonth = await _monthExpenses(repo);
    final totalThis = _total(thisMonth);
    final lastMonth = DateTime(_now.year, _now.month - 1, 1);
    final lastExpenses = await repo.getExpenses(from: lastMonth, to: DateTime(lastMonth.year, lastMonth.month + 1, 0));
    final totalLast = _total(lastExpenses);
    if (totalLast == 0) return 'No expenses last month to compare.';
    final pct = ((totalThis - totalLast) / totalLast * 100).toStringAsFixed(1);
    final direction = totalThis > totalLast ? 'more' : 'less';
    return 'You spent ${_fmt(totalThis)} this month vs ${_fmt(totalLast)} last month ($pct% $direction).';
  }

  Future<String> _answerLargest(ExpenseRepository repo, String q) async {
    final period = _periodFromQuery(q);
    List<ExpenseModel> exps;
    if (period == 'this month') exps = await _monthExpenses(repo);
    else exps = await repo.getExpenses();
    if (exps.isEmpty) return 'No expenses found.';
    exps.sort((a, b) => b.amount.compareTo(a.amount));
    final top = exps.first;
    return 'Your largest expense${period == 'this month' ? ' this month' : ''} was ${_fmt(top.amount)} for ${top.category?.name ?? 'other'} on ${_dateFmt.format(top.date)}${top.note != null ? ' (${top.note})' : ''}.';
  }

  Future<String> _answerRecent(ExpenseRepository repo, String q) async {
    final exps = await repo.getExpenses();
    if (exps.isEmpty) return 'No expenses yet.';
    final count = 5;
    final buf = StringBuffer('Last $count expenses:\n');
    for (final e in exps.take(count)) {
      buf.writeln('• ${_fmt(e.amount)} — ${e.category?.name ?? 'other'} (${_dateFmt.format(e.date)})');
    }
    return buf.toString();
  }

  Future<String> _answerAverage(ExpenseRepository repo, String q) async {
    final exps = await _monthExpenses(repo);
    if (exps.isEmpty) return 'No expenses this month to calculate averages.';
    final daysInMonth = DateTime(_now.year, _now.month + 1, 0).day;
    final total = _total(exps);
    final avgDay = total / max(1, _now.day);
    final avgTrans = total / exps.length;
    return 'This month: average ${_fmt(avgDay)}/day across ${exps.length} transactions, average ${_fmt(avgTrans)} per transaction.';
  }

  Future<String> _answerCount(ExpenseRepository repo, String q) async {
    final period = _periodFromQuery(q);
    List<ExpenseModel> exps;
    if (period == 'today') exps = await _todayExpenses(repo);
    else if (period == 'this week') exps = await _weekExpenses(repo);
    else exps = await _monthExpenses(repo);
    return 'You have ${exps.length} expense${exps.length == 1 ? '' : 's'} for $period.';
  }

  Future<List<int>> _categoryIdsFromString(String q, List<ExpenseModel> monthExps, ExpenseRepository repo) async {
    final categories = (await repo.getCategories(type: 'expense'))
        .where((c) => q.contains(c.name.toLowerCase()))
        .map((c) => c.id)
        .toList();
    if (categories.isEmpty) {
      return monthExps.map((e) => e.categoryId).toSet().toList();
    }
    return categories;
  }

  Future<String> _answerWhatIf(ExpenseRepository repo, String q) async {
    final monthExps = await _monthExpenses(repo);
    if (monthExps.isEmpty) return 'No expenses this month to simulate.';

    // Extract reduction percentage
    final pctMatch = RegExp(r'(\d+)%').firstMatch(q);
    final reductionPct = pctMatch != null ? int.parse(pctMatch.group(1)!) : 20;

    final catIds = await _categoryIdsFromString(q, monthExps, repo);
    final catReductions = <int, double>{for (final id in catIds) id: reductionPct / 100.0};

    double totalReduction = 0;
    final byCategory = <int, List<ExpenseModel>>{};
    for (final e in monthExps) {
      byCategory.putIfAbsent(e.categoryId, () => []).add(e);
    }
    for (final entry in catReductions.entries) {
      final catExps = byCategory[entry.key] ?? [];
      totalReduction += catExps.fold(0.0, (s, e) => s + e.amount) * entry.value;
    }

    final categories = await repo.getCategories(type: 'expense');
    final catNames = catIds.map((id) {
      final c = categories.where((c) => c.id == id);
      return c.isNotEmpty ? c.first.name : 'category $id';
    }).toList();

    return 'What-if analysis: If you cut ${catNames.join(", ")} by $reductionPct%, '
        'you could save ${_fmt(totalReduction)} this month. '
        '${totalReduction > 0 ? "That\'s ${_fmt(totalReduction)} more in your pocket!" : ""}';
  }

  Future<String> _fallback(ExpenseRepository repo, String q) async {
    final total = _total(await _monthExpenses(repo));
    return 'I can answer questions about your spending, income, budgets, and patterns. '
        'Try asking: "How much did I spend on food?", "What\'s my budget status?", '
        '"Any unusual expenses?", or "Compare this month to last month." '
        '${total > 0 ? "You\'ve spent ${_fmt(total)} this month so far." : ""}';
  }
}
