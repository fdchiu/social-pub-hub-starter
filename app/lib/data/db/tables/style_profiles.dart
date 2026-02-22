import 'package:drift/drift.dart';

import '../converters/string_list_converter.dart';

class StyleProfiles extends Table {
  TextColumn get id => text()();

  TextColumn get voiceName => text().withDefault(const Constant('David'))();

  RealColumn get casualFormal => real().withDefault(const Constant(0.6))();

  RealColumn get punchiness => real().withDefault(const Constant(0.7))();

  TextColumn get emojiLevel => text().withDefault(const Constant('light'))();

  TextColumn get bannedPhrases => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  TextColumn get syncStatus => text().withDefault(const Constant('dirty'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
