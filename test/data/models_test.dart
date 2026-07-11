import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/data/models/expense_models.dart';

void main() {
  group('CategoryModel', () {
    test('creates from parameters', () {
      final cat = CategoryModel(
        id: 1,
        name: 'Food',
        icon: 'restaurant',
        color: 0xFFE53935,
        isCustom: false,
        type: 'expense',
        isActive: true,
      );
      expect(cat.name, 'Food');
      expect(cat.icon, 'restaurant');
      expect(cat.type, 'expense');
    });
  });

  group('ExpenseModel', () {
    test('creates from parameters', () {
      final now = DateTime.now();
      final expense = ExpenseModel(
        id: 1,
        amount: 25.50,
        categoryId: 1,
        date: now,
        note: 'Lunch',
        paymentMethod: 'Card',
        isRecurring: false,
        createdAt: now,
        updatedAt: now,
      );
      expect(expense.amount, 25.50);
      expect(expense.note, 'Lunch');
      expect(expense.paymentMethod, 'Card');
      expect(expense.tags, isEmpty);
    });

    test('fromMap/toMap roundtrip with tags', () {
      final now = DateTime.now();
      final model = ExpenseModel(
        id: 1,
        amount: 25.50,
        categoryId: 2,
        date: now,
        note: 'Lunch',
        tags: ['food', 'groceries'],
        paymentMethod: 'Card',
        isRecurring: true,
        recurringFrequency: 'monthly',
        createdAt: now,
        updatedAt: now,
      );
      final map = model.toMap();
      final restored = ExpenseModel.fromMap(map);
      expect(restored.amount, model.amount);
      expect(restored.tags, ['food', 'groceries']);
      expect(restored.isRecurring, true);
      expect(restored.recurringFrequency, 'monthly');
    });

    test('fromMap handles null and empty tags', () {
      final map = {
        'id': 1, 'amount': 10.0, 'categoryId': 1,
        'date': DateTime.now().toIso8601String(),
        'tags': null,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      final model = ExpenseModel.fromMap(map);
      expect(model.tags, isEmpty);

      map['tags'] = '';
      final model2 = ExpenseModel.fromMap(map);
      expect(model2.tags, isEmpty);
    });
  });

  group('IncomeModel', () {
    test('fromMap/toMap roundtrip with tags', () {
      final now = DateTime.now();
      final model = IncomeModel(
        id: 1,
        amount: 1000,
        categoryId: 1,
        date: now,
        source: 'Freelance',
        tags: ['work', 'project-a'],
        createdAt: now,
        updatedAt: now,
      );
      final map = model.toMap();
      final restored = IncomeModel.fromMap(map);
      expect(restored.amount, model.amount);
      expect(restored.tags, ['work', 'project-a']);
      expect(restored.source, 'Freelance');
    });
  });

  group('BudgetModel', () {
    test('computes remaining and percentage', () {
      final budget = BudgetModel(
        id: 1,
        month: 1,
        year: 2025,
        budgetAmount: 1000,
        spentAmount: 250,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );
      expect(budget.remaining, 750);
      expect(budget.percentage, 25.0);
    });

    test('percentage handles zero budget', () {
      final budget = BudgetModel(
        id: 1,
        month: 1,
        year: 2025,
        budgetAmount: 0,
        spentAmount: 250,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );
      expect(budget.percentage, 0);
    });
  });

  group('DashboardSummary', () {
    test('creates with values', () {
      final summary = const DashboardSummary(
        totalToday: 50,
        totalThisWeek: 300,
        totalThisMonth: 1200,
        totalIncomeThisMonth: 5000,
        remainingBudget: 800,
        topCategory: 'Food',
        topCategoryAmount: 400,
      );
      expect(summary.totalToday, 50);
      expect(summary.topCategory, 'Food');
      expect(summary.remainingBudget, 800);
    });
  });

  group('SavingsGoal', () {
    test('creates from parameters', () {
      final now = DateTime.now();
      final goal = SavingsGoal(
        id: 'goal_1',
        targetAmount: 1000,
        targetDate: now.add(const Duration(days: 90)),
        description: 'Emergency fund',
        savedAmount: 250,
        createdAt: now,
      );
      expect(goal.id, 'goal_1');
      expect(goal.description, 'Emergency fund');
      expect(goal.targetAmount, 1000);
      expect(goal.savedAmount, 250);
    });

    test('computes progress percentage', () {
      final goal = SavingsGoal(
        id: 'g1', targetAmount: 1000, targetDate: DateTime(2025, 6, 1),
        description: 'Save', savedAmount: 250, createdAt: DateTime(2025, 1, 1),
      );
      expect(goal.progress, 25.0);
    });

    test('computes remaining amount', () {
      final goal = SavingsGoal(
        id: 'g1', targetAmount: 1000, targetDate: DateTime(2025, 6, 1),
        description: 'Save', savedAmount: 250, createdAt: DateTime(2025, 1, 1),
      );
      expect(goal.remaining, 750);
    });

    test('fromMap/toMap roundtrip', () {
      final now = DateTime.now();
      final goal = SavingsGoal(
        id: 'g1', targetAmount: 5000, targetDate: now.add(const Duration(days: 180)),
        description: 'New laptop', savedAmount: 1200, createdAt: now,
      );
      final map = goal.toMap();
      final restored = SavingsGoal.fromMap(map);
      expect(restored.id, goal.id);
      expect(restored.targetAmount, goal.targetAmount);
      expect(restored.description, goal.description);
      expect(restored.savedAmount, goal.savedAmount);
    });
  });
}
