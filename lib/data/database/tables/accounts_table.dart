import 'package:drift/drift.dart';

@DataClassName('AccountDb')
class AccountsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  TextColumn get icon => text().withDefault(const Constant('account_balance'))();
  IntColumn get color => integer().withDefault(const Constant(0xFF1E88E5))();
  RealColumn get principal => real().nullable()();
  RealColumn get interestRate => real().nullable()();
  RealColumn get minPayment => real().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
