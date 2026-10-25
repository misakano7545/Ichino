/// 服务器返回的 JSON 数值并不总是稳定的 Dart 类型：同一个字段可能是
/// `int`、`double`，也可能是字符串。这些函数把所有宽松转换收口到一处。
library;

int jsonInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double jsonDouble(dynamic value, {double fallback = 0.0}) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

bool jsonBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == '1' || normalized == 'true';
  }
  return fallback;
}

String jsonString(dynamic value, {String fallback = ''}) =>
    value?.toString() ?? fallback;

Map<String, dynamic> jsonMap(dynamic value) =>
    value is Map<String, dynamic> ? value : const {};

List<Map<String, dynamic>> jsonMapList(dynamic value) => value is List
    ? value.whereType<Map<String, dynamic>>().toList(growable: false)
    : const [];
