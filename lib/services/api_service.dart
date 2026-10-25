import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../config/title_server_config.dart';
import 'aimedb_transport.dart';
import 'api_log.dart';

class LoginResult {
  final bool success;
  final int errorId;
  final int userId;
  final String token;

  /// 服务器拒绝登录时给用户的说明（含 errorID 的含义）。
  final String? message;

  const LoginResult({
    required this.success,
    required this.errorId,
    required this.userId,
    required this.token,
    this.message,
  });
}

/// aimedb 扫码登录：二维码串（或二维码链接）→ userID + token。
///
/// 与 Astral `api/Chime.py` 保持一致：
///   * 签名 key = SHA-256(完整 Keychip + 本机本地时间 + 签名盐)，大写 hex；
///     拼接里不含 qrCode，也不含 titlekey。
///   * `qrCode` 字段发 84 串第 21 位起的 64 位载荷，不是整串。
///   * 请求头**不能带 Content-Type**，带了服务器直接回 errorID=57。
///   * chipID 用完整 Keychip（带连字符）；游戏服务器那边才用 11 位短值。
class ApiService {
  static const String _aimeHost = 'ai.sys-allnet.cn';
  static const String _aimePath = '/wc_aime/api/get_data';
  static const String _signKey = 'XcW5FW4cPArBXEk4vzKz3CIrMuA5EVVW';
  static const String _openGameId = 'MAID';
  static const String _titleKey = 'SDGB';
  static const String _userAgent = 'WC_AIME_LIB';

  static const String _qrPrefix = 'SGWC';
  static const String _qrGameId = 'MAID';

  /// SGWC(4) + MAID(4) + 时间戳(12)
  static const int _qrHeadLength = 20;
  static const int _qrTotalLength = 84;

  static final Uri _aimeUri = Uri.https(_aimeHost, _aimePath);

  final TitleServerConfig? _config;

  ApiService([this._config]);

  TitleServerConfig? get _cfg => _config ?? TitleServerConfigHolder().config;

  /// 任意输入 -> 标准 84 字符二维码串，格式不合预期时抛 [FormatException]。
  static String normalizeQr(String input) {
    var qr = input.trim();

    if (qr.startsWith('http://') || qr.startsWith('https://')) {
      final path = Uri.parse(qr).path;
      final match = RegExp(r'/qrcode/req/([^/]+)\.html').firstMatch(path);
      if (match == null) {
        throw FormatException('这个链接里取不出二维码数据：$qr');
      }
      qr = _qrPrefix + match.group(1)!;
    }

    if (qr.length != _qrTotalLength) {
      throw FormatException(
        '二维码长度应为 $_qrTotalLength 字符，实际 ${qr.length} 字符',
      );
    }
    if (!qr.startsWith(_qrPrefix)) {
      throw FormatException('二维码应当以 "$_qrPrefix" 开头');
    }
    if (qr.substring(4, 8) != _qrGameId) {
      throw FormatException('二维码里的 GameID 应当是 "$_qrGameId"');
    }
    final payload = qr.substring(_qrHeadLength);
    if (!RegExp(r'^[0-9A-F]+$').hasMatch(payload)) {
      throw FormatException('二维码载荷必须是大写十六进制');
    }
    return qr;
  }

  /// 请求体 `qrCode` 字段的值：84 串去掉前 20 位后的 64 位载荷。
  static String extractQRCode(String input) =>
      normalizeQr(input).substring(_qrHeadLength);

  /// 真机报的是机台本地墙上时间，所以这里跟着设备时区走，不固定偏移。
  static String formatTimestamp(DateTime now) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(now.year % 100)}${two(now.month)}${two(now.day)}'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }

  Future<LoginResult> login(String qrInput) async {
    final chipId = _cfg?.fullKeychipId ?? '';
    if (chipId.isEmpty) {
      throw const FormatException('设置里没有 Keychip，无法生成签名');
    }

    final qr = normalizeQr(qrInput);
    final timestamp = formatTimestamp(DateTime.now());
    final key = sha256
        .convert(utf8.encode(chipId + timestamp + _signKey))
        .toString()
        .toUpperCase();

    final bodyBytes = utf8.encode(
      jsonEncode({
        'chipID': chipId,
        'openGameID': _openGameId,
        'key': key,
        'qrCode': qr.substring(_qrHeadLength),
        'timestamp': timestamp,
        'titlekey': _titleKey,
      }),
    );

    ApiLog.log('[login] POST https://$_aimeHost$_aimePath');
    ApiLog.log('[login] chipID=$chipId timestamp=$timestamp');

    // 不带 Content-Type：aimedb 见到这个头会回 errorID=57。
    // 传输层在 Windows 上走 WinHTTP，绕过服务器对 BoringSSL 指纹的拦截。
    final response = await AimedbTransport.post(
      _aimeUri,
      headers: const {'Connection': 'Keep-Alive', 'User-Agent': _userAgent},
      body: bodyBytes,
    ).timeout(const Duration(seconds: 25));

    ApiLog.log(
      '[login] HTTP ${response.statusCode}, ${response.bodyBytes.length} bytes',
    );

    final Map<String, dynamic> obj;
    try {
      obj = jsonDecode(response.body) as Map<String, dynamic>;
    } on Exception {
      final preview = response.body.trim();
      throw FormatException(
        'aimedb 的响应不是合法 JSON：'
        '${preview.length > 200 ? preview.substring(0, 200) : preview}',
      );
    }

    final errorId = (obj['errorID'] as num?)?.toInt() ?? -1;
    final userId = (obj['userID'] as num?)?.toInt() ?? -1;
    final token = obj['token'] as String? ?? '';

    if (errorId != 0) {
      return LoginResult(
        success: false,
        errorId: errorId,
        userId: userId,
        token: token,
        message: errorId == 57
            ? '登录被拒（errorID=57）：二维码已失效或已被使用'
            : '登录被拒（errorID=$errorId）',
      );
    }
    if (userId == -1 || token.isEmpty) {
      return LoginResult(
        success: false,
        errorId: errorId,
        userId: userId,
        token: token,
        message: '扫码登录没有拿到 userID/token'
            '（userID=$userId，token 长度 ${token.length}）',
      );
    }

    final tokenHead = token.length < 8 ? token : token.substring(0, 8);
    ApiLog.log('[login] 成功 userID=$userId token=$tokenHead...');
    return LoginResult(
      success: true,
      errorId: errorId,
      userId: userId,
      token: token,
    );
  }
}
