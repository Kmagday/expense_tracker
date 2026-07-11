import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class CurrencyState {
  final String code;
  final String symbol;
  final NumberFormat formatter;

  const CurrencyState({
    required this.code,
    required this.symbol,
    required this.formatter,
  });
}

class CurrencyCubit extends Cubit<CurrencyState> {
  static Map<String, String> get currencies => Currencies.all;

  CurrencyCubit() : super(_defaultState()) {
    _load();
  }

  static CurrencyState _defaultState() {
    return _buildState(UiLabels.defaultCurrencyCode);
  }

  static CurrencyState _buildState(String code) {
    final symbol = Currencies.all[code] ?? UiLabels.fallbackCurrencySymbol;
    return CurrencyState(
      code: code,
      symbol: symbol,
      formatter: NumberFormat.currency(symbol: symbol),
    );
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(PrefKeys.currencyCode) ?? UiLabels.defaultCurrencyCode;
    debugPrint('[CurrencyCubit] loaded currency: $code');
    emit(_buildState(code));
  }

  Future<void> setCurrency(String code) async {
    if (!Currencies.all.containsKey(code)) return;
    debugPrint('[CurrencyCubit] setCurrency: $code');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.currencyCode, code);
    emit(_buildState(code));
  }
}
