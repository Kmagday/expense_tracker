import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';

QueryExecutor createExecutor() {
  return LazyDatabase(() async {
    debugPrint('[DB] opening WebAssembly database');
    final result = await WasmDatabase.open(
      databaseName: 'expense_tracker',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.dart.js'),
    );
    return result.resolvedExecutor;
  });
}
