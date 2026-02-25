import 'package:drift/drift.dart';

import '../converters/string_list_converter.dart';
import 'posts.dart';

class SourceItems extends Table {
  TextColumn get id => text()();

  TextColumn get type => text()();

  TextColumn get url => text().nullable()();

  TextColumn get title => text().nullable()();

  TextColumn get userNote => text().nullable()();

  TextColumn get tags => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();

  TextColumn get bundleId => text().nullable()();

  TextColumn get postId => text().nullable().references(Posts, #id)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  TextColumn get syncStatus => text().withDefault(const Constant('dirty'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
