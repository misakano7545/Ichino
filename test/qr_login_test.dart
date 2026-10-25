import 'package:flutter_test/flutter_test.dart';
import 'package:ichino/config/title_server_config.dart';
import 'package:ichino/services/api_service.dart';

/// 扫码登录的输入归一化与 Keychip 拼装：纯逻辑，不发请求。
void main() {
  const payload = 'A63E01C304710072610022219460000000000000000000000000000000000000';
  const qrString = 'SGWCMAID261002221946$payload';
  const qrUrl =
      'https://wq.wahlap.net/qrcode/req/MAID261002221946$payload.html'
      '?l=123456&t=261002221946&d=1';

  group('normalizeQr / extractQRCode', () {
    test('84 位二维码串取后 64 位载荷', () {
      expect(payload.length, 64);
      expect(qrString.length, 84);
      expect(ApiService.extractQRCode(qrString), payload);
    });

    test('二维码链接还原成同一条串', () {
      expect(ApiService.normalizeQr(qrUrl), qrString);
      expect(ApiService.extractQRCode(qrUrl), payload);
    });

    test('长度、前缀、GameID、载荷字符集不合预期时抛 FormatException', () {
      expect(
        () => ApiService.normalizeQr('ABCDEF' * 12),
        throwsFormatException,
      );
      expect(
        () => ApiService.normalizeQr('XGWC${qrString.substring(4)}'),
        throwsFormatException,
      );
      expect(
        () => ApiService.normalizeQr('SGWCXBID${qrString.substring(8)}'),
        throwsFormatException,
      );
      expect(
        () => ApiService.normalizeQr('SGWCMAID261002221946${'G' * 64}'),
        throwsFormatException,
      );
      expect(
        () => ApiService.normalizeQr('https://wq.wahlap.net/other/x.html'),
        throwsFormatException,
      );
    });
  });

  group('formatTimestamp', () {
    test('本机本地墙上时间，yymmddHHMMss', () {
      expect(
        ApiService.formatTimestamp(DateTime(2026, 10, 2, 22, 19, 46)),
        '261002221946',
      );
      expect(
        ApiService.formatTimestamp(DateTime(2026, 1, 5, 7, 3, 9)),
        '260105070309',
      );
    });
  });

  group('TitleServerConfig.fullKeychipId', () {
    TitleServerConfig config(String keychip, {int placeId = 1007}) =>
        TitleServerConfig(
          titleServerUrl: 'https://example.invalid',
          aesKey: 'k',
          aesIv: 'v',
          clientId: 'A63E01C3047',
          placeId: placeId,
          keychipId: keychip,
        );

    test('完整形式（带连字符 / 连写 / 小写）归一到大写带连字符', () {
      expect(config('A63E-01C30471007').fullKeychipId, 'A63E-01C30471007');
      expect(config('A63E01C30471007').fullKeychipId, 'A63E-01C30471007');
      expect(config('a63e-01c30471007').fullKeychipId, 'A63E-01C30471007');
    });

    test('只填 11 位短值时按 placeId 补全', () {
      expect(config('A63E01C3047').fullKeychipId, 'A63E-01C30471007');
    });

    test('短于 11 位当没配，交给登录层报错', () {
      expect(config('').fullKeychipId, isEmpty);
      expect(config('A63E01').fullKeychipId, isEmpty);
    });
  });
}
