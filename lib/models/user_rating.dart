import '../core/json_value.dart';

/// GetUserRatingApi 的 `userRating` 结构，移植自 Empurple 的 `UserRatingData`。
///
/// 服务端已按 RA 排好 BEST 35 / BEST 15，客户端不再重排。
enum MusicLevel {
  basic,
  advanced,
  expert,
  master,
  reMaster;

  static MusicLevel fromInt(int level) =>
      level >= 0 && level < MusicLevel.values.length
          ? MusicLevel.values[level]
          : MusicLevel.basic;
}

class UserRatingItemBean {
  final int musicId;
  final int level;
  final int achievement;
  final int comboStatus;
  final int syncStatus;
  final int romVersion;

  const UserRatingItemBean({
    required this.musicId,
    required this.level,
    required this.achievement,
    required this.comboStatus,
    required this.syncStatus,
    required this.romVersion,
  });

  /// 达成率百分比数值，接口原值 1001234 => 100.1234。
  double get achievementPercent => achievement / 10000.0;

  /// 对应 Empurple 的 `formatRatingSimple`。
  String get achievementText => '${achievementPercent.toStringAsFixed(4)}%';

  /// DX 谱的 musicId 会加 10000 偏移。
  bool get isDx => musicId > 10000;

  MusicLevel get musicLevel => MusicLevel.fromInt(level);

  factory UserRatingItemBean.fromJson(Map<String, dynamic> json) {
    return UserRatingItemBean(
      musicId: jsonInt(json['musicId']),
      level: jsonInt(json['level']),
      achievement: jsonInt(json['achievement']),
      comboStatus: jsonInt(json['comboStatus']),
      syncStatus: jsonInt(json['syncStatus']),
      romVersion: jsonInt(json['romVersion']),
    );
  }
}

class UserRatingBean {
  final int userId;
  final List<UserRatingItemBean> ratingList;
  final List<UserRatingItemBean> newRatingList;

  const UserRatingBean({
    required this.userId,
    required this.ratingList,
    required this.newRatingList,
  });

  static List<UserRatingItemBean> _parseList(dynamic raw) =>
      jsonMapList(raw).map(UserRatingItemBean.fromJson).toList();

  factory UserRatingBean.fromJson(Map<String, dynamic> json) {
    final userRating = jsonMap(json['userRating']);

    return UserRatingBean(
      userId: jsonInt(json['userId']),
      ratingList: _parseList(userRating['ratingList']),
      newRatingList: _parseList(userRating['newRatingList']),
    );
  }
}
