import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/expense_models.dart';
import '../data/repositories/expense_repository.dart';

// ── Events ──

sealed class ExpenseEvent {}

final class LoadExpenses extends ExpenseEvent {}

final class AddExpenseEvent extends ExpenseEvent {
  final double amount;
  final int categoryId;
  final DateTime date;
  final String? note;
  final int? accountId;
  final String? paymentMethod;
  final bool isRecurring;
  final String? recurringFrequency;
  final String? receiptPath;

  final List<String> tags;

  AddExpenseEvent({
    required this.amount,
    required this.categoryId,
    required this.date,
    this.note,
    this.accountId,
    this.paymentMethod,
    this.isRecurring = false,
    this.recurringFrequency,
    this.receiptPath,
    this.tags = const [],
  });
}

final class UpdateExpenseEvent extends ExpenseEvent {
  final int id;
  final double? amount;
  final int? categoryId;
  final DateTime? date;
  final String? note;
  final int? accountId;
  final String? paymentMethod;
  final String? receiptPath;
  final List<String>? tags;

  UpdateExpenseEvent({
    required this.id,
    this.amount,
    this.categoryId,
    this.date,
    this.note,
    this.accountId,
    this.paymentMethod,
    this.receiptPath,
    this.tags,
  });
}

final class DeleteExpenseEvent extends ExpenseEvent {
  final int id;
  DeleteExpenseEvent(this.id);
}

// ── State ──

class ExpenseState {
  final List<ExpenseModel> expenses;
  final List<CategoryModel> categories;
  final List<AccountModel> accounts;
  final bool isLoading;
  final String? error;

  const ExpenseState({
    this.expenses = const [],
    this.categories = const [],
    this.accounts = const [],
    this.isLoading = false,
    this.error,
  });

  ExpenseState copyWith({
    List<ExpenseModel>? expenses,
    List<CategoryModel>? categories,
    List<AccountModel>? accounts,
    bool? isLoading,
    String? error,
  }) {
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      categories: categories ?? this.categories,
      accounts: accounts ?? this.accounts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ── Bloc ──

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final ExpenseRepository _repo;

  ExpenseBloc(this._repo) : super(const ExpenseState()) {
    on<LoadExpenses>(_onLoad);
    on<AddExpenseEvent>(_onAdd);
    on<UpdateExpenseEvent>(_onUpdate);
    on<DeleteExpenseEvent>(_onDelete);
  }

  Future<void> _onLoad(LoadExpenses event, Emitter<ExpenseState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final cats = await _repo.getCategories(type: 'expense');
      final accts = await _repo.getAccounts();
      debugPrint('[ExpenseBloc] loaded ${cats.length} expense categories, ${accts.length} accounts');
      emit(state.copyWith(
        expenses: await _repo.getExpenses(),
        categories: cats,
        accounts: accts,
        isLoading: false,
      ));
    } catch (e) {
      debugPrint('[ExpenseBloc] _onLoad error: $e');
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onAdd(AddExpenseEvent event, Emitter<ExpenseState> emit) async {
    emit(state.copyWith(isLoading: true));
    await _repo.addExpense(
      amount: event.amount,
      categoryId: event.categoryId,
      date: event.date,
      note: event.note,
      accountId: event.accountId,
      paymentMethod: event.paymentMethod,
      isRecurring: event.isRecurring,
      recurringFrequency: event.recurringFrequency,
      receiptPath: event.receiptPath,
      tags: event.tags,
    );
    emit(state.copyWith(
      expenses: await _repo.getExpenses(),
      isLoading: false,
    ));
  }

  Future<void> _onUpdate(UpdateExpenseEvent event, Emitter<ExpenseState> emit) async {
    emit(state.copyWith(isLoading: true));
    await _repo.updateExpense(
      event.id,
      amount: event.amount,
      categoryId: event.categoryId,
      date: event.date,
      note: event.note,
      accountId: event.accountId,
      paymentMethod: event.paymentMethod,
      receiptPath: event.receiptPath,
      tags: event.tags,
    );
    emit(state.copyWith(
      expenses: await _repo.getExpenses(),
      isLoading: false,
    ));
  }

  Future<void> _onDelete(DeleteExpenseEvent event, Emitter<ExpenseState> emit) async {
    emit(state.copyWith(isLoading: true));
    await _repo.deleteExpense(event.id);
    emit(state.copyWith(
      expenses: await _repo.getExpenses(),
      isLoading: false,
    ));
  }
}
