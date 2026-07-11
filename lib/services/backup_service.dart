import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import '../data/database/app_database.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class BackupService {
  final AppDatabase _db;

  BackupService(this._db);

  Future<String> exportBackup(String passphrase) async {
    final categories = await _db.select(_db.categoriesTable).get();
    final expenses = await _db.select(_db.expensesTable).get();
    final incomes = await _db.select(_db.incomesTable).get();
    final budgets = await _db.select(_db.budgetsTable).get();
    final accounts = await _db.select(_db.accountsTable).get();
    final transfers = await _db.select(_db.transfersTable).get();

    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': categories.map((e) => e.toJson()).toList(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'incomes': incomes.map((e) => e.toJson()).toList(),
      'budgets': budgets.map((e) => e.toJson()).toList(),
      'accounts': accounts.map((e) => e.toJson()).toList(),
      'transfers': transfers.map((e) => e.toJson()).toList(),
    };

    final jsonStr = const JsonEncoder.withIndent(null).convert(data);
    final encrypted = _encrypt(jsonStr, passphrase);
    return encrypted;
  }

  Future<void> exportToFile(String passphrase) async {
    final encrypted = await exportBackup(passphrase);
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat(DateFormats.fileTimestamp).format(DateTime.now());
    final file = File('${dir.path}/${AppFiles.backupPrefix}$timestamp.etb');
    await file.writeAsString(encrypted);
    await Share.shareXFiles([XFile(file.path)], text: AppFiles.backupShareText);
  }

  Future<int> importBackup(String encryptedData, String passphrase) async {
    final jsonStr = _decrypt(encryptedData, passphrase);
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final version = data['version'] as int? ?? 1;

    debugPrint('[Backup] importing backup v$version');

    await _db.delete(_db.expensesTable).go();
    await _db.delete(_db.incomesTable).go();
    await _db.delete(_db.budgetsTable).go();
    await _db.delete(_db.categoriesTable).go();
    await _db.delete(_db.accountsTable).go();
    await _db.delete(_db.transfersTable).go();

    int imported = 0;

    if (data['categories'] is List) {
      for (final row in data['categories'] as List) {
        await _db.into(_db.categoriesTable).insert(
          CategoriesTableCompanion(
            name: Value(row['name'] as String),
            icon: Value(row['icon'] as String? ?? 'receipt'),
            color: Value(row['color'] as int? ?? 0xFF757575),
            isCustom: Value(row['isCustom'] as bool? ?? false),
            type: Value(row['type'] as String? ?? 'expense'),
            isActive: Value(row['isActive'] as bool? ?? true),
            createdAt: Value(_parseDt(row['createdAt'])),
            updatedAt: Value(_parseDt(row['updatedAt'])),
          ),
        );
        imported++;
      }
    }

    final catMap = <int, int>{};
    final newCats = await _db.select(_db.categoriesTable).get();
    for (int i = 0; i < newCats.length; i++) {
      if (data['categories'] is List && i < (data['categories'] as List).length) {
        final oldId = (data['categories'] as List)[i]['id'] as int;
        catMap[oldId] = newCats[i].id;
      }
    }

    if (data['expenses'] is List) {
      for (final row in data['expenses'] as List) {
        await _db.into(_db.expensesTable).insert(ExpensesTableCompanion(
          amount: Value((row['amount'] as num).toDouble()),
          categoryId: Value(catMap[row['categoryId'] as int] ?? 1),
          date: Value(_parseDt(row['date'])),
          accountId: Value<int?>(row['accountId'] as int?),
          note: Value<String?>(row['note'] as String?),
          paymentMethod: Value<String?>(row['paymentMethod'] as String?),
          receiptPath: Value<String?>(row['receiptPath'] as String?),
          tags: Value<String?>(row['tags'] as String?),
          isRecurring: Value(row['isRecurring'] as bool? ?? false),
          recurringFrequency: Value<String?>(row['recurringFrequency'] as String?),
          isDeleted: Value(row['isDeleted'] as bool? ?? false),
          deletedAt: Value<DateTime?>(row['deletedAt'] != null ? _parseDt(row['deletedAt']) : null),
          createdAt: Value(_parseDt(row['createdAt'])),
          updatedAt: Value(_parseDt(row['updatedAt'])),
        ));
        imported++;
      }
    }

    if (data['incomes'] is List) {
      for (final row in data['incomes'] as List) {
        await _db.into(_db.incomesTable).insert(IncomesTableCompanion(
          amount: Value((row['amount'] as num).toDouble()),
          categoryId: Value(catMap[row['categoryId'] as int] ?? 1),
          date: Value(_parseDt(row['date'])),
          accountId: Value<int?>(row['accountId'] as int?),
          source: Value<String?>(row['source'] as String?),
          note: Value<String?>(row['note'] as String?),
          tags: Value<String?>(row['tags'] as String?),
          isDeleted: Value(row['isDeleted'] as bool? ?? false),
          deletedAt: Value<DateTime?>(row['deletedAt'] != null ? _parseDt(row['deletedAt']) : null),
          createdAt: Value(_parseDt(row['createdAt'])),
          updatedAt: Value(_parseDt(row['updatedAt'])),
        ));
        imported++;
      }
    }

    if (data['budgets'] is List) {
      for (final row in data['budgets'] as List) {
        await _db.into(_db.budgetsTable).insert(BudgetsTableCompanion(
          categoryId: Value<int?>(row['categoryId'] != null ? catMap[row['categoryId'] as int] : null),
          month: Value(row['month'] as int),
          year: Value(row['year'] as int),
          budgetAmount: Value((row['budgetAmount'] as num).toDouble()),
          spentAmount: Value((row['spentAmount'] as num?)?.toDouble() ?? 0),
          createdAt: Value(_parseDt(row['createdAt'])),
          updatedAt: Value(_parseDt(row['updatedAt'])),
        ));
        imported++;
      }
    }

    if (data['accounts'] is List) {
      for (final row in data['accounts'] as List) {
        await _db.into(_db.accountsTable).insert(AccountsTableCompanion(
          name: Value(row['name'] as String),
          type: Value(row['type'] as String? ?? 'checking'),
          balance: Value((row['balance'] as num?)?.toDouble() ?? 0),
          icon: Value(row['icon'] as String? ?? 'account_balance'),
          color: Value(row['color'] as int? ?? 0xFF1E88E5),
          isActive: Value(row['isActive'] as bool? ?? true),
          createdAt: Value(_parseDt(row['createdAt'])),
          updatedAt: Value(_parseDt(row['updatedAt'])),
        ));
        imported++;
      }
    }

    if (data['transfers'] is List) {
      for (final row in data['transfers'] as List) {
        await _db.into(_db.transfersTable).insert(TransfersTableCompanion(
          fromAccountId: Value(row['fromAccountId'] as int),
          toAccountId: Value(row['toAccountId'] as int),
          amount: Value((row['amount'] as num).toDouble()),
          date: Value(_parseDt(row['date'])),
          note: Value<String?>(row['note'] as String?),
          createdAt: Value(_parseDt(row['createdAt'])),
          updatedAt: Value(_parseDt(row['updatedAt'])),
        ));
        imported++;
      }
    }

    debugPrint('[Backup] imported $imported records');
    return imported;
  }

  DateTime _parseDt(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is String) return DateTime.parse(v);
    if (v is DateTime) return v;
    return DateTime.now();
  }

  String _encrypt(String plain, String passphrase) {
    final key = enc.Key.fromUtf8(passphrase.padRight(32).substring(0, 32));
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plain, iv: iv);
    final combined = base64.encode(iv.bytes) + ':' + encrypted.base64;
    return combined;
  }

  String _decrypt(String combined, String passphrase) {
    final parts = combined.split(':');
    if (parts.length != 2) throw FormatException(UiLabels.invalidBackup);
    final iv = enc.IV.fromBase64(parts[0]);
    final cipherText = parts[1];
    final key = enc.Key.fromUtf8(passphrase.padRight(32).substring(0, 32));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    return encrypter.decrypt64(cipherText, iv: iv);
  }
}
