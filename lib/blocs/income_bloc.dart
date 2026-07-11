import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/expense_models.dart';
import '../data/repositories/expense_repository.dart';

sealed class IncomeEvent {}

final class LoadIncomes extends IncomeEvent {}

final class AddIncomeEvent extends IncomeEvent {
  final double amount;
  final int categoryId;
  final String? source;
  final DateTime date;
  final String? note;
  final int? accountId;
  final List<String> tags;

  AddIncomeEvent({
    required this.amount,
    required this.categoryId,
    this.source,
    required this.date,
    this.note,
    this.accountId,
    this.tags = const [],
  });
}

final class UpdateIncomeEvent extends IncomeEvent {
  final int id;
  final double? amount;
  final int? categoryId;
  final String? source;
  final DateTime? date;
  final String? note;
  final int? accountId;
  final List<String>? tags;

  UpdateIncomeEvent({
    required this.id,
    this.amount,
    this.categoryId,
    this.source,
    this.date,
    this.note,
    this.accountId,
    this.tags,
  });
}

final class DeleteIncomeEvent extends IncomeEvent {
  final int id;
  DeleteIncomeEvent(this.id);
}

class IncomeState {
  final List<IncomeModel> incomes;
  final List<CategoryModel> categories;
  final List<AccountModel> accounts;
  final bool isLoading;

  const IncomeState({
    this.incomes = const [],
    this.categories = const [],
    this.accounts = const [],
    this.isLoading = false,
  });

  IncomeState copyWith({
    List<IncomeModel>? incomes,
    List<CategoryModel>? categories,
    List<AccountModel>? accounts,
    bool? isLoading,
  }) {
    return IncomeState(
      incomes: incomes ?? this.incomes,
      categories: categories ?? this.categories,
      accounts: accounts ?? this.accounts,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class IncomeBloc extends Bloc<IncomeEvent, IncomeState> {
  final ExpenseRepository _repo;

  IncomeBloc(this._repo) : super(const IncomeState()) {
    on<LoadIncomes>(_onLoad);
    on<AddIncomeEvent>(_onAdd);
    on<UpdateIncomeEvent>(_onUpdate);
    on<DeleteIncomeEvent>(_onDelete);
  }

  Future<void> _onLoad(LoadIncomes event, Emitter<IncomeState> emit) async {
    debugPrint('[IncomeBloc] loading incomes');
    emit(state.copyWith(isLoading: true));
    try {
      final incomes = await _repo.getIncomes();
      final categories = await _repo.getCategories(type: 'income');
      final accts = await _repo.getAccounts();
      accts.removeWhere((a) => a.isDebt);
      debugPrint('[IncomeBloc] loaded ${incomes.length} incomes, ${categories.length} income categories, ${accts.length} accounts');
      emit(state.copyWith(incomes: incomes, categories: categories, accounts: accts, isLoading: false));
    } catch (e) {
      debugPrint('[IncomeBloc] _onLoad error: $e');
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onAdd(AddIncomeEvent event, Emitter<IncomeState> emit) async {
    debugPrint('[IncomeBloc] adding income - amount: ${event.amount}, categoryId: ${event.categoryId}');
    await _repo.addIncome(
      amount: event.amount,
      categoryId: event.categoryId,
      source: event.source,
      date: event.date,
      note: event.note,
      accountId: event.accountId,
      tags: event.tags,
    );
    final accts = await _repo.getAccounts();
    accts.removeWhere((a) => a.isDebt);
    emit(state.copyWith(
      incomes: await _repo.getIncomes(),
      accounts: accts,
      isLoading: false,
    ));
  }

  Future<void> _onUpdate(UpdateIncomeEvent event, Emitter<IncomeState> emit) async {
    debugPrint('[IncomeBloc] updating income id=${event.id}');
    await _repo.updateIncome(
      event.id,
      amount: event.amount,
      categoryId: event.categoryId,
      source: event.source,
      date: event.date,
      note: event.note,
      accountId: event.accountId,
      tags: event.tags,
    );
    final accts = await _repo.getAccounts();
    accts.removeWhere((a) => a.isDebt);
    emit(state.copyWith(
      incomes: await _repo.getIncomes(),
      accounts: accts,
      isLoading: false,
    ));
  }

  Future<void> _onDelete(DeleteIncomeEvent event, Emitter<IncomeState> emit) async {
    debugPrint('[IncomeBloc] deleting income id=${event.id}');
    await _repo.deleteIncome(event.id);
    final accts = await _repo.getAccounts();
    accts.removeWhere((a) => a.isDebt);
    emit(state.copyWith(
      incomes: await _repo.getIncomes(),
      accounts: accts,
      isLoading: false,
    ));
  }
}
