import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TitleServerConfig {
  final String titleServerUrl;
  final String aesKey;
  final String aesIv;
  final String obfuscateParam;
  final String apiVersion;
  final String clientId;
  final int regionId;
  final int placeId;
  final String regionName;
  final String placeName;
  final String keychipId;

  const TitleServerConfig({
    required this.titleServerUrl,
    required this.aesKey,
    required this.aesIv,
    this.obfuscateParam = '',
    this.apiVersion = '',
    required this.clientId,
    this.regionId = 0,
    this.placeId = 0,
    this.regionName = '',
    this.placeName = '',
    this.keychipId = '',
  });

  List<int> get aesKeyBytes => utf8.encode(aesKey);
  List<int> get aesIvBytes => utf8.encode(aesIv);

  /// 扫码登录签的是**完整 Keychip**（`A63E-01C30471007`），游戏服务器那边才用
  /// 11 位短值。这里按 Astral 的约定补出完整形式：前 4 位 + 连字符 + 余下 + placeId，
  /// 所以只填了短值也能还原；填不满 11 位就当没配。
  String get fullKeychipId {
    final raw = keychipId.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();
    if (raw.length < 11) return '';
    final short = '${raw.substring(0, 4)}-${raw.substring(4)}';
    return raw.length == 11 ? '$short$placeId' : short;
  }

  Map<String, dynamic> toJson() => {
        'titleServerUrl': titleServerUrl,
        'aesKey': aesKey,
        'aesIv': aesIv,
        'obfuscateParam': obfuscateParam,
        'apiVersion': apiVersion,
        'clientId': clientId,
        'regionId': regionId,
        'placeId': placeId,
        'regionName': regionName,
        'placeName': placeName,
        'keychipId': keychipId,
      };

  factory TitleServerConfig.fromJson(Map<String, dynamic> json) {
    return TitleServerConfig(
      titleServerUrl: json['titleServerUrl'] as String? ?? '',
      aesKey: json['aesKey'] as String? ?? '',
      aesIv: json['aesIv'] as String? ?? '',
      obfuscateParam: json['obfuscateParam'] as String? ?? '',
      apiVersion: json['apiVersion'] as String? ?? '',
      clientId: json['clientId'] as String? ?? '',
      regionId: json['regionId'] as int? ?? 0,
      placeId: json['placeId'] as int? ?? 0,
      regionName: json['regionName'] as String? ?? '',
      placeName: json['placeName'] as String? ?? '',
      keychipId: json['keychipId'] as String? ?? '',
    );
  }
}

class TitleServerConfigHolder {
  static const _storageKey = 'title_server_config';

  static final TitleServerConfigHolder _instance = TitleServerConfigHolder._();
  factory TitleServerConfigHolder() => _instance;
  TitleServerConfigHolder._();

  TitleServerConfig? _config;
  TitleServerConfig? get config => _config;

  bool get isConfigured {
    final c = _config;
    return c != null &&
        c.titleServerUrl.isNotEmpty &&
        c.aesKey.isNotEmpty &&
        c.aesIv.isNotEmpty &&
        c.clientId.isNotEmpty;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        _config = TitleServerConfig.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {
        _config = null;
      }
    }
  }

  Future<void> update(TitleServerConfig config) async {
    _config = config;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(config.toJson()));
  }

  Future<void> clear() async {
    _config = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
