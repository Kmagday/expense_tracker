import 'package:drift/drift.dart';
import 'categories_table.dart';

@DataClassName('BudgetDb')
class BudgetsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(CategoriesTable, #id).nullable()();
  IntColumn get month => integer()();
  IntColumn get year => integer()();
  RealColumn get budgetAmount => real()();
  RealColumn get spentAmount => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
