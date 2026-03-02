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

  TextColumn get coverImageUrl => text().nullable()();

  TextColumn get coverImageDataUri => text().nullable()();

  TextColumn get coverImagePrompt => text().nullable()();

  RealColumn get humanizeStrictness =>
      real().withDefault(const Constant(0.7))();

  TextColumn get status => text().withDefault(const Constant('active'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  TextColumn get syncStatus => text().withDefault(const Constant('dirty'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
