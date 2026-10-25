import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'api_log.dart';

/// aimedb 的 HTTPS 传输层。
///
/// 服务器按 TLS 指纹拦截：Dart/BoringSSL 的握手能被接受，但紧接着连接就被
/// 服务端关掉（Connection closed before full header was received），而系统栈
/// （WinHTTP / Schannel）能正常拿到响应。Windows 上因此改走 WinHTTP；其它平台
/// 仍用 HttpClient，并手动补上服务器没下发的中间证书。
class AimedbTransport {
  AimedbTransport._();

  /// 服务器只下发叶子证书，中间证书要自己补：Dart 的 BoringSSL 不会像浏览器
  /// 那样顺着证书里的 AIA 地址去补链，缺了它就报 unable to get local issuer。
  /// 这里仅把缺失的 GlobalSign 中间证书加进信任链，证书校验本身仍然开启。
  static const String _globalSignIntermediatePem = '''
-----BEGIN CERTIFICATE-----
MIIFfjCCA2agAwIBAgIRAIRDWG9jliZDgTN8gBouYRgwDQYJKoZIhvcNAQELBQAw
RjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExHDAaBgNV
BAMTE0dsb2JhbFNpZ24gUm9vdCBSNDYwHhcNMjUwOTE3MDI1NTMwWhcNMjkwNjIz
MDAwMDAwWjBWMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1z
YTEsMCoGA1UEAxMjR2xvYmFsU2lnbiBHQ0MgUjQ2IEFscGhhU1NMIENBIDIwMjUw
ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCV0s/1NfwruxzhrfoOWN/B
V8j/6KxInyuIpVJ50pmHimyU5ACjC4ST2ZyU2Ltggfc/ydc1OrTUqDyoTGjWOazH
obK+GQQtBd+MUEykZbnVCfNj14Um7UiqTGOFaOK551Etd9aE/F9/hYl+4XMXJPqC
+V3ziJbO0QQcL4/wZBvqbW3xZjqb/bcLKHttfNF+JMmO+DrT9VWyomNWVeC3Grs4
DybZLgs4RVmg8sp/Ic0quOdBjIhE+W0jYbUW6Z9HP9q2lh7UVCwn1rZ1mFTRhIXa
shGqL43uXnXfRls3T93w2dnCpgTundq28WmWuzb/RZ6kHvALQmu8f891gHfbb+kb
AgMBAAGjggFVMIIBUTAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUH
AwEwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUo0yssb+0iO2LdNhfNDjJ
6QolnnswHwYDVR0jBBgwFoAUA1yrc4GHqMywptWU4jaWSf8FmSwwewYIKwYBBQUH
AQEEbzBtMC4GCCsGAQUFBzABhiJodHRwOi8vb2NzcC5nbG9iYWxzaWduLmNvbS9y
b290cjQ2MDsGCCsGAQUFBzAChi9odHRwOi8vc2VjdXJlLmdsb2JhbHNpZ24uY29t
L2NhY2VydC9yb290cjQ2LmNydDA2BgNVHR8ELzAtMCugKaAnhiVodHRwOi8vY3Js
Lmdsb2JhbHNpZ24uY29tL3Jvb3RyNDYuY3JsMCEGA1UdIAQaMBgwCAYGZ4EMAQIB
MAwGCisGAQQBoDIKAQMwDQYJKoZIhvcNAQELBQADggIBAFidiFkGjaslf0o1kWbY
Y1Fe0N/OtR28cj5js0b6mhb0AXgyi8m3IOBBnHFsyGb/OGpGlsfnyOCNHNc4p12Z
f8tqkqtd1qh2oks7+MvEAatwDy4NMlQYmjRpdTzTu6+HFv3waK+UOHbm1NC5s5fb
lPjio082KdjQsG+isWSCUGP7hjVjTcPioy5v0HJDYzmbX1oro7fa7potZ4vjNPRI
mMH2St+E2OphOO4NkrllXtSUw5ThyiFaymFIvWfSXSWOHIcK3HwOlUxgpgrJMDi0
ZuKX3W2+wDVRmrPJXgaX+6R/uBqtdMi2O+ebkjmS5zyk2U7sHsaa9lPQz3PS5hBv
aeW0FHeJK4Yc2yeQ/HBRL3YORG5JQdH1+P/+OJnv7s10Qjipe0tPwHccfMSprzRs
0t/2wG3b2GdTBX9JJjxWp3SJs/Bib7ScMJYyMMgrUBQ/BSCreEpvKvrsw2SAsPwY
dx7fjCpsFBM0Tdrqzc1HUm/qNgETPA6tWTMn+27ot19Q94KpnEHYL1hRyCJ5JB/6
OWVNCbn2YhtwJON6787ZbkVHOz9itAZKajPNH/nO/wB4gtlhnQb1yhZ6nG6LZAsu
gJBL58/BSqH1KWGnHyp9s7VwFJPI3LoSEqLd5BryAOQg/5P5uW339YFmbJCcqS3G
3CVvDrQnx+qrRlxBrS/QeigQ
-----END CERTIFICATE-----
''';

  static Future<http.Response> post(
    Uri uri, {
    required Map<String, String> headers,
    required List<int> body,
  }) async {
    if (Platform.isWindows) {
      ApiLog.log('[aimedb] transport=WinHTTP');
      return _winHttpPost(uri, headers, body);
    }
    ApiLog.log('[aimedb] transport=Dart HttpClient');
    return _dartPost(uri, headers, body);
  }

  static Future<http.Response> _dartPost(
    Uri uri,
    Map<String, String> headers,
    List<int> body,
  ) async {
    final context = SecurityContext(withTrustedRoots: true)
      ..setTrustedCertificatesBytes(utf8.encode(_globalSignIntermediatePem));
    final client = IOClient(HttpClient(context: context));
    try {
      final request = http.Request('POST', uri)
        ..headers.addAll(headers)
        ..bodyBytes = body;
      return await http.Response.fromStream(await client.send(request));
    } finally {
      client.close();
    }
  }

  /// FFI 调用是同步阻塞的，放到后台 isolate 里跑，避免卡住登录页。
  static Future<http.Response> _winHttpPost(
    Uri uri,
    Map<String, String> headers,
    List<int> body,
  ) async {
    final result = await Isolate.run(
      () => _winHttpRequest(
        host: uri.host,
        path: uri.path,
        headers: headers,
        body: Uint8List.fromList(body),
      ),
    );
    if (result.error != null) {
      throw HttpException('WinHTTP 请求失败：${result.error}', uri: uri);
    }
    return http.Response.bytes(
      result.body,
      result.statusCode,
      request: http.Request('POST', uri),
    );
  }
}

class _WinHttpResult {
  final int statusCode;
  final Uint8List body;
  final String? error;

  const _WinHttpResult(this.statusCode, this.body, [this.error]);
}

const int _winHttpAccessAutomaticProxy = 4;
const int _winHttpFlagSecure = 0x00800000;
const int _winHttpQueryStatusCode = 19;
const int _winHttpQueryFlagNumber = 0x20000000;

typedef _OpenNative = IntPtr Function(
  Pointer<Utf16>,
  Uint32,
  Pointer<Utf16>,
  Pointer<Utf16>,
  Uint32,
);
typedef _OpenDart = int Function(
  Pointer<Utf16>,
  int,
  Pointer<Utf16>,
  Pointer<Utf16>,
  int,
);

typedef _ConnectNative = IntPtr Function(
  IntPtr,
  Pointer<Utf16>,
  Uint16,
  Uint32,
);
typedef _ConnectDart = int Function(int, Pointer<Utf16>, int, int);

typedef _OpenRequestNative = IntPtr Function(
  IntPtr,
  Pointer<Utf16>,
  Pointer<Utf16>,
  Pointer<Utf16>,
  Pointer<Utf16>,
  Pointer<IntPtr>,
  Uint32,
);
typedef _OpenRequestDart = int Function(
  int,
  Pointer<Utf16>,
  Pointer<Utf16>,
  Pointer<Utf16>,
  Pointer<Utf16>,
  Pointer<IntPtr>,
  int,
);

typedef _SetTimeoutsNative = Int32 Function(IntPtr, Int32, Int32, Int32, Int32);
typedef _SetTimeoutsDart = int Function(int, int, int, int, int);

typedef _SendNative = Int32 Function(
  IntPtr,
  Pointer<Utf16>,
  Uint32,
  Pointer<Uint8>,
  Uint32,
  Uint32,
  IntPtr,
);
typedef _SendDart = int Function(
  int,
  Pointer<Utf16>,
  int,
  Pointer<Uint8>,
  int,
  int,
  int,
);

typedef _ReceiveNative = Int32 Function(IntPtr, Pointer<Void>);
typedef _ReceiveDart = int Function(int, Pointer<Void>);

typedef _QueryHeadersNative = Int32 Function(
  IntPtr,
  Uint32,
  Pointer<Utf16>,
  Pointer<Void>,
  Pointer<Uint32>,
  Pointer<Uint32>,
);
typedef _QueryHeadersDart = int Function(
  int,
  int,
  Pointer<Utf16>,
  Pointer<Void>,
  Pointer<Uint32>,
  Pointer<Uint32>,
);

typedef _ReadNative = Int32 Function(
  IntPtr,
  Pointer<Uint8>,
  Uint32,
  Pointer<Uint32>,
);
typedef _ReadDart = int Function(int, Pointer<Uint8>, int, Pointer<Uint32>);

typedef _CloseNative = Int32 Function(IntPtr);
typedef _CloseDart = int Function(int);

typedef _LastErrorNative = Uint32 Function();
typedef _LastErrorDart = int Function();

class _WinHttp {
  static final DynamicLibrary _winhttp = DynamicLibrary.open('winhttp.dll');
  static final DynamicLibrary _kernel32 = DynamicLibrary.open('kernel32.dll');

  static final _OpenDart open = _winhttp
      .lookupFunction<_OpenNative, _OpenDart>('WinHttpOpen');
  static final _ConnectDart connect = _winhttp
      .lookupFunction<_ConnectNative, _ConnectDart>('WinHttpConnect');
  static final _OpenRequestDart openRequest = _winhttp
      .lookupFunction<_OpenRequestNative, _OpenRequestDart>(
        'WinHttpOpenRequest',
      );
  static final _SetTimeoutsDart setTimeouts = _winhttp
      .lookupFunction<_SetTimeoutsNative, _SetTimeoutsDart>(
        'WinHttpSetTimeouts',
      );
  static final _SendDart send = _winhttp
      .lookupFunction<_SendNative, _SendDart>('WinHttpSendRequest');
  static final _ReceiveDart receive = _winhttp
      .lookupFunction<_ReceiveNative, _ReceiveDart>('WinHttpReceiveResponse');
  static final _QueryHeadersDart queryHeaders = _winhttp
      .lookupFunction<_QueryHeadersNative, _QueryHeadersDart>(
        'WinHttpQueryHeaders',
      );
  static final _ReadDart read = _winhttp
      .lookupFunction<_ReadNative, _ReadDart>('WinHttpReadData');
  static final _CloseDart close = _winhttp
      .lookupFunction<_CloseNative, _CloseDart>('WinHttpCloseHandle');
  static final _LastErrorDart lastError = _kernel32
      .lookupFunction<_LastErrorNative, _LastErrorDart>('GetLastError');
}

/// 同步版本，只能在后台 isolate 里调用。
_WinHttpResult _winHttpRequest({
  required String host,
  required String path,
  required Map<String, String> headers,
  required Uint8List body,
}) {
  final headerText = headers.entries
      .map((e) => '${e.key}: ${e.value}')
      .join('\r\n');

  final agent = 'Ichino/1.0'.toNativeUtf16();
  final hostPtr = host.toNativeUtf16();
  final verb = 'POST'.toNativeUtf16();
  final pathPtr = path.toNativeUtf16();
  final version = 'HTTP/1.1'.toNativeUtf16();
  final headersPtr = '$headerText\r\n'.toNativeUtf16();
  final bodyPtr = calloc<Uint8>(body.isEmpty ? 1 : body.length);
  if (body.isNotEmpty) {
    bodyPtr.asTypedList(body.length).setAll(0, body);
  }
  final statusPtr = calloc<Uint32>();
  final statusLen = calloc<Uint32>()..value = 4;
  final readBuf = calloc<Uint8>(16384);
  final readLen = calloc<Uint32>();

  var session = 0;
  var connect = 0;
  var request = 0;
  try {
    session = _WinHttp.open(
      agent,
      _winHttpAccessAutomaticProxy,
      nullptr,
      nullptr,
      0,
    );
    if (session == 0) return _error('WinHttpOpen');

    // 同步调用本身没有超时，交给 WinHTTP 内部的四段超时兜底。
    _WinHttp.setTimeouts(session, 8000, 12000, 20000, 20000);

    connect = _WinHttp.connect(session, hostPtr, 443, 0);
    if (connect == 0) return _error('WinHttpConnect');

    request = _WinHttp.openRequest(
      connect,
      verb,
      pathPtr,
      version,
      nullptr,
      nullptr,
      _winHttpFlagSecure,
    );
    if (request == 0) return _error('WinHttpOpenRequest');

    final sent = _WinHttp.send(
      request,
      headersPtr,
      0xFFFFFFFF,
      bodyPtr,
      body.length,
      body.length,
      0,
    );
    if (sent == 0) return _error('WinHttpSendRequest');

    if (_WinHttp.receive(request, nullptr) == 0) {
      return _error('WinHttpReceiveResponse');
    }

    final statusOk = _WinHttp.queryHeaders(
      request,
      _winHttpQueryStatusCode | _winHttpQueryFlagNumber,
      nullptr,
      statusPtr.cast(),
      statusLen,
      nullptr,
    );
    final statusCode = statusOk == 0 ? 0 : statusPtr.value;

    // 必须让 BytesBuilder 复制：readBuf 会在下一轮读取时被覆盖。
    final chunks = BytesBuilder();
    while (true) {
      if (_WinHttp.read(request, readBuf, 16384, readLen) == 0) {
        return _error('WinHttpReadData');
      }
      final n = readLen.value;
      if (n == 0) break;
      chunks.add(readBuf.asTypedList(n));
      if (chunks.length > 4 * 1024 * 1024) break;
    }

    return _WinHttpResult(statusCode, chunks.takeBytes());
  } finally {
    if (request != 0) _WinHttp.close(request);
    if (connect != 0) _WinHttp.close(connect);
    if (session != 0) _WinHttp.close(session);
    calloc.free(agent);
    calloc.free(hostPtr);
    calloc.free(verb);
    calloc.free(pathPtr);
    calloc.free(version);
    calloc.free(headersPtr);
    calloc.free(bodyPtr);
    calloc.free(statusPtr);
    calloc.free(statusLen);
    calloc.free(readBuf);
    calloc.free(readLen);
  }
}

_WinHttpResult _error(String what) {
  final code = _WinHttp.lastError();
  return _WinHttpResult(0, Uint8List(0), '$what（GetLastError=$code）');
}
