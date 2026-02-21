import 'dart:convert';

import 'package:drift/drift.dart';

class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) {
      return const <String>[];
    }

    final decoded = jsonDecode(fromDb);
    if (decoded is! List) {
      return const <String>[];
    }

    return decoded.whereType<String>().toList(growable: false);
  }

  @override
  String toSql(List<String> value) {
    return jsonEncode(value);
  }
}
