import 'package:drift/drift.dart';
import 'accounts_table.dart';

@DataClassName('TransferDb')
class TransfersTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get fromAccountId => integer().references(AccountsTable, #id)();
  IntColumn get toAccountId => integer().references(AccountsTable, #id)();
  RealColumn get amount => real()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
