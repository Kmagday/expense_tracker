import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/data/database/app_database.dart';
import 'package:expense_tracker/data/repositories/expense_repository.dart';
import 'package:expense_tracker/data/models/expense_models.dart';
import 'package:drift/native.dart';

void main() {
  late AppDatabase db;
  late ExpenseRepository repo;

  setUp(() async {
    db = AppDatabase.connect(NativeDatabase.memory());
    await db.seedDefaultCategories();
    await db.seedDefaultAccounts();
    repo = ExpenseRepository(db);
  });

  tearDown(() {
    db.close();
  });

  group('Savings Goals', () {
    test('CRUD cycle', () async {
      final now = DateTime.now();
      final goal = SavingsGoal(
        id: 'test_1', targetAmount: 1000,
        targetDate: now.add(const Duration(days: 90)),
        description: 'Emergency fund', savedAmount: 200, createdAt: now,
      );

      await repo.saveGoal(goal);
      var goals = await repo.getGoals();
      expect(goals.length, 1);
      expect(goals.first.id, 'test_1');
      expect(goals.first.targetAmount, 1000);

      final updated = SavingsGoal(
        id: 'test_1', targetAmount: 1500,
        targetDate: now.add(const Duration(days: 90)),
        description: 'Emergency fund', savedAmount: 500, createdAt: now,
      );
      await repo.saveGoal(updated);
      goals = await repo.getGoals();
      expect(goals.length, 1);
      expect(goals.first.targetAmount, 1500);
      expect(goals.first.savedAmount, 500);

      await repo.deleteGoal('test_1');
      goals = await repo.getGoals();
      expect(goals, isEmpty);
    });

    test('handles multiple goals', () async {
      final now = DateTime.now();
      await repo.saveGoal(SavingsGoal(
        id: 'a', targetAmount: 1000, targetDate: now.add(const Duration(days: 30)),
        description: 'Goal A', createdAt: now,
      ));
      await repo.saveGoal(SavingsGoal(
        id: 'b', targetAmount: 2000, targetDate: now.add(const Duration(days: 60)),
        description: 'Goal B', createdAt: now,
      ));
      await repo.saveGoal(SavingsGoal(
        id: 'c', targetAmount: 3000, targetDate: now.add(const Duration(days: 90)),
        description: 'Goal C', createdAt: now,
      ));

      final goals = await repo.getGoals();
      expect(goals.length, 3);
    });
  });

  group('Expenses', () {
    test('add and retrieve expense', () async {
      final cats = await repo.getCategories(type: 'expense');
      expect(cats, isNotEmpty);

      final expense = await repo.addExpense(
        amount: 42.50,
        categoryId: cats.first.id,
        date: DateTime.now(),
        note: 'Test expense',
        paymentMethod: 'Card',
        tags: ['test', 'demo'],
      );
      expect(expense.amount, 42.50);
      expect(expense.note, 'Test expense');
      expect(expense.tags, ['test', 'demo']);
      expect(expense.paymentMethod, 'Card');
    });

    test('soft delete and restore cycle', () async {
      final cats = await repo.getCategories(type: 'expense');
      final expense = await repo.addExpense(
        amount: 100, categoryId: cats.first.id, date: DateTime.now(),
      );
      expect((await repo.getExpenses()).length, 1);

      await repo.deleteExpense(expense.id);
      expect((await repo.getExpenses()).length, 0);

      final deleted = await repo.getDeletedExpenses();
      expect(deleted.length, 1);
      expect(deleted.first.id, expense.id);

      await repo.restoreExpense(expense.id);
      expect((await repo.getExpenses()).length, 1);
      expect((await repo.getDeletedExpenses()).length, 0);
    });

    test('hard delete removes permanently', () async {
      final cats = await repo.getCategories(type: 'expense');
      final expense = await repo.addExpense(
        amount: 50, categoryId: cats.first.id, date: DateTime.now(),
      );
      await repo.deleteExpense(expense.id);
      await repo.hardDeleteExpense(expense.id);
      expect((await repo.getDeletedExpenses()).length, 0);
    });
  });

  group('Search', () {
    test('search by note text', () async {
      final cats = await repo.getCategories(type: 'expense');
      await repo.addExpense(
        amount: 25, categoryId: cats.first.id, date: DateTime.now(),
        note: 'Lunch at McDonalds',
      );
      await repo.addExpense(
        amount: 50, categoryId: cats.first.id, date: DateTime.now(),
        note: 'Dinner at Burger King',
      );
      await repo.addExpense(
        amount: 15, categoryId: cats.first.id, date: DateTime.now(),
        note: 'Coffee',
      );

      final results = await repo.searchExpenses('Burger');
      expect(results.length, 1);
      expect(results.first.note, contains('Burger'));
    });

    test('search by amount range', () async {
      final cats = await repo.getCategories(type: 'expense');
      for (final amount in [10.0, 25.0, 50.0, 100.0]) {
        await repo.addExpense(
          amount: amount, categoryId: cats.first.id, date: DateTime.now(),
        );
      }

      final results = await repo.searchExpenses('', minAmount: 25, maxAmount: 75);
      expect(results.length, 2);
      expect(results.every((e) => e.amount >= 25 && e.amount <= 75), true);
    });

    test('search by tag', () async {
      final cats = await repo.getCategories(type: 'expense');
      await repo.addExpense(
        amount: 30, categoryId: cats.first.id, date: DateTime.now(),
        tags: ['groceries', 'food'],
      );
      await repo.addExpense(
        amount: 20, categoryId: cats.first.id, date: DateTime.now(),
        tags: ['transport'],
      );

      final results = await repo.searchExpenses('', tags: ['food']);
      expect(results.length, 1);
      expect(results.first.tags, contains('food'));
    });
  });

  group('Upcoming Bills', () {
    test('returns recurring expenses within range', () async {
      final cats = await repo.getCategories(type: 'expense');
      final now = DateTime.now();

      await repo.addExpense(
        amount: 100, categoryId: cats.first.id, date: now,
        isRecurring: true, recurringFrequency: 'monthly',
      );
      await repo.addExpense(
        amount: 50, categoryId: cats.first.id, date: now.add(const Duration(days: 60)),
        isRecurring: true, recurringFrequency: 'monthly',
      );
      await repo.addExpense(
        amount: 200, categoryId: cats.first.id, date: now.add(const Duration(days: 400)),
        isRecurring: true, recurringFrequency: 'yearly',
      );

      final bills = await repo.getUpcomingBills(days: 90);
      expect(bills.length, 2);
    });
  });
}
