import '../core/json_value.dart';

class UserDataBean {
  final int userId;
  final String userName;
  final String? friendCode;
  final bool isNetMember;
  final int point;
  final int totalPoint;
  final int playerRating;
  final int playerOldRating;
  final int playerNewRating;
  final int highestRating;
  final int musicRating;
  final int gradeRank;
  final int courseRank;
  final int classRank;
  final int nameplateId;
  final int frameId;
  final int iconId;
  final int trophyId;
  final int plateId;
  final int titleId;
  final int partnerId;
  final int playCount;
  final int currentPlayCount;
  final int totalSync;
  final int totalAchievement;
  final int totalDeluxscore;
  final int totalAwake;
  final String lastGameId;
  final String lastRomVersion;
  final String lastDataVersion;
  final String lastLoginDate;
  final String lastPlayDate;
  final String firstGameId;
  final String firstRomVersion;
  final String firstDataVersion;
  final String firstPlayDate;
  final String lastRegionName;
  final int lastRegionId;
  final String dailyBonusDate;
  final int banState;

  const UserDataBean({
    required this.userId,
    required this.userName,
    required this.friendCode,
    required this.isNetMember,
    required this.point,
    required this.totalPoint,
    required this.playerRating,
    required this.playerOldRating,
    required this.playerNewRating,
    required this.highestRating,
    required this.musicRating,
    required this.gradeRank,
    required this.courseRank,
    required this.classRank,
    required this.nameplateId,
    required this.frameId,
    required this.iconId,
    required this.trophyId,
    required this.plateId,
    required this.titleId,
    required this.partnerId,
    required this.playCount,
    required this.currentPlayCount,
    required this.totalSync,
    required this.totalAchievement,
    required this.totalDeluxscore,
    required this.totalAwake,
    required this.lastGameId,
    required this.lastRomVersion,
    required this.lastDataVersion,
    required this.lastLoginDate,
    required this.lastPlayDate,
    required this.firstGameId,
    required this.firstRomVersion,
    required this.firstDataVersion,
    required this.firstPlayDate,
    required this.lastRegionName,
    required this.lastRegionId,
    required this.dailyBonusDate,
    required this.banState,
  });

  factory UserDataBean.fromJson(Map<String, dynamic> json) {
    final ud = jsonMap(json['userData']);

    return UserDataBean(
      userId: jsonInt(json['userId']),
      userName: jsonString(ud['userName']),
      friendCode: ud['friendCode']?.toString(),
      isNetMember: jsonBool(ud['isNetMember']),
      point: jsonInt(ud['point']),
      totalPoint: jsonInt(ud['totalPoint']),
      playerRating: jsonInt(ud['playerRating']),
      playerOldRating: jsonInt(ud['playerOldRating']),
      playerNewRating: jsonInt(ud['playerNewRating']),
      highestRating: jsonInt(ud['highestRating']),
      musicRating: jsonInt(ud['musicRating']),
      gradeRank: jsonInt(ud['gradeRank']),
      courseRank: jsonInt(ud['courseRank']),
      classRank: jsonInt(ud['classRank']),
      nameplateId: jsonInt(ud['nameplateId']),
      frameId: jsonInt(ud['frameId']),
      iconId: jsonInt(ud['iconId']),
      trophyId: jsonInt(ud['trophyId']),
      plateId: jsonInt(ud['plateId']),
      titleId: jsonInt(ud['titleId']),
      partnerId: jsonInt(ud['partnerId']),
      playCount: jsonInt(ud['playCount']),
      currentPlayCount: jsonInt(ud['currentPlayCount']),
      totalSync: jsonInt(ud['totalSync']),
      totalAchievement: jsonInt(ud['totalAchievement']),
      totalDeluxscore: jsonInt(ud['totalDeluxscore']),
      totalAwake: jsonInt(ud['totalAwake']),
      lastGameId: jsonString(ud['lastGameId']),
      lastRomVersion: jsonString(ud['lastRomVersion']),
      lastDataVersion: jsonString(ud['lastDataVersion']),
      lastLoginDate: jsonString(ud['lastLoginDate']),
      lastPlayDate: jsonString(ud['lastPlayDate']),
      firstGameId: jsonString(ud['firstGameId']),
      firstRomVersion: jsonString(ud['firstRomVersion']),
      firstDataVersion: jsonString(ud['firstDataVersion']),
      firstPlayDate: jsonString(ud['firstPlayDate']),
      lastRegionName: jsonString(ud['lastRegionName']),
      lastRegionId: jsonInt(ud['lastRegionId']),
      dailyBonusDate: jsonString(ud['dailyBonusDate']),
      banState: jsonInt(json['banState']),
    );
  }
}