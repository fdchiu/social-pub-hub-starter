import 'package:drift/drift.dart';

import 'drafts.dart';

class Variants extends Table {
  TextColumn get id => text()();

  TextColumn get draftId => text().references(Drafts, #id)();

  TextColumn get platform => text()();

  TextColumn get body => text().named('text')();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  TextColumn get syncStatus => text().withDefault(const Constant('dirty'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
