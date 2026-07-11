import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class OnboardingState {
  final bool completed;
  final bool loading;

  const OnboardingState({this.completed = false, this.loading = true});

  OnboardingState copyWith({bool? completed, bool? loading}) {
    return OnboardingState(
      completed: completed ?? this.completed,
      loading: loading ?? this.loading,
    );
  }
}

class OnboardingCubit extends Cubit<OnboardingState> {
  static const _key = PrefKeys.onboardingCompleted;

  OnboardingCubit() : super(const OnboardingState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_key) ?? false;
    emit(state.copyWith(completed: completed, loading: false));
  }

  Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    emit(state.copyWith(completed: true));
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, false);
    emit(state.copyWith(completed: false));
  }
}
