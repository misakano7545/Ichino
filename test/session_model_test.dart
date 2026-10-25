import 'package:flutter_test/flutter_test.dart';
import 'package:ichino/models/session_model.dart';

void main() {
  final session = SessionModel.instance;

  setUp(session.reset);
  tearDown(session.reset);

  test('updateCookies 只在 Cookie 变化时通知，空值忽略', () {
    var notified = 0;
    session.addListener(() => notified++);

    session.updateCookies(null);
    session.updateCookies('');
    expect(notified, 0);
    expect(session.cookies, isNull);

    session.updateCookies('JSESSIONID=A');
    expect(session.cookies, 'JSESSIONID=A');
    expect(notified, 1);

    // 同一个值重复回写不制造额外重建。
    session.updateCookies('JSESSIONID=A');
    expect(notified, 1);

    session.updateCookies('JSESSIONID=B');
    expect(session.cookies, 'JSESSIONID=B');
    expect(notified, 2);
  });

  test('reset 清空 Cookie 与登录态并通知', () {
    session.updateCookies('JSESSIONID=A');
    var notified = 0;
    session.addListener(() => notified++);

    session.reset();

    expect(session.cookies, isNull);
    expect(session.gameLogin, isNull);
    expect(notified, 1);
  });
}
