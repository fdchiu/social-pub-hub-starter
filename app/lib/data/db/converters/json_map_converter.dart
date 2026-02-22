import 'dart:convert';

import 'package:drift/drift.dart';

class JsonMapConverter extends TypeConverter<Map<String, dynamic>, String> {
  const JsonMapConverter();

  @override
  Map<String, dynamic> fromSql(String fromDb) {
    final decoded = jsonDecode(fromDb);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.cast<String, dynamic>();
    }
    return const <String, dynamic>{};
  }

  @override
  String toSql(Map<String, dynamic> value) {
    return jsonEncode(value);
  }
}
