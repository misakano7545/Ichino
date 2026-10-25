import '../models/session_model.dart';
import '../models/user_data.dart';
import '../models/user_preview.dart';
import '../services/title_api_service.dart';

/// 开发期 UI 预览用的假数据，不连 aimedb / title server。
///
/// 改这里就能调主页各卡片展示的数值；头像 `iconId: 0` 显示占位图标，
/// 改成非 0 会去 assets2.lxns.net 拉真实头像。
const int uiPreviewUserId = 12345678901234;
const String uiPreviewToken = 'ui-preview-token';
const int uiPreviewLoginId = 987654;

const UserDataBean uiPreviewUserData = UserDataBean(
  userId: uiPreviewUserId,
  userName: 'Ichino',
  friendCode: '123456789012345',
  isNetMember: true,
  point: 234567,
  totalPoint: 9876543,
  playerRating: 15234,
  playerOldRating: 8200,
  playerNewRating: 7034,
  highestRating: 15456,
  musicRating: 13800,
  gradeRank: 12,
  courseRank: 34,
  classRank: 56,
  nameplateId: 101,
  frameId: 202,
  iconId: 0,
  trophyId: 303,
  plateId: 404,
  titleId: 505,
  partnerId: 606,
  playCount: 2345,
  currentPlayCount: 123,
  totalSync: 45678,
  totalAchievement: 123456,
  totalDeluxscore: 98765,
  totalAwake: 5678,
  lastGameId: 'SDEZ',
  lastRomVersion: '1.60.00',
  lastDataVersion: '1.60.00',
  lastLoginDate: '2026-10-25 12:34:56',
  lastPlayDate: '2026-10-25 12:00:00',
  firstGameId: 'SDEZ',
  firstRomVersion: '1.00.00',
  firstDataVersion: '1.00.00',
  firstPlayDate: '2021-07-01 10:00:00',
  lastRegionName: '上海',
  lastRegionId: 1007,
  dailyBonusDate: '2026-10-25 12:00:00',
  banState: 0,
);

const UserPreviewDataBean uiPreviewPreview = UserPreviewDataBean(
  userId: uiPreviewUserId,
  userName: 'Ichino',
  isLogin: true,
  loginId: uiPreviewLoginId,
  lastGameId: 'SDEZ',
  lastRomVersion: '1.60.00',
  lastDataVersion: '1.60.00',
  lastLoginDate: '2026-10-25 12:34:56',
  lastPlayDate: '2026-10-25 12:00:00',
  playerRating: 15234,
  nameplateId: 101,
  iconId: 0,
  trophyId: 303,
  isNetMember: true,
  isInherit: false,
  totalAwake: 5678,
  dispRate: 1,
  dailyBonusDate: '2026-10-25 12:00:00',
  headPhoneVolume: 80,
  banState: 0,
  errorId: 0,
);

const String uiPreviewRawResponse = '''
{
  "userId": $uiPreviewUserId,
  "userName": "Ichino",
  "isLogin": true,
  "playerRating": 15234,
  "banState": 0,
  "errorId": 0
}''';

/// 预置登录态与主页种子数据；风险/票据页会按「已登录」渲染。
SessionRestoreResult createUiPreviewSession() {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  SessionModel.instance
    ..setGameLogin(
      UserLoginResult(
        token: uiPreviewToken,
        loginId: uiPreviewLoginId,
        lastLoginDate: uiPreviewUserData.lastLoginDate,
        // 提前两分钟，避免页面一进来就卡在 60 秒登录冷却里。
        loginDateTime: now - 120,
      ),
    )
    ..updateCookies('JSESSIONID=UI-PREVIEW');

  return const SessionRestoreResult(
    reusedCookie: true,
    userData: uiPreviewUserData,
    preview: uiPreviewPreview,
    rawPreviewResponse: uiPreviewRawResponse,
    loggedIn: true,
  );
}
