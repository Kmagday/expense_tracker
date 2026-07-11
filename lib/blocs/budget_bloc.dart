import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/expense_models.dart';
import '../data/repositories/expense_repository.dart';

sealed class BudgetEvent {}

final class LoadBudgets extends BudgetEvent {}

final class ChangeBudgetMonth extends BudgetEvent {
  final int month;
  final int year;
  ChangeBudgetMonth({required this.month, required this.year});
}

final class SetBudgetEvent extends BudgetEvent {
  final int? categoryId;
  final int month;
  final int year;
  final double amount;

  SetBudgetEvent({
    this.categoryId,
    required this.month,
    required this.year,
    required this.amount,
  });
}

final class DeleteBudgetEvent extends BudgetEvent {
  final int id;
  DeleteBudgetEvent(this.id);
}

class BudgetState {
  final List<BudgetModel> budgets;
  final List<CategoryModel> categories;
  final int selectedMonth;
  final int selectedYear;
  final bool isLoading;

  const BudgetState({
    this.budgets = const [],
    this.categories = const [],
    this.selectedMonth = 0,
    this.selectedYear = 0,
    this.isLoading = false,
  });

  BudgetState copyWith({
    List<BudgetModel>? budgets,
    List<CategoryModel>? categories,
    int? selectedMonth,
    int? selectedYear,
    bool? isLoading,
  }) {
    return BudgetState(
      budgets: budgets ?? this.budgets,
      categories: categories ?? this.categories,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final ExpenseRepository _repo;

  BudgetBloc(this._repo) : super(const BudgetState()) {
    on<LoadBudgets>(_onLoad);
    on<ChangeBudgetMonth>(_onChangeMonth);
    on<SetBudgetEvent>(_onSetBudget);
    on<DeleteBudgetEvent>(_onDeleteBudget);
  }

  Future<void> _onLoad(LoadBudgets event, Emitter<BudgetState> emit) async {
    debugPrint('[BudgetBloc] loading budgets');
    emit(state.copyWith(isLoading: true));
    try {
      final now = DateTime.now();
      final month = state.selectedMonth > 0 ? state.selectedMonth : now.month;
      final year = state.selectedYear > 0 ? state.selectedYear : now.year;
      final budgets = await _repo.getBudgets(month, year);
      debugPrint('[BudgetBloc] loaded ${budgets.length} budgets for $month/$year');
      emit(state.copyWith(
        budgets: budgets,
        categories: await _repo.getCategories(type: 'expense'),
        selectedMonth: month,
        selectedYear: year,
        isLoading: false,
      ));
    } catch (e) {
      debugPrint('[BudgetBloc] _onLoad error: $e');
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onChangeMonth(ChangeBudgetMonth event, Emitter<BudgetState> emit) async {
    debugPrint('[BudgetBloc] changing month to ${event.month}/${event.year}');
    emit(state.copyWith(isLoading: true));
    try {
      final budgets = await _repo.getBudgets(event.month, event.year);
      emit(state.copyWith(
        budgets: budgets,
        categories: await _repo.getCategories(type: 'expense'),
        selectedMonth: event.month,
        selectedYear: event.year,
        isLoading: false,
      ));
    } catch (e) {
      debugPrint('[BudgetBloc] _onChangeMonth error: $e');
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onSetBudget(SetBudgetEvent event, Emitter<BudgetState> emit) async {
    debugPrint('[BudgetBloc] setting budget - categoryId: ${event.categoryId}, month: ${event.month}, year: ${event.year}, amount: ${event.amount}');
    await _repo.setBudget(
      categoryId: event.categoryId,
      month: event.month,
      year: event.year,
      amount: event.amount,
    );
    final month = state.selectedMonth > 0 ? state.selectedMonth : event.month;
    final year = state.selectedYear > 0 ? state.selectedYear : event.year;
    emit(state.copyWith(
      budgets: await _repo.getBudgets(month, year),
      isLoading: false,
    ));
  }

  Future<void> _onDeleteBudget(DeleteBudgetEvent event, Emitter<BudgetState> emit) async {
    debugPrint('[BudgetBloc] deleting budget id=${event.id}');
    await _repo.deleteBudget(event.id);
    final month = state.selectedMonth;
    final year = state.selectedYear;
    emit(state.copyWith(
      budgets: await _repo.getBudgets(month, year),
      isLoading: false,
    ));
  }
}
