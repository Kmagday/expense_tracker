import 'package:drift/drift.dart';
import 'categories_table.dart';

@DataClassName('ExpenseDb')
class ExpensesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  IntColumn get categoryId => integer().references(CategoriesTable, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  IntColumn get accountId => integer().nullable()();
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get receiptPath => text().nullable()();
  TextColumn get tags => text().nullable()();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  TextColumn get recurringFrequency => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
