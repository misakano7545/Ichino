import 'package:flutter_test/flutter_test.dart';
import 'package:ichino/core/json_value.dart';

void main() {
  group('jsonInt', () {
    test('int / num / 数字字符串都能读出来', () {
      expect(jsonInt(12), 12);
      expect(jsonInt(12.9), 12);
      expect(jsonInt('42'), 42);
      expect(jsonInt('-3'), -3);
    });

    test('null、非数字字符串、其他类型退回 fallback', () {
      expect(jsonInt(null), 0);
      expect(jsonInt('12abc'), 0);
      expect(jsonInt('12abc', fallback: -1), -1);
      expect(jsonInt({'v': 1}), 0);
    });
  });

  group('jsonDouble', () {
    test('int / double / 数字字符串都能读出来', () {
      expect(jsonDouble(3), 3.0);
      expect(jsonDouble(3.25), 3.25);
      expect(jsonDouble('3.25'), 3.25);
    });

    test('解析失败退回 fallback', () {
      expect(jsonDouble(null), 0.0);
      expect(jsonDouble('x'), 0.0);
      expect(jsonDouble('x', fallback: 1.5), 1.5);
    });
  });

  group('jsonBool', () {
    test('bool、数字、常见字符串形式', () {
      expect(jsonBool(true), isTrue);
      expect(jsonBool(false), isFalse);
      expect(jsonBool(1), isTrue);
      expect(jsonBool(0), isFalse);
      expect(jsonBool('1'), isTrue);
      expect(jsonBool(' TRUE '), isTrue);
      expect(jsonBool('true'), isTrue);
      expect(jsonBool('0'), isFalse);
      expect(jsonBool('false'), isFalse);
    });

    test('无法判断时用 fallback', () {
      expect(jsonBool(null), isFalse);
      expect(jsonBool(null, fallback: true), isTrue);
      expect(jsonBool('yes'), isFalse);
    });
  });

  group('jsonString', () {
    test('null 用 fallback，其他类型转字符串', () {
      expect(jsonString(null), '');
      expect(jsonString(null, fallback: '-'), '-');
      expect(jsonString(7), '7');
      expect(jsonString('abc'), 'abc');
    });
  });

  group('jsonMap / jsonMapList', () {
    test('jsonMap 只接受 Map<String, dynamic>', () {
      final map = <String, dynamic>{'a': 1};
      expect(jsonMap(map), same(map));
      expect(jsonMap(null), isEmpty);
      expect(jsonMap([1, 2]), isEmpty);
    });

    test('jsonMapList 丢掉非 Map 元素，其余原样保留', () {
      final rows = [
        <String, dynamic>{'id': 1},
        'oops',
        null,
        <String, dynamic>{'id': 2},
      ];
      expect(jsonMapList(rows).map((e) => e['id']), [1, 2]);
      expect(jsonMapList(null), isEmpty);
      expect(jsonMapList(<String, dynamic>{'id': 1}), isEmpty);
    });
  });
}
