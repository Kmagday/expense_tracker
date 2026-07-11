import 'package:drift/drift.dart';
import 'categories_table.dart';

@DataClassName('IncomeDb')
class IncomesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  IntColumn get categoryId => integer().references(CategoriesTable, #id)();
  TextColumn get source => text().nullable()();
  DateTimeColumn get date => dateTime()();
  IntColumn get accountId => integer().nullable()();
  TextColumn get tags => text().nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
