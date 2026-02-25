import 'package:drift/drift.dart';

import 'posts.dart';

class Drafts extends Table {
  TextColumn get id => text()();

  TextColumn get canonicalMarkdown => text().withDefault(const Constant(''))();

  TextColumn get intent => text().nullable()();

  RealColumn get tone => real().nullable()();

  RealColumn get punchiness => real().nullable()();

  TextColumn get emojiLevel => text().nullable()();

  TextColumn get audience => text().nullable()();

  TextColumn get postId => text().nullable().references(Posts, #id)();

  TextColumn get contentType => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  TextColumn get syncStatus => text().withDefault(const Constant('dirty'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
