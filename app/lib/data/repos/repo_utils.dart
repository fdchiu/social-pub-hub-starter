import 'dart:math';

final Random _random = Random();

String generateEntityId() {
  final micros = DateTime.now().toUtc().microsecondsSinceEpoch;
  final suffix = _random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
  return '$micros-$suffix';
}
