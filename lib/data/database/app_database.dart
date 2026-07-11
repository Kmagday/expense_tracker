import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'tables/categories_table.dart';
import 'tables/expenses_table.dart';
import 'tables/incomes_table.dart';
import 'tables/budgets_table.dart';
import 'tables/accounts_table.dart';
import 'tables/transfers_table.dart';
import 'tables/savings_goals_table.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';
import 'connection_stub.dart'
    if (dart.library.io) 'connection.native.dart'
    if (dart.library.html) 'connection.web.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    CategoriesTable,
    ExpensesTable,
    IncomesTable,
    BudgetsTable,
    AccountsTable,
    TransfersTable,
    SavingsGoalsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(createExecutor());
  AppDatabase.connect(super.executor);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        debugPrint('[DB] creating all tables');
        await m.createAll();
        await seedDefaultCategories();
        await seedDefaultAccounts();
      },
      onUpgrade: (m, from, to) async {
        debugPrint('[DB] migrating schema v$from → v$to');
        if (from < 2) {
          await m.createTable(accountsTable);
          await m.createTable(transfersTable);
          await m.addColumn(expensesTable, expensesTable.accountId);
          await m.addColumn(incomesTable, incomesTable.accountId);
          await seedDefaultAccounts();
        }
        if (from < 3) {
          await m.addColumn(expensesTable, expensesTable.tags);
          await m.addColumn(incomesTable, incomesTable.tags);
        }
        if (from < 4) {
          await m.createTable(savingsGoalsTable);
          await migrateSavingsGoalsFromPrefs();
        }
        if (from < 5) {
          await customStatement('''
            CREATE TABLE IF NOT EXISTS debts_table (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              type TEXT NOT NULL,
              principal REAL NOT NULL,
              current_balance REAL NOT NULL,
              interest_rate REAL NOT NULL DEFAULT 0,
              min_payment REAL NOT NULL DEFAULT 0,
              due_date TEXT NOT NULL,
              linked_account_id INTEGER,
              is_active INTEGER NOT NULL DEFAULT 1,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        }
        if (from < 6) {
          await m.addColumn(accountsTable, accountsTable.principal);
          await m.addColumn(accountsTable, accountsTable.interestRate);
          await m.addColumn(accountsTable, accountsTable.minPayment);
          await m.addColumn(accountsTable, accountsTable.dueDate);
          await customStatement('DROP TABLE IF EXISTS debts_table');
        }
      },
    );
  }

  Future<void> seedDefaultCategories() async {
    final count = await select(categoriesTable).get().then((r) => r.length);
    if (count > 0) return;

    debugPrint('[DB] seeding default categories');
    final now = DateTime.now();
    final defaults = [
      (name: 'Food', icon: 'restaurant', color: 0xFFE53935, type: 'expense'),
      (name: 'Transport', icon: 'directions_car', color: 0xFF1E88E5, type: 'expense'),
      (name: 'Bills', icon: 'receipt', color: 0xFF43A047, type: 'expense'),
      (name: 'Shopping', icon: 'shopping_bag', color: 0xFF8E24AA, type: 'expense'),
      (name: 'Entertainment', icon: 'movie', color: 0xFFFB8C00, type: 'expense'),
      (name: 'Health', icon: 'local_hospital', color: 0xFF00897B, type: 'expense'),
      (name: 'Education', icon: 'school', color: 0xFF3949AB, type: 'expense'),
      (name: 'Other', icon: 'more_horiz', color: 0xFF757575, type: 'expense'),
      (name: 'Salary', icon: 'work', color: 0xFF43A047, type: 'income'),
      (name: 'Freelance', icon: 'computer', color: 0xFF1E88E5, type: 'income'),
      (name: AccountTypes.investment, icon: 'trending_up', color: 0xFF8E24AA, type: 'income'),
      (name: 'Gift', icon: 'card_giftcard', color: 0xFFFB8C00, type: 'income'),
    ];
    for (final c in defaults) {
      await into(categoriesTable).insert(CategoriesTableCompanion.insert(
        name: c.name,
        icon: Value(c.icon),
        color: Value(c.color),
        type: Value(c.type),
        isCustom: const Value(false),
        createdAt: now,
        updatedAt: now,
      ));
    }
  }

  Future<void> seedDefaultAccounts() async {
    final count = await select(accountsTable).get().then((r) => r.length);
    if (count > 0) return;
    debugPrint('[DB] seeding default accounts');
    final now = DateTime.now();
    final defaults = [
      (name: 'Cash', type: 'Cash', icon: 'money', color: 0xFF43A047),
      (name: DefaultAccounts.bankAccount, type: 'Checking', icon: 'account_balance', color: 0xFF1E88E5),
    ];
    for (final a in defaults) {
      await into(accountsTable).insert(AccountsTableCompanion.insert(
        name: a.name,
        type: a.type,
        icon: Value(a.icon),
        color: Value(a.color),
        createdAt: now,
        updatedAt: now,
      ));
    }
  }

  Future<void> updateAccountBalance(int accountId, double delta) async {
    final account = await (select(accountsTable)..where((t) => t.id.equals(accountId))).getSingleOrNull();
    if (account == null) return;
    await (update(accountsTable)..where((t) => t.id.equals(accountId))).write(
      AccountsTableCompanion(
        balance: Value(account.balance + delta),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ── SharedPreferences → SQLite Migration ──

  Future<void> migrateFromSharedPrefs() async {
    debugPrint('[DB] checking for SharedPreferences data to migrate');
    final prefs = await SharedPreferences.getInstance();
    bool hasData = false;
    for (final key in ['categories', 'expenses', 'incomes', 'budgets']) {
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty && raw != '[]') { hasData = true; break; }
    }
    if (!hasData) { debugPrint('[DB] no SharedPreferences data to migrate'); return; }

    debugPrint('[DB] migrating data from SharedPreferences');

    final categoriesRaw = prefs.getString('categories');
    if (categoriesRaw != null && categoriesRaw.isNotEmpty && categoriesRaw != '[]') {
      final List<dynamic> catList = _decodeJson(categoriesRaw);
      for (final c in catList) {
        final existing = await (select(categoriesTable)
              ..where((t) => t.name.equals(c['name'] as String? ?? '')))
            .get();
        if (existing.isNotEmpty) continue;
        await into(categoriesTable).insert(CategoriesTableCompanion.insert(
          name: c['name'] as String? ?? 'Other',
          icon: Value<String>(c['icon'] as String? ?? 'more_horiz'),
          color: Value<int>(c['color'] as int? ?? 0xFF757575),
          type: Value<String>(c['type'] as String? ?? 'expense'),
          isCustom: Value<bool>(c['isCustom'] as bool? ?? true),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    }

    final allCats = await select(categoriesTable).get();
    final catMap = {for (final c in allCats) c.name: c.id};

    final expensesRaw = prefs.getString('expenses');
    if (expensesRaw != null && expensesRaw.isNotEmpty && expensesRaw != '[]') {
      final List<dynamic> expList = _decodeJson(expensesRaw);
      for (final e in expList) {
        final catId = _resolveCatId(e, catMap);
        await into(expensesTable).insert(ExpensesTableCompanion.insert(
          amount: (e['amount'] as num?)?.toDouble() ?? 0,
          categoryId: catId,
          date: e['date'] != null ? DateTime.parse(e['date'] as String) : DateTime.now(),
          note: Value<String?>(e['note'] as String?),
          paymentMethod: Value<String?>(e['paymentMethod'] as String?),
          receiptPath: Value<String?>(e['receiptPath'] as String?),
          isRecurring: Value(e['isRecurring'] as bool? ?? false),
          recurringFrequency: Value<String?>(e['recurringFrequency'] as String?),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    }

    final incomesRaw = prefs.getString('incomes');
    if (incomesRaw != null && incomesRaw.isNotEmpty && incomesRaw != '[]') {
      final List<dynamic> incList = _decodeJson(incomesRaw);
      for (final i in incList) {
        await into(incomesTable).insert(IncomesTableCompanion.insert(
          amount: (i['amount'] as num?)?.toDouble() ?? 0,
          categoryId: _resolveCatId(i, catMap),
          source: Value<String?>(i['source'] as String?),
          date: i['date'] != null ? DateTime.parse(i['date'] as String) : DateTime.now(),
          note: Value<String?>(i['note'] as String?),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    }

    final budgetsRaw = prefs.getString('budgets');
    if (budgetsRaw != null && budgetsRaw.isNotEmpty && budgetsRaw != '[]') {
      final List<dynamic> budList = _decodeJson(budgetsRaw);
      for (final b in budList) {
        await into(budgetsTable).insert(BudgetsTableCompanion.insert(
          categoryId: Value<int?>(b['categoryId'] as int?),
          month: b['month'] as int? ?? DateTime.now().month,
          year: b['year'] as int? ?? DateTime.now().year,
          budgetAmount: (b['budgetAmount'] as num?)?.toDouble() ?? 0,
          spentAmount: Value<double>((b['spentAmount'] as num?)?.toDouble() ?? 0),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    }

    debugPrint('[DB] migration complete');
  }

  int _resolveCatId(Map<String, dynamic> item, Map<String, int> catMap) {
    final catId = item['categoryId'] as int?;
    if (catId != null && catMap.values.contains(catId)) return catId;
    final catName = item['categoryName'] as String?;
    if (catName != null && catMap.containsKey(catName)) return catMap[catName]!;
    return catMap['Other'] ?? 1;
  }

  List<dynamic> _decodeJson(String raw) {
    try { return jsonDecode(raw) as List<dynamic>; }
    catch (_) { return []; }
  }

  // ── Savings Goals Migration from SharedPreferences ──

  Future<void> migrateSavingsGoalsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(PrefKeys.savingsGoals);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List;
      for (final e in list) {
        final m = e as Map<String, dynamic>;
        await into(savingsGoalsTable).insert(SavingsGoalsTableCompanion.insert(
          id: m['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
          targetAmount: (m['targetAmount'] as num?)?.toDouble() ?? 0,
          targetDate: m['targetDate'] != null ? DateTime.parse(m['targetDate'] as String) : DateTime.now(),
          description: m['description'] as String? ?? '',
          savedAmount: Value<double>((m['savedAmount'] as num?)?.toDouble() ?? 0),
          createdAt: m['createdAt'] != null ? DateTime.parse(m['createdAt'] as String) : DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
      debugPrint('[DB] migrated ${list.length} savings goals from SharedPreferences');
    } catch (e) {
      debugPrint('[DB] failed to migrate savings goals: $e');
    }
  }

  // ── Soft Delete / Restore ──

  Future<void> softDeleteExpense(int id) async {
    await (update(expensesTable)..where((t) => t.id.equals(id))).write(
      ExpensesTableCompanion(isDeleted: const Value(true), deletedAt: Value(DateTime.now())),
    );
  }

  Future<void> softDeleteIncome(int id) async {
    await (update(incomesTable)..where((t) => t.id.equals(id))).write(
      IncomesTableCompanion(isDeleted: const Value(true), deletedAt: Value(DateTime.now())),
    );
  }

  Future<void> restoreExpense(int id) async {
    await (update(expensesTable)..where((t) => t.id.equals(id))).write(
      ExpensesTableCompanion(isDeleted: const Value(false), deletedAt: const Value(null)),
    );
  }

  Future<void> restoreIncome(int id) async {
    await (update(incomesTable)..where((t) => t.id.equals(id))).write(
      IncomesTableCompanion(isDeleted: const Value(false), deletedAt: const Value(null)),
    );
  }

  Future<void> hardDeleteExpense(int id) async {
    await (delete(expensesTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> hardDeleteIncome(int id) async {
    await (delete(incomesTable)..where((t) => t.id.equals(id))).go();
  }

  Future<List<ExpenseDb>> getDeletedExpenses() async {
    return (select(expensesTable)..where((t) => t.isDeleted.equals(true))).get();
  }

  Future<List<IncomeDb>> getDeletedIncomes() async {
    return (select(incomesTable)..where((t) => t.isDeleted.equals(true))).get();
  }

  Future<int> purgeOldDeleted() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final deletedExpenses = await (select(expensesTable)
      ..where((t) => t.isDeleted.equals(true) & t.deletedAt.isNotNull() & t.deletedAt.isSmallerThan(Variable<DateTime>(cutoff))))
        .get();
    final deletedIncomes = await (select(incomesTable)
      ..where((t) => t.isDeleted.equals(true) & t.deletedAt.isNotNull() & t.deletedAt.isSmallerThan(Variable<DateTime>(cutoff))))
        .get();
    for (final e in deletedExpenses) { await (delete(expensesTable)..where((t) => t.id.equals(e.id))).go(); }
    for (final i in deletedIncomes) { await (delete(incomesTable)..where((t) => t.id.equals(i.id))).go(); }
    return deletedExpenses.length + deletedIncomes.length;
  }

  Future<void> updateBudgetSpending(int month, int year, int categoryId, double delta) async {
    final budgets = await (select(budgetsTable)
          ..where((t) =>
              t.month.equals(month) & t.year.equals(year) &
              (t.categoryId.equals(categoryId) | t.categoryId.isNull())))
        .get();
    for (final b in budgets) {
      await (update(budgetsTable)..where((t) => t.id.equals(b.id))).write(
        BudgetsTableCompanion(spentAmount: Value(b.spentAmount + delta), updatedAt: Value(DateTime.now())),
      );
    }
  }
}
