import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

/// Simple JSON-based local database that works on all platforms (including web).
/// Stores each "table" as a JSON-encoded string under a SharedPreferences key.
class LocalDatabase {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('[LocalDB] initialized');
  }

  SharedPreferences get prefs {
    if (_prefs == null) throw StateError('LocalDatabase not initialized. Call init() first.');
    return _prefs!;
  }

  // ── Generic CRUD helpers ──

  List<Map<String, dynamic>> _getTable(String key) {
    final raw = prefs.getString(key);
    if (raw == null) {
      debugPrint('[LocalDB] _getTable($key) -> empty (key not found)');
      return [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      debugPrint('[LocalDB] _getTable($key) -> invalid data');
      return [];
    }
    final result = decoded.cast<Map<String, dynamic>>();
    debugPrint('[LocalDB] _getTable($key) -> ${result.length} rows');
    return result;
  }

  void _setTable(String key, List<Map<String, dynamic>> data) {
    debugPrint('[LocalDB] _setTable($key) -> ${data.length} rows');
    prefs.setString(key, jsonEncode(data));
  }

  int _nextId(String key) {
    final table = _getTable(key);
    if (table.isEmpty) return 1;
    final maxId = table.map((e) => e['id'] as int).reduce((a, b) => a > b ? a : b);
    debugPrint('[LocalDB] _nextId($key) -> ${maxId + 1}');
    return maxId + 1;
  }

  List<Map<String, dynamic>> getAll(String key) => _getTable(key);

  Map<String, dynamic>? getById(String key, int id) {
    final table = _getTable(key);
    final idx = table.indexWhere((e) => e['id'] == id);
    return idx >= 0 ? Map.from(table[idx]) : null;
  }

  int insert(String key, Map<String, dynamic> item) {
    final table = _getTable(key);
    final id = _nextId(key);
    item['id'] = id;
    table.add(item);
    _setTable(key, table);
    debugPrint('[LocalDB] insert($key) -> id=$id');
    return id;
  }

  bool update(String key, int id, Map<String, dynamic> item) {
    final table = _getTable(key);
    final idx = table.indexWhere((e) => e['id'] == id);
    if (idx < 0) {
      debugPrint('[LocalDB] update($key, $id) -> not found');
      return false;
    }
    item['id'] = id;
    table[idx] = item;
    _setTable(key, table);
    debugPrint('[LocalDB] update($key, $id) -> ok');
    return true;
  }

  bool delete(String key, int id) {
    final table = _getTable(key);
    final idx = table.indexWhere((e) => e['id'] == id);
    if (idx < 0) {
      debugPrint('[LocalDB] delete($key, $id) -> not found');
      return false;
    }
    table.removeAt(idx);
    _setTable(key, table);
    debugPrint('[LocalDB] delete($key, $id) -> ok');
    return true;
  }

  List<Map<String, dynamic>> query(String key, {bool Function(Map<String, dynamic>)? where}) {
    final table = _getTable(key);
    if (where == null) return table;
    return table.where(where).toList();
  }

  void deleteWhere(String key, bool Function(Map<String, dynamic>) predicate) {
    final table = _getTable(key);
    table.removeWhere(predicate);
    _setTable(key, table);
  }

  void clear(String key) {
    debugPrint('[LocalDB] clear($key)');
    prefs.remove(key);
  }

  void clearAll() {
    debugPrint('[LocalDB] clearing all tables');
    prefs.remove('categories');
    prefs.remove('expenses');
    prefs.remove('incomes');
    prefs.remove('budgets');
  }

  // ── Seeded data ──

  void seedDefaultCategories() {
    final existing = _getTable('categories');
    if (existing.isNotEmpty) {
      debugPrint('[LocalDB] seedDefaultCategories - already have ${existing.length} categories');
      return;
    }

    final defaults = [
      {'name': 'Food', 'icon': 'restaurant', 'color': 0xFFE53935, 'type': 'expense', 'isCustom': false, 'isActive': true},
      {'name': 'Transport', 'icon': 'directions_car', 'color': 0xFF1E88E5, 'type': 'expense', 'isCustom': false, 'isActive': true},
      {'name': 'Bills', 'icon': 'receipt_long', 'color': 0xFF43A047, 'type': 'expense', 'isCustom': false, 'isActive': true},
      {'name': 'Shopping', 'icon': 'shopping_bag', 'color': 0xFFFB8C00, 'type': 'expense', 'isCustom': false, 'isActive': true},
      {'name': 'Entertainment', 'icon': 'movie', 'color': 0xFF8E24AA, 'type': 'expense', 'isCustom': false, 'isActive': true},
      {'name': 'Health', 'icon': 'local_hospital', 'color': 0xFF00ACC1, 'type': 'expense', 'isCustom': false, 'isActive': true},
      {'name': 'Education', 'icon': 'school', 'color': 0xFF3949AB, 'type': 'expense', 'isCustom': false, 'isActive': true},
      {'name': 'Other', 'icon': 'more_horiz', 'color': 0xFF757575, 'type': 'expense', 'isCustom': false, 'isActive': true},
      {'name': 'Salary', 'icon': 'work', 'color': 0xFF2E7D32, 'type': 'income', 'isCustom': false, 'isActive': true},
      {'name': 'Freelance', 'icon': 'computer', 'color': 0xFF1565C0, 'type': 'income', 'isCustom': false, 'isActive': true},
      {'name': AccountTypes.investment, 'icon': 'trending_up', 'color': 0xFF00897B, 'type': 'income', 'isCustom': false, 'isActive': true},
      {'name': 'Gift', 'icon': 'card_giftcard', 'color': 0xFFAD1457, 'type': 'income', 'isCustom': false, 'isActive': true},
    ];

    int id = 1;
    for (final item in defaults) {
      item['id'] = id++;
    }
    _setTable('categories', defaults);
    debugPrint('[LocalDB] seeded ${defaults.length} default categories');
  }
}
