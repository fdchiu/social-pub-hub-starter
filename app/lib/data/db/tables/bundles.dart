import 'package:drift/drift.dart';

import '../converters/string_list_converter.dart';

class Bundles extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  TextColumn get anchorType => text().withDefault(const Constant('youtube'))();

  TextColumn get anchorRef => text().nullable()();

  TextColumn get canonicalDraftId => text().nullable()();

  TextColumn get postId => text().nullable()();

  TextColumn get relatedVariantIds => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
