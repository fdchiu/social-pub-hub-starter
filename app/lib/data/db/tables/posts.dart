import 'package:drift/drift.dart';

import 'projects.dart';

class Posts extends Table {
  TextColumn get id => text()();

  TextColumn get projectId => text().nullable().references(Projects, #id)();

  TextColumn get title => text()();

  TextColumn get contentType =>
      text().withDefault(const Constant('general_post'))();

  TextColumn get goal => text().nullable()();

  TextColumn get audience => text().nullable()();

  TextColumn get status => text().withDefault(const Constant('active'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
