import 'package:drift/drift.dart';

import '../converters/string_list_converter.dart';

class SourceItems extends Table {
  TextColumn get id => text()();

  TextColumn get type => text()();

  TextColumn get url => text().nullable()();

  TextColumn get title => text().nullable()();

  TextColumn get userNote => text().nullable()();

  TextColumn get tags =>
      text().map(const StringListConverter()).withDefault(const Constant('[]'))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
