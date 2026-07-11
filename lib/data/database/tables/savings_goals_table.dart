import 'package:drift/drift.dart';

@DataClassName('SavingsGoalDb')
class SavingsGoalsTable extends Table {
  TextColumn get id => text()();
  RealColumn get targetAmount => real()();
  DateTimeColumn get targetDate => dateTime()();
  TextColumn get description => text()();
  RealColumn get savedAmount => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
