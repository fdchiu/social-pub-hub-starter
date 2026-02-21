import 'package:drift/drift.dart';

import 'variants.dart';

class PublishLogs extends Table {
  TextColumn get id => text()();

  TextColumn get variantId => text().nullable().references(Variants, #id)();

  TextColumn get platform => text()();

  TextColumn get mode => text()();

  TextColumn get status => text().withDefault(const Constant('draft'))();

  TextColumn get externalUrl => text().nullable()();

  DateTimeColumn get postedAt => dateTime().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
