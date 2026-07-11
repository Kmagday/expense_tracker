import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/expense_models.dart';
import '../data/repositories/expense_repository.dart';

// ── Events ──

sealed class DashboardEvent {}

final class LoadDashboard extends DashboardEvent {}

// ── State ──

class DashboardState {
  final DashboardSummary? summary;
  final List<ExpenseModel> recentExpenses;
  final List<AccountModel> accounts;
  final bool isLoading;

  const DashboardState({
    this.summary,
    this.recentExpenses = const [],
    this.accounts = const [],
    this.isLoading = false,
  });

  DashboardState copyWith({
    DashboardSummary? summary,
    List<ExpenseModel>? recentExpenses,
    List<AccountModel>? accounts,
    bool? isLoading,
  }) {
    return DashboardState(
      summary: summary ?? this.summary,
      recentExpenses: recentExpenses ?? this.recentExpenses,
      accounts: accounts ?? this.accounts,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ── Bloc ──

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ExpenseRepository _repo;

  DashboardBloc(this._repo) : super(const DashboardState()) {
    on<LoadDashboard>(_onLoad);
  }

  Future<void> _onLoad(LoadDashboard event, Emitter<DashboardState> emit) async {
    debugPrint('[DashboardBloc] loading dashboard');
    emit(state.copyWith(isLoading: true));
    try {
      final result = await _repo.getDashboardSummary();
      final accts = await _repo.getAccounts();
      debugPrint('[DashboardBloc] loaded - today: \$${result.summary.totalToday}, month: \$${result.summary.totalThisMonth}, ${result.allExpenses.length} expenses, ${accts.length} accounts');
      emit(state.copyWith(
        summary: result.summary,
        recentExpenses: result.allExpenses.take(5).toList(),
        accounts: accts,
        isLoading: false,
      ));
    } catch (e) {
      debugPrint('[DashboardBloc] _onLoad error: $e');
      emit(state.copyWith(isLoading: false));
    }
  }
}
