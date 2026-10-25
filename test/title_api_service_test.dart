import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ichino/config/title_server_config.dart';
import 'package:ichino/services/title_api_service.dart';

const _config = TitleServerConfig(
  titleServerUrl: 'http://127.0.0.1:9',
  aesKey: '0123456789abcdef',
  aesIv: 'fedcba9876543210',
  clientId: 'A63E01C2805',
);

void main() {
  test('describeApiError 只取协议层异常的 message', () {
    expect(
      describeApiError(const TitleApiException('GetUserDataApi returned 500')),
      'GetUserDataApi returned 500',
    );
    expect(describeApiError(const FormatException('bad qr')), 'FormatException: bad qr');
    expect(describeApiError('oops'), 'oops');
  });

  test('响应头里的 JSESSIONID 会写回实例并通知调用方', () async {
    final captured = <String>[];
    final sentCookies = <String?>[];
    final service = TitleApiService(
      _config,
      cookies: 'JSESSIONID=OLD',
      onCookiesChanged: captured.add,
    );

    var requests = 0;
    final client = MockClient((request) async {
      sentCookies.add(request.headers['Cookie']);
      requests++;
      if (requests == 1) {
        return http.Response(
          '',
          500,
          headers: {'Set-Cookie': 'JSESSIONID=NEW; Path=/; HttpOnly'},
        );
      }
      return http.Response('', 500);
    });

    await http.runWithClient(() async {
      // Cookie 捕获发生在状态码检查之前：即使这次请求失败，
      // 服务器轮换的 Cookie 也不能丢。
      await expectLater(
        service.getUserData(1),
        throwsA(isA<TitleApiException>()),
      );
      await expectLater(
        service.getUserData(1),
        throwsA(isA<TitleApiException>()),
      );
    }, () => client);

    expect(captured, ['JSESSIONID=NEW']);
    expect(service.cookies, 'JSESSIONID=NEW');
    expect(sentCookies, ['JSESSIONID=OLD', 'JSESSIONID=NEW']);
  });

  test('响应没有 JSESSIONID 时不回写', () async {
    final captured = <String>[];
    final service = TitleApiService(
      _config,
      cookies: 'JSESSIONID=OLD',
      onCookiesChanged: captured.add,
    );

    await http.runWithClient(() async {
      await expectLater(
        service.getUserData(1),
        throwsA(isA<TitleApiException>()),
      );
    }, () => MockClient((_) async => http.Response('', 500)));

    expect(captured, isEmpty);
    expect(service.cookies, 'JSESSIONID=OLD');
  });

  test('lastRawResponse 是实例状态，不会跨实例串数据', () {
    final first = TitleApiService(_config);
    final second = TitleApiService(_config);

    first.lastRawResponse = '{"userData":{}}';

    expect(first.lastRawResponse, '{"userData":{}}');
    expect(second.lastRawResponse, isNull);
  });
}
