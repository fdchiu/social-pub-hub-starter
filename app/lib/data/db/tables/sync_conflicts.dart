import 'package:drift/drift.dart';

import '../converters/json_map_converter.dart';

class SyncConflicts extends Table {
  TextColumn get id => text()();

  TextColumn get entityType => text()();

  TextColumn get entityId => text()();

  TextColumn get localPayload =>
      text().map(const JsonMapConverter()).withDefault(const Constant('{}'))();

  TextColumn get remotePayload =>
      text().map(const JsonMapConverter()).withDefault(const Constant('{}'))();

  DateTimeColumn get detectedAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get resolvedAt => dateTime().nullable()();

  TextColumn get resolution => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
