import 'package:flutter_test/flutter_test.dart';
import 'package:ichino/core/date_time_format.dart';

void main() {
  test('上海时区固定为 UTC+8', () {
    expect(shanghaiOffset, const Duration(hours: 8));
    expect(
      shanghaiFromUnixSeconds(0),
      DateTime.utc(1970, 1, 1, 8),
    );
  });

  test('formatDate 补零', () {
    expect(formatDate(DateTime(2026, 1, 5, 7, 3, 9)), '2026-01-05');
    expect(formatDate(DateTime(2026, 12, 31, 23, 59, 59)), '2026-12-31');
  });

  test('formatDateTime 与 formatPlayDateTime 的秒与小数位', () {
    final dt = DateTime(2026, 10, 2, 22, 19, 46);
    expect(formatDateTime(dt), '2026-10-02 22:19:46');
    expect(formatPlayDateTime(dt), '2026-10-02 22:19:46.0');
  });
}
