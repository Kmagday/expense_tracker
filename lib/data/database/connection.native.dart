import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

QueryExecutor createExecutor() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/expense_tracker.db');
    debugPrint('[DB] opening native database at ${file.path}');
    return NativeDatabase(file);
  });
}
