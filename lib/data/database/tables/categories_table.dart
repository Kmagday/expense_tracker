import 'package:drift/drift.dart';

@DataClassName('CategoryDb')
class CategoriesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant('receipt'))();
  IntColumn get color => integer().withDefault(const Constant(0xFFE53935))();
  TextColumn get type => text().withDefault(const Constant('expense'))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(true))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
