import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system) {
    debugPrint('[ThemeCubit] initialized with mode: $state');
  }

  void setTheme(ThemeMode mode) {
    debugPrint('[ThemeCubit] setTheme: $mode');
    emit(mode);
  }

  void toggle() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    debugPrint('[ThemeCubit] toggle: $state -> $next');
    emit(next);
  }
}
