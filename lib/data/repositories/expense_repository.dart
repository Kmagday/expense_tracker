import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../models/expense_models.dart';

class ExpenseRepository {
  final AppDatabase _db;

  ExpenseRepository(this._db);

  // ── Categories ──

  Future<List<CategoryModel>> getCategories({String? type}) async {
    var query = _db.select(_db.categoriesTable)..where((t) => t.isActive.equals(true));
    if (type != null) query.where((t) => t.type.equals(type));
    final all = await query.get();
    if (all.isEmpty) {
      debugPrint('[ExpenseRepo] categories empty, seeding defaults');
      await _db.seedDefaultCategories();
      query = _db.select(_db.categoriesTable)..where((t) => t.isActive.equals(true));
      if (type != null) query.where((t) => t.type.equals(type));
      return (await query.get()).map(_catFromDb).toList();
    }
    return all.map(_catFromDb).toList();
  }

  Future<CategoryModel?> getCategory(int id) async {
    final cat = await (_db.select(_db.categoriesTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    return cat != null ? _catFromDb(cat) : null;
  }

  Future<CategoryModel> addCategory(String name, String icon, int color, String type) async {
    final now = DateTime.now();
    final id = await _db.into(_db.categoriesTable).insert(CategoriesTableCompanion.insert(
      name: name,
      icon: Value(icon),
      color: Value(color),
      type: Value(type),
      createdAt: now,
      updatedAt: now,
    ));
    return _catFromDb(await (_db.select(_db.categoriesTable)..where((t) => t.id.equals(id))).getSingle());
  }

  // ── Mapping ──

  CategoryModel _catFromDb(dynamic c) => CategoryModel(
    id: c.id, name: c.name, icon: c.icon, color: c.color,
    isCustom: c.isCustom, type: c.type, isActive: c.isActive,
  );

  AccountModel _accFromDb(dynamic a) => AccountModel(
    id: a.id, name: a.name, type: a.type,
    balance: a.balance, icon: a.icon, color: a.color,
    isActive: a.isActive,
    principal: a.principal, interestRate: a.interestRate,
    minPayment: a.minPayment, dueDate: a.dueDate,
  );

  List<String> _tags(dynamic e) {
    final raw = e.tags as String?;
    return raw != null && raw.isNotEmpty
        ? raw.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList()
        : const [];
  }

  Future<ExpenseModel> _expWithCat(dynamic e) async {
    final cat = await getCategory(e.categoryId);
    return ExpenseModel(
      id: e.id, amount: e.amount, categoryId: e.categoryId,
      date: e.date, note: e.note, accountId: e.accountId,
      paymentMethod: e.paymentMethod, receiptPath: e.receiptPath,
      tags: _tags(e),
      isRecurring: e.isRecurring, recurringFrequency: e.recurringFrequency,
      createdAt: e.createdAt, updatedAt: e.updatedAt, category: cat,
    );
  }

  Future<IncomeModel> _incWithCat(dynamic i) async {
    final cat = await getCategory(i.categoryId);
    return IncomeModel(
      id: i.id, amount: i.amount, categoryId: i.categoryId,
      source: i.source, date: i.date, note: i.note,
      accountId: i.accountId, tags: _tags(i),
      createdAt: i.createdAt, updatedAt: i.updatedAt, category: cat,
    );
  }

  Future<BudgetModel> _budWithCat(dynamic b) async {
    final cat = b.categoryId != null ? await getCategory(b.categoryId!) : null;
    return BudgetModel(
      id: b.id, categoryId: b.categoryId,
      month: b.month, year: b.year,
      budgetAmount: b.budgetAmount, spentAmount: b.spentAmount,
      createdAt: b.createdAt, updatedAt: b.updatedAt, category: cat,
    );
  }

  // ── Accounts ──

  Future<List<AccountModel>> getAccounts() async {
    final rows = await (_db.select(_db.accountsTable)..where((t) => t.isActive.equals(true))).get();
    return rows.map(_accFromDb).toList();
  }

  Future<AccountModel?> getAccount(int id) async {
    final a = await (_db.select(_db.accountsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    return a != null ? _accFromDb(a) : null;
  }

  Future<AccountModel> addAccount(String name, String type, {String icon = 'account_balance', int color = 0xFF1E88E5, double balance = 0, double? principal, double? interestRate, double? minPayment, DateTime? dueDate}) async {
    final now = DateTime.now();
    debugPrint('[ExpenseRepo] addAccount - name: $name, type: $type, balance: $balance, principal: $principal');
    final id = await _db.into(_db.accountsTable).insert(AccountsTableCompanion.insert(
      name: name, type: type,
      balance: Value(balance),
      icon: Value(icon), color: Value(color),
      principal: Value(principal), interestRate: Value(interestRate),
      minPayment: Value(minPayment), dueDate: Value(dueDate),
      createdAt: now, updatedAt: now,
    ));
    return _accFromDb(await (_db.select(_db.accountsTable)..where((t) => t.id.equals(id))).getSingle());
  }

  Future<void> updateAccount(int id, {String? name, String? type, String? icon, int? color, double? balance, double? principal, double? interestRate, double? minPayment, DateTime? dueDate}) async {
    debugPrint('[ExpenseRepo] updateAccount id=$id - name: $name, type: $type, balance: $balance');
    await (_db.update(_db.accountsTable)..where((t) => t.id.equals(id))).write(
      AccountsTableCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        type: type != null ? Value(type) : const Value.absent(),
        icon: icon != null ? Value(icon) : const Value.absent(),
        color: color != null ? Value(color) : const Value.absent(),
        balance: balance != null ? Value(balance) : const Value.absent(),
        principal: principal != null ? Value(principal) : const Value.absent(),
        interestRate: interestRate != null ? Value(interestRate) : const Value.absent(),
        minPayment: minPayment != null ? Value(minPayment) : const Value.absent(),
        dueDate: dueDate != null ? Value(dueDate) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteAccount(int id) async {
    debugPrint('[ExpenseRepo] deleteAccount id=$id');
    await (_db.update(_db.accountsTable)..where((t) => t.id.equals(id))).write(
      AccountsTableCompanion(isActive: const Value(false), updatedAt: Value(DateTime.now())),
    );
  }

  Future<void> updateAccountBalance(int accountId, double delta) =>
      _db.updateAccountBalance(accountId, delta);

  // ── Transfers ──

  Future<TransferModel> addTransfer({required int fromAccountId, required int toAccountId, required double amount, DateTime? date, String? note}) async {
    final now = DateTime.now();
    final d = date ?? now;
    debugPrint('[ExpenseRepo] addTransfer - from: $fromAccountId, to: $toAccountId, amount: $amount, date: $d');
    final id = await _db.into(_db.transfersTable).insert(TransfersTableCompanion.insert(
      fromAccountId: fromAccountId, toAccountId: toAccountId,
      amount: amount, date: d,
      note: Value<String?>(note),
      createdAt: now, updatedAt: now,
    ));
    await _db.updateAccountBalance(fromAccountId, -amount);
    await _db.updateAccountBalance(toAccountId, amount);
    final row = await (_db.select(_db.transfersTable)..where((t) => t.id.equals(id))).getSingle();
    return TransferModel(
      id: row.id, fromAccountId: row.fromAccountId, toAccountId: row.toAccountId,
      amount: row.amount, note: row.note, date: row.date,
      createdAt: row.createdAt, updatedAt: row.updatedAt,
    );
  }

  Future<List<TransferModel>> getTransfers() async {
    final rows = await (_db.select(_db.transfersTable)..orderBy([(t) => OrderingTerm.desc(t.date)])).get();
    return rows.map((r) => TransferModel(
      id: r.id, fromAccountId: r.fromAccountId, toAccountId: r.toAccountId,
      amount: r.amount, note: r.note, date: r.date,
      createdAt: r.createdAt, updatedAt: r.updatedAt,
    )).toList();
  }

  Future<List<TransferModel>> getTransfersForAccount(int accountId) async {
    final rows = await (_db.select(_db.transfersTable)
      ..where((t) => t.fromAccountId.equals(accountId) | t.toAccountId.equals(accountId))
      ..orderBy([(t) => OrderingTerm.desc(t.date)])
    ).get();
    return rows.map((r) => TransferModel(
      id: r.id, fromAccountId: r.fromAccountId, toAccountId: r.toAccountId,
      amount: r.amount, note: r.note, date: r.date,
      createdAt: r.createdAt, updatedAt: r.updatedAt,
    )).toList();
  }

  // ── Expenses ──

  Future<List<ExpenseModel>> getExpenses({DateTime? from, DateTime? to, int? categoryId, String? paymentMethod, int? accountId, String? tag}) async {
    var query = _db.select(_db.expensesTable)..where((t) => t.isDeleted.equals(false));
    if (from != null) query.where((t) => t.date.isBiggerThan(Variable<DateTime>(from.subtract(const Duration(days: 1)))));
    if (to != null) query.where((t) => t.date.isSmallerThan(Variable<DateTime>(to.add(const Duration(days: 1)))));
    if (categoryId != null) query.where((t) => t.categoryId.equals(categoryId));
    if (paymentMethod != null) query.where((t) => t.paymentMethod.equals(paymentMethod));
    if (accountId != null) query.where((t) => t.accountId.equals(accountId));
    if (tag != null) query.where((t) => t.tags.like('%$tag%'));
    query.orderBy([(t) => OrderingTerm.desc(t.date)]);
    final rows = await query.get();
    final result = <ExpenseModel>[];
    for (final r in rows) { result.add(await _expWithCat(r)); }
    debugPrint('[ExpenseRepo] getExpenses -> ${result.length} results');
    return result;
  }

  Future<List<ExpenseModel>> getRecurringExpenses() async {
    final rows = await (_db.select(_db.expensesTable)
      ..where((t) => t.isRecurring.equals(true) & t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.date)])
    ).get();
    final result = <ExpenseModel>[];
    for (final r in rows) { result.add(await _expWithCat(r)); }
    return result;
  }

  Future<List<ExpenseModel>> getUpcomingBills({int days = 30}) async {
    final now = DateTime.now();
    final future = now.add(Duration(days: days));
    final rows = await (_db.select(_db.expensesTable)
      ..where((t) => t.isRecurring.equals(true) & t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.date)])
    ).get();
    final result = <ExpenseModel>[];
    for (final r in rows) {
      final exp = await _expWithCat(r);
      if (exp.date.isBefore(future) || exp.date.isAtSameMomentAs(future)) {
        result.add(exp);
      }
    }
    return result;
  }

  DateTime? _nextOccurrence(DateTime from, String? frequency) {
    switch (frequency) {
      case 'daily': return DateTime(from.year, from.month, from.day + 1);
      case 'weekly': return DateTime(from.year, from.month, from.day + 7);
      case 'monthly': return DateTime(from.year, from.month + 1, from.day);
      case 'yearly': return DateTime(from.year + 1, from.month, from.day);
      default: return null;
    }
  }

  Future<int> generateRecurringExpenses() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recurring = await getRecurringExpenses();
    int generated = 0;
    for (final exp in recurring) {
      final next = _nextOccurrence(exp.date, exp.recurringFrequency);
      if (next == null || next.isAfter(today)) continue;
      final existing = await (_db.select(_db.expensesTable)..where((t) =>
        t.isDeleted.equals(false) &
        t.date.equals(next) & t.categoryId.equals(exp.categoryId) &
        t.amount.equals(exp.amount)
      )).get();
      if (existing.isEmpty) {
        await addExpense(
          amount: exp.amount, categoryId: exp.categoryId, date: next,
          note: exp.note, accountId: exp.accountId,
          paymentMethod: exp.paymentMethod, tags: exp.tags,
          isRecurring: false,
        );
        generated++;
      }
    }
    if (generated > 0) debugPrint('[ExpenseRepo] generated $generated recurring expenses');
    return generated;
  }

  Future<ExpenseModel> addExpense({required double amount, required int categoryId, required DateTime date, String? note, int? accountId, String? paymentMethod, String? receiptPath, bool isRecurring = false, String? recurringFrequency, List<String> tags = const []}) async {
    debugPrint('[ExpenseRepo] addExpense - amount: $amount, categoryId: $categoryId, accountId: $accountId, date: $date');
    final now = DateTime.now();
    final id = await _db.into(_db.expensesTable).insert(ExpensesTableCompanion.insert(
      amount: amount, categoryId: categoryId, date: date,
      accountId: Value<int?>(accountId),
      note: Value<String?>(note), paymentMethod: Value<String?>(paymentMethod),
      receiptPath: Value<String?>(receiptPath), isRecurring: Value(isRecurring),
      recurringFrequency: Value<String?>(recurringFrequency),
      tags: Value<String?>(tags.isNotEmpty ? tags.join(',') : null),
      createdAt: now, updatedAt: now,
    ));
    await _db.updateBudgetSpending(date.month, date.year, categoryId, amount);
    if (accountId != null) await _db.updateAccountBalance(accountId, -amount);
    return _expWithCat(await (_db.select(_db.expensesTable)..where((t) => t.id.equals(id))).getSingle());
  }

  Future<void> updateExpense(int id, {double? amount, int? categoryId, DateTime? date, String? note, int? accountId, String? paymentMethod, String? receiptPath, List<String>? tags}) async {
    debugPrint('[ExpenseRepo] updateExpense id=$id - amount: $amount, categoryId: $categoryId, accountId: $accountId');
    final existing = await (_db.select(_db.expensesTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing == null) { debugPrint('[ExpenseRepo] updateExpense id=$id: not found'); return; }
    final oldAmount = existing.amount;
    final newAmount = amount ?? oldAmount;
    final oldAccountId = existing.accountId;
    final newAccountId = accountId;
    if (oldAccountId == newAccountId) {
      if (oldAmount != newAmount && oldAccountId != null) {
        await _db.updateAccountBalance(oldAccountId, oldAmount - newAmount);
      }
    } else {
      if (oldAccountId != null) await _db.updateAccountBalance(oldAccountId, oldAmount);
      if (newAccountId != null) await _db.updateAccountBalance(newAccountId, -newAmount);
    }
    if (categoryId != null && categoryId != existing.categoryId) {
      await _db.updateBudgetSpending(existing.date.month, existing.date.year, existing.categoryId, -existing.amount);
      await _db.updateBudgetSpending(date?.month ?? existing.date.month, date?.year ?? existing.date.year, categoryId, newAmount);
    } else if (amount != null && amount != existing.amount) {
      await _db.updateBudgetSpending(existing.date.month, existing.date.year, existing.categoryId, -existing.amount);
      await _db.updateBudgetSpending(date?.month ?? existing.date.month, date?.year ?? existing.date.year, existing.categoryId, newAmount);
    }
    await (_db.update(_db.expensesTable)..where((t) => t.id.equals(id))).write(
      ExpensesTableCompanion(
        amount: amount != null ? Value(amount) : const Value.absent(),
        categoryId: categoryId != null ? Value(categoryId) : const Value.absent(),
        date: date != null ? Value(date) : const Value.absent(),
        accountId: accountId != null ? Value<int?>(accountId) : Value(accountId),
        note: note != null ? Value<String?>(note) : const Value.absent(),
        paymentMethod: paymentMethod != null ? Value<String?>(paymentMethod) : const Value.absent(),
        receiptPath: receiptPath != null ? Value<String?>(receiptPath) : const Value.absent(),
        tags: tags != null ? Value<String?>(tags.isNotEmpty ? tags.join(',') : null) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteExpense(int id) async {
    debugPrint('[ExpenseRepo] deleteExpense id=$id');
    final existing = await (_db.select(_db.expensesTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing != null) {
      await _db.updateBudgetSpending(existing.date.month, existing.date.year, existing.categoryId, -existing.amount);
      if (existing.accountId != null) await _db.updateAccountBalance(existing.accountId!, existing.amount);
    }
    await _db.softDeleteExpense(id);
  }

  Future<void> restoreExpense(int id) async {
    debugPrint('[ExpenseRepo] restoreExpense id=$id');
    final existing = await (_db.select(_db.expensesTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing != null) {
      await _db.restoreExpense(id);
      await _db.updateBudgetSpending(existing.date.month, existing.date.year, existing.categoryId, existing.amount);
      if (existing.accountId != null) await _db.updateAccountBalance(existing.accountId!, -existing.amount);
    }
  }

  Future<void> hardDeleteExpense(int id) async {
    debugPrint('[ExpenseRepo] hardDeleteExpense id=$id');
    return _db.hardDeleteExpense(id);
  }
  Future<List<ExpenseModel>> getDeletedExpenses() async {
    final rows = await _db.getDeletedExpenses();
    final result = <ExpenseModel>[];
    for (final r in rows) { result.add(await _expWithCat(r)); }
    return result;
  }

  // ── Incomes ──

  Future<List<IncomeModel>> getIncomes({DateTime? from, DateTime? to, int? accountId, String? tag}) async {
    var query = _db.select(_db.incomesTable)..where((t) => t.isDeleted.equals(false));
    if (from != null) query.where((t) => t.date.isBiggerThan(Variable<DateTime>(from.subtract(const Duration(days: 1)))));
    if (to != null) query.where((t) => t.date.isSmallerThan(Variable<DateTime>(to.add(const Duration(days: 1)))));
    if (accountId != null) query.where((t) => t.accountId.equals(accountId));
    if (tag != null) query.where((t) => t.tags.like('%$tag%'));
    query.orderBy([(t) => OrderingTerm.desc(t.date)]);
    final rows = await query.get();
    final result = <IncomeModel>[];
    for (final r in rows) { result.add(await _incWithCat(r)); }
    return result;
  }

  Future<IncomeModel> addIncome({required double amount, required int categoryId, String? source, required DateTime date, String? note, int? accountId, List<String> tags = const []}) async {
    debugPrint('[ExpenseRepo] addIncome - amount: $amount, categoryId: $categoryId, accountId: $accountId, date: $date');
    final now = DateTime.now();
    final id = await _db.into(_db.incomesTable).insert(IncomesTableCompanion.insert(
      amount: amount, categoryId: categoryId, date: date,
      accountId: Value<int?>(accountId),
      source: Value<String?>(source), note: Value<String?>(note),
      tags: Value<String?>(tags.isNotEmpty ? tags.join(',') : null),
      createdAt: now, updatedAt: now,
    ));
    if (accountId != null) await _db.updateAccountBalance(accountId, amount);
    return _incWithCat(await (_db.select(_db.incomesTable)..where((t) => t.id.equals(id))).getSingle());
  }

  Future<void> updateIncome(int id, {double? amount, int? categoryId, String? source, DateTime? date, String? note, int? accountId, List<String>? tags}) async {
    debugPrint('[ExpenseRepo] updateIncome id=$id - amount: $amount, categoryId: $categoryId, accountId: $accountId');
    final existing = await (_db.select(_db.incomesTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing == null) { debugPrint('[ExpenseRepo] updateIncome id=$id: not found'); return; }
    final oldAmount = existing.amount;
    final newAmount = amount ?? oldAmount;
    final oldAccountId = existing.accountId;
    final newAccountId = accountId;
    if (oldAccountId == newAccountId) {
      if (oldAmount != newAmount && oldAccountId != null) {
        await _db.updateAccountBalance(oldAccountId, newAmount - oldAmount);
      }
    } else {
      if (oldAccountId != null) await _db.updateAccountBalance(oldAccountId, -oldAmount);
      if (newAccountId != null) await _db.updateAccountBalance(newAccountId, newAmount);
    }
    await (_db.update(_db.incomesTable)..where((t) => t.id.equals(id))).write(
      IncomesTableCompanion(
        amount: amount != null ? Value(amount) : const Value.absent(),
        categoryId: categoryId != null ? Value(categoryId) : const Value.absent(),
        source: source != null ? Value<String?>(source) : const Value.absent(),
        date: date != null ? Value(date) : const Value.absent(),
        note: note != null ? Value<String?>(note) : const Value.absent(),
        accountId: accountId != null ? Value<int?>(accountId) : Value(accountId),
        tags: tags != null ? Value<String?>(tags.isNotEmpty ? tags.join(',') : null) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteIncome(int id) async {
    debugPrint('[ExpenseRepo] deleteIncome id=$id');
    final existing = await (_db.select(_db.incomesTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing != null) {
      if (existing.accountId != null) await _db.updateAccountBalance(existing.accountId!, -existing.amount);
    }
    await _db.softDeleteIncome(id);
  }
  Future<void> restoreIncome(int id) async {
    debugPrint('[ExpenseRepo] restoreIncome id=$id');
    final existing = await (_db.select(_db.incomesTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing != null) {
      await _db.restoreIncome(id);
      if (existing.accountId != null) await _db.updateAccountBalance(existing.accountId!, existing.amount);
    }
  }
  Future<void> hardDeleteIncome(int id) async {
    debugPrint('[ExpenseRepo] hardDeleteIncome id=$id');
    return _db.hardDeleteIncome(id);
  }

  Future<List<IncomeModel>> getDeletedIncomes() async {
    final rows = await _db.getDeletedIncomes();
    final result = <IncomeModel>[];
    for (final r in rows) { result.add(await _incWithCat(r)); }
    return result;
  }

  // ── Budgets ──

  Future<List<BudgetModel>> getBudgets(int month, int year) async {
    final rows = await (_db.select(_db.budgetsTable)..where((t) => t.month.equals(month) & t.year.equals(year))).get();
    final result = <BudgetModel>[];
    for (final r in rows) { result.add(await _budWithCat(r)); }
    return result;
  }

  Future<BudgetModel> setBudget({int? categoryId, required int month, required int year, required double amount}) async {
    final existing = await (_db.select(_db.budgetsTable)
          ..where((t) => t.month.equals(month) & t.year.equals(year) &
              ((categoryId != null ? t.categoryId.equals(categoryId) : t.categoryId.isNull()))))
        .get();
    if (existing.isNotEmpty) {
      final b = existing.first;
      await (_db.update(_db.budgetsTable)..where((t) => t.id.equals(b.id))).write(
        BudgetsTableCompanion(budgetAmount: Value(amount), updatedAt: Value(DateTime.now())),
      );
      if (categoryId != null) await _syncOverallBudget(month, year);
      return _budWithCat(b);
    }
    final now = DateTime.now();
    final id = await _db.into(_db.budgetsTable).insert(BudgetsTableCompanion.insert(
      categoryId: Value<int?>(categoryId), month: month, year: year,
      budgetAmount: amount, createdAt: now, updatedAt: now,
    ));
    if (categoryId != null) await _syncOverallBudget(month, year);
    return _budWithCat(await (_db.select(_db.budgetsTable)..where((t) => t.id.equals(id))).getSingle());
  }

  Future<void> deleteBudget(int id) async {
    final b = await (_db.select(_db.budgetsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    await (_db.delete(_db.budgetsTable)..where((t) => t.id.equals(id))).go();
    if (b != null && b.categoryId != null) {
      await _syncOverallBudget(b.month, b.year);
    }
  }

  Future<void> _syncOverallBudget(int month, int year) async {
    final catRows = await (_db.select(_db.budgetsTable)
          ..where((t) => t.month.equals(month) & t.year.equals(year) & t.categoryId.isNotNull()))
        .get();
    final total = catRows.fold(0.0, (s, r) => s + r.budgetAmount);
    if (total == 0) return;
    final existingOverall = await (_db.select(_db.budgetsTable)
          ..where((t) => t.month.equals(month) & t.year.equals(year) & t.categoryId.isNull()))
        .get();
    if (existingOverall.isNotEmpty) {
      await (_db.update(_db.budgetsTable)..where((t) => t.id.equals(existingOverall.first.id))).write(
        BudgetsTableCompanion(budgetAmount: Value(total), updatedAt: Value(DateTime.now())),
      );
    } else {
      final now = DateTime.now();
      await _db.into(_db.budgetsTable).insert(BudgetsTableCompanion.insert(
        categoryId: const Value(null), month: month, year: year,
        budgetAmount: total, createdAt: now, updatedAt: now,
      ));
    }
  }

  // ── Dashboard ──

  Future<({DashboardSummary summary, List<ExpenseModel> allExpenses})> getDashboardSummary() async {
    debugPrint('[ExpenseRepo] getDashboardSummary');
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final allExpenses = await getExpenses();
    final monthExpenses = allExpenses.where((e) => !e.date.isBefore(monthStart) && !e.date.isAfter(monthEnd)).toList();
    final todayExpenses = allExpenses.where((e) => !e.date.isBefore(todayStart)).toList();
    final weekExpenses = allExpenses.where((e) => !e.date.isBefore(weekStart)).toList();

    final totalToday = todayExpenses.fold(0.0, (s, e) => s + e.amount);
    final totalThisWeek = weekExpenses.fold(0.0, (s, e) => s + e.amount);
    final totalThisMonth = monthExpenses.fold(0.0, (s, e) => s + e.amount);

    final incomes = await getIncomes(from: monthStart, to: monthEnd);
    final totalIncomeThisMonth = incomes.fold(0.0, (s, i) => s + i.amount);

    final budgets = await getBudgets(now.month, now.year);
    final overallBudget = budgets.where((b) => b.categoryId == null).fold(0.0, (s, b) => s + b.budgetAmount);
    final remainingBudget = overallBudget - totalThisMonth;

    String? topCategory;
    double topAmount = 0;
    if (monthExpenses.isNotEmpty) {
      final byCat = <String, double>{};
      for (final e in monthExpenses) {
        final name = e.category?.name ?? 'Other';
        byCat[name] = (byCat[name] ?? 0) + e.amount;
      }
      final top = byCat.entries.reduce((a, b) => a.value > b.value ? a : b);
      topCategory = top.key;
      topAmount = top.value;
    }

    return (
      summary: DashboardSummary(
        totalToday: totalToday,
        totalThisWeek: totalThisWeek,
        totalThisMonth: totalThisMonth,
        totalIncomeThisMonth: totalIncomeThisMonth,
        remainingBudget: remainingBudget,
        topCategory: topCategory ?? '',
        topCategoryAmount: topAmount,
      ),
      allExpenses: allExpenses,
    );
  }

  Future<void> clearAllData() async {
    debugPrint('[ExpenseRepo] clearAllData');
    await _db.delete(_db.expensesTable).go();
    await _db.delete(_db.incomesTable).go();
    await _db.delete(_db.budgetsTable).go();
    await _db.delete(_db.categoriesTable).go();
    await _db.delete(_db.accountsTable).go();
    await _db.delete(_db.transfersTable).go();
    await _db.seedDefaultCategories();
    await _db.seedDefaultAccounts();
  }

  // ── Savings Goals ──

  Future<List<SavingsGoal>> getGoals() async {
    debugPrint('[ExpenseRepo] getGoals');
    final rows = await (_db.select(_db.savingsGoalsTable)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
    ).get();
    return rows.map(_goalFromDb).toList();
  }

  Future<void> saveGoal(SavingsGoal goal) async {
    final existing = await (_db.select(_db.savingsGoalsTable)
      ..where((t) => t.id.equals(goal.id))).get();
    if (existing.isNotEmpty) {
      await (_db.update(_db.savingsGoalsTable)..where((t) => t.id.equals(goal.id))).write(
        SavingsGoalsTableCompanion(
          targetAmount: Value(goal.targetAmount),
          targetDate: Value(goal.targetDate),
          description: Value(goal.description),
          savedAmount: Value(goal.savedAmount),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } else {
      await _db.into(_db.savingsGoalsTable).insert(SavingsGoalsTableCompanion.insert(
        id: goal.id, targetAmount: goal.targetAmount, targetDate: goal.targetDate,
        description: goal.description, savedAmount: Value(goal.savedAmount),
        createdAt: goal.createdAt, updatedAt: DateTime.now(),
      ));
    }
  }

  Future<void> deleteGoal(String id) async {
    await (_db.delete(_db.savingsGoalsTable)..where((t) => t.id.equals(id))).go();
  }

  SavingsGoal _goalFromDb(SavingsGoalDb row) => SavingsGoal(
    id: row.id, targetAmount: row.targetAmount, targetDate: row.targetDate,
    description: row.description, savedAmount: row.savedAmount, createdAt: row.createdAt,
  );

  // ── Search ──

  Future<List<ExpenseModel>> searchExpenses(String query, {double? minAmount, double? maxAmount, DateTime? from, DateTime? to, List<String>? tags}) async {
    var searchQuery = _db.select(_db.expensesTable)..where((t) => t.isDeleted.equals(false));
    if (query.isNotEmpty) {
      searchQuery.where((t) =>
        t.note.like('%$query%') | t.tags.like('%$query%') |
        t.paymentMethod.like('%$query%')
      );
    }
    if (minAmount != null) searchQuery.where((t) => t.amount.isBiggerThan(Variable<double>(minAmount - 0.01)));
    if (maxAmount != null) searchQuery.where((t) => t.amount.isSmallerThan(Variable<double>(maxAmount + 0.01)));
    if (from != null) searchQuery.where((t) => t.date.isBiggerThan(Variable<DateTime>(from.subtract(const Duration(days: 1)))));
    if (to != null) searchQuery.where((t) => t.date.isSmallerThan(Variable<DateTime>(to.add(const Duration(days: 1)))));
    if (tags != null && tags.isNotEmpty) {
      for (final tag in tags) {
        searchQuery.where((t) => t.tags.like('%$tag%'));
      }
    }
    searchQuery.orderBy([(t) => OrderingTerm.desc(t.date)]);
    final rows = await searchQuery.get();
    final result = <ExpenseModel>[];
    for (final r in rows) { result.add(await _expWithCat(r)); }
    return result;
  }

  Future<int> purgeOldDeleted() => _db.purgeOldDeleted();
}
