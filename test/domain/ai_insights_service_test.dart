import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/data/models/expense_models.dart';
import 'package:expense_tracker/domain/services/ai_insights_service.dart';

void main() {
  late AIInsightsService service;

  setUp(() {
    service = AIInsightsService();
  });

  group('Forecast', () {
    test('returns total when less than 2 expenses', () {
      final expenses = [
        _makeExpense(amount: 50, day: 1),
      ];
      final result = service.forecastEndOfMonth(expenses, 30);
      expect(result, 50.0);
    });

    test('projects end-of-month spending', () {
      final expenses = [
        _makeExpense(amount: 100, day: 1),
        _makeExpense(amount: 100, day: 2),
        _makeExpense(amount: 100, day: 3),
        _makeExpense(amount: 100, day: 4),
        _makeExpense(amount: 100, day: 5),
      ];
      final result = service.forecastEndOfMonth(expenses, 30);
      expect(result, greaterThan(0));
    });
  });

  group('Anomaly Detection', () {
    test('returns empty for less than 3 expenses', () {
      final expenses = [
        _makeExpense(amount: 10, day: 1),
        _makeExpense(amount: 20, day: 2),
      ];
      expect(service.detectAnomalies(expenses), isEmpty);
    });

    test('flags unusually large expense', () {
      final expenses = [
        _makeExpense(amount: 10, day: 1),
        _makeExpense(amount: 12, day: 2),
        _makeExpense(amount: 11, day: 3),
        _makeExpense(amount: 9, day: 4),
        _makeExpense(amount: 10, day: 5),
        _makeExpense(amount: 11, day: 6),
        _makeExpense(amount: 12, day: 7),
        _makeExpense(amount: 10, day: 8),
        _makeExpense(amount: 500, day: 9),
        _makeExpense(amount: 11, day: 10),
      ];
      final anomalies = service.detectAnomalies(expenses);
      expect(anomalies.length, 1);
      expect(anomalies.first.amount, 500);
    });
  });

  group('Pattern Analysis', () {
    test('returns summary for empty data', () {
      final result = service.analyzePatterns([]);
      expect(result['summary'], 'No data to analyze.');
    });

    test('detects highest and lowest spending days', () {
      final monday = DateTime(2025, 1, 6); // Monday
      final expenses = [
        _makeExpense(amount: 50, date: monday),
        _makeExpense(amount: 100, date: monday.add(const Duration(days: 5))), // Saturday
      ];
      final result = service.analyzePatterns(expenses);
      expect(result.containsKey('highestSpendingDay'), true);
      expect(result.containsKey('lowestSpendingDay'), true);
    });
  });

  group('Suggestions', () {
    test('returns prompt for few expenses', () {
      final result = service.generateSuggestions([]);
      expect(result.first, contains('Add more expenses'));
    });

    test('generates food-related suggestion', () {
      final expenses = List.generate(10, (i) => _makeExpense(
        amount: 100,
        day: i + 1,
        categoryName: 'Food',
        categoryColor: 0xFFE53935,
      ));
      final result = service.generateSuggestions(expenses);
      expect(result.any((s) => s.contains('food') || s.contains('Food')), true);
    });
  });

  group('Subscription Detection', () {
    test('returns empty for no expenses', () {
      expect(service.detectSubscriptions([]), isEmpty);
    });

    test('detects recurring flagged expense as subscription', () {
      final expenses = [
        _makeExpense(amount: 9.99, day: 1, isRecurring: true),
        _makeExpense(amount: 15.00, day: 5),
        _makeExpense(amount: 9.99, day: 1, isRecurring: true, month: 2),
        _makeExpense(amount: 9.99, day: 1, isRecurring: true, month: 3),
      ];
      final subs = service.detectSubscriptions(expenses);
      expect(subs, isNotEmpty);
      expect(subs.first.amount, 9.99);
    });
  });

  group('What-If Simulator', () {
    test('returns zero reduction for empty reductions', () {
      final result = service.simulateWhatIf(
        monthExpenses: [],
        daysInMonth: 30,
        categoryReductions: {},
      );
      expect(result['reduction'], 0);
      expect(result['currentForecast'], 0);
      expect(result['adjustedForecast'], 0);
    });

    test('reduces forecast by category percentage', () {
      final expenses = [
        _makeExpense(amount: 200, day: 1, categoryId: 1, categoryName: 'Food'),
        _makeExpense(amount: 300, day: 5, categoryId: 1, categoryName: 'Food'),
        _makeExpense(amount: 100, day: 10, categoryId: 2, categoryName: 'Transport'),
      ];
      final result = service.simulateWhatIf(
        monthExpenses: expenses,
        daysInMonth: 30,
        categoryReductions: {1: 0.2}, // 20% off category 1
      );
      expect(result['reduction'], 100.0); // 20% of 500
      expect(result['difference'], 100.0);
      expect(result['adjustedForecast'], lessThan(result['currentForecast']));
    });
  });
}

ExpenseModel _makeExpense({
  double amount = 10,
  int day = 1,
  int month = 1,
  String categoryName = 'General',
  int categoryColor = 0xFF757575,
  int categoryId = 1,
  bool isRecurring = false,
  DateTime? date,
}) {
  final d = date ?? DateTime(2025, month, day);
  return ExpenseModel(
    id: 0,
    amount: amount,
    categoryId: categoryId,
    date: d,
    createdAt: d,
    updatedAt: d,
    isRecurring: isRecurring,
    category: CategoryModel(
      id: categoryId,
      name: categoryName,
      icon: 'receipt',
      color: categoryColor,
      isCustom: false,
      type: 'expense',
      isActive: true,
    ),
  );
}
