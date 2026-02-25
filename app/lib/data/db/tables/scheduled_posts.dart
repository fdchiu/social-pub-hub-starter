import 'package:drift/drift.dart';

import 'posts.dart';
import 'variants.dart';

class ScheduledPosts extends Table {
  TextColumn get id => text()();

  TextColumn get variantId => text().nullable().references(Variants, #id)();

  TextColumn get postId => text().nullable().references(Posts, #id)();

  TextColumn get platform => text()();

  TextColumn get content => text()();

  DateTimeColumn get scheduledFor => dateTime()();

  TextColumn get status => text().withDefault(const Constant('queued'))();

  TextColumn get externalUrl => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  TextColumn get syncStatus => text().withDefault(const Constant('dirty'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
