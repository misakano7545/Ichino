import '../core/json_value.dart';

class UserPreviewDataBean {
  final int userId;
  final String userName;
  final bool isLogin;

  /// 机台侧这次登录的 `loginId`（组装 UpsertUserAll 时当 playlogId 用）。
  /// 服务器没带这个字段时是 0。
  final int loginId;
  final String lastGameId;
  final String lastRomVersion;
  final String lastDataVersion;
  final String lastLoginDate;
  final String lastPlayDate;
  final int playerRating;
  final int nameplateId;
  final int iconId;
  final int trophyId;
  final bool isNetMember;
  final bool isInherit;
  final int totalAwake;
  final int dispRate;
  final String dailyBonusDate;
  final int headPhoneVolume;
  final int banState;
  final int errorId;

  const UserPreviewDataBean({
    required this.userId,
    required this.userName,
    required this.isLogin,
    this.loginId = 0,
    required this.lastGameId,
    required this.lastRomVersion,
    required this.lastDataVersion,
    required this.lastLoginDate,
    required this.lastPlayDate,
    required this.playerRating,
    required this.nameplateId,
    required this.iconId,
    required this.trophyId,
    required this.isNetMember,
    required this.isInherit,
    required this.totalAwake,
    required this.dispRate,
    required this.dailyBonusDate,
    required this.headPhoneVolume,
    required this.banState,
    required this.errorId,
  });

  factory UserPreviewDataBean.fromJson(Map<String, dynamic> json) {
    return UserPreviewDataBean(
      userId: jsonInt(json['userId']),
      userName: jsonString(json['userName']),
      isLogin: jsonBool(json['isLogin']),
      loginId: jsonInt(json['loginId']),
      lastGameId: jsonString(json['lastGameId']),
      lastRomVersion: jsonString(json['lastRomVersion']),
      lastDataVersion: jsonString(json['lastDataVersion']),
      lastLoginDate: jsonString(json['lastLoginDate']),
      lastPlayDate: jsonString(json['lastPlayDate']),
      playerRating: jsonInt(json['playerRating']),
      nameplateId: jsonInt(json['nameplateId']),
      iconId: jsonInt(json['iconId']),
      trophyId: jsonInt(json['trophyId']),
      isNetMember: jsonBool(json['isNetMember']),
      isInherit: jsonBool(json['isInherit']),
      totalAwake: jsonInt(json['totalAwake']),
      dispRate: jsonInt(json['dispRate']),
      dailyBonusDate: jsonString(json['dailyBonusDate']),
      headPhoneVolume: jsonInt(json['headPhoneVolume']),
      banState: jsonInt(json['banState']),
      errorId: jsonInt(json['errorId']),
    );
  }
}
