# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Development Commands

```bash
# Run the app (launches on connected device)
flutter run

# Run analyzer
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Build release artifacts
flutter build apk --release          # Android
flutter build windows --release      # Windows
flutter build macos --release        # macOS
flutter build linux --release        # Linux
flutter build ios --release --no-codesign   # iOS（无证书时只验证可编译）

# Check for outdated dependencies
flutter pub outdated

# Upgrade dependencies
flutter pub upgrade --major-versions
```

## Architecture

This is a Flutter app (Android / iOS / Windows / macOS / Linux) that serves as a QR-code-based
login client for the maimai DX arcade game network.

### Code Layout

```
lib/
├── main.dart                # 入口：main() + MyApp（MaterialApp）
├── config/                  # strings / responsive / TitleServerConfig
├── core/
│   ├── json_value.dart      # 宽松 JSON 数值转换（jsonInt / jsonBool / jsonMapList …）
│   └── date_time_format.dart# UTC+8 时间戳与 yyyy-MM-dd HH:mm:ss.f 格式化
├── pages/
│   ├── login_page.dart      # 登录页（QR 粘贴 / 图片识别）
│   ├── home_page.dart       # 主页骨架（HomeTab 枚举 + 懒构建 IndexedStack）
│   ├── home/
│   │   ├── home_tab.dart       # 六个页签的标题 / 图标 / 顺序
│   │   └── home_tab_view.dart  # 首页内容（加载 / 错误 / preview / userData 分支）
│   ├── settings_page.dart   # Title Server / 机器参数配置
│   └── ...                  # 各功能页（ticket / best50 / 风险操作等）
├── models/
│   ├── session_model.dart   # 会话与 Cookie 的唯一持有者（ChangeNotifier 单例）
│   └── ...
├── widgets/
│   ├── cooldown_mixin.dart  # CooldownMixin：登录后冷却倒计时
│   ├── step_progress.dart   # RiskStep + StepProgressCard
│   ├── app_card.dart        # AppCard / SectionTitle / AutoLogoutToggle
│   ├── app_notice.dart      # AppNotice + context.showSnack
│   ├── home/                # 主页资料 / 统计 / 调试卡片
│   ├── risk/
│   │   ├── risk_list_widgets.dart  # 待提交列表与表单控件
│   │   ├── music_risk_editors.dart # 解锁歌曲 / 收藏品编辑器
│   │   └── risk_run_mixin.dart     # 风险执行阶段与错误上报
│   └── best50_poster.dart   # B50 成绩图
└── services/
    ├── api_service.dart     # Aime 登录 API 客户端
    ├── title_api_service.dart # 游戏服务器传输层（加解密 / 会话 / 各 Api）
    ├── user_all_payload_builder.dart # UpsertUserAll 组装与各补丁
    ├── api_log.dart         # 传输层调试日志（仅 debug）
    └── ...
```

### Key Design Decisions

- **Risk-flow scaffolding is shared**: the feature pages (ticket / unlock music / collectibles /
  travel partner / number patch / map traverse / kaleidx / risk hub) all use `CooldownMixin`,
  `RiskStep`, `StepProgressCard`, `AppCard`, `AppNotice` and `AutoLogoutToggle` instead of
  copy-pasting the same timer / step / banner / card code. Keep new pages on these primitives.
- **QR decoding is native-only**: `services/qr_service.dart` calls the
  `dev.naominet.ichino/qr_scanner` MethodChannel, implemented by Android's `MainActivity` and
  iOS's `SceneDelegate`. Desktop has no handler, so image-based QR scanning is mobile-only.
- **Auth flow**: `ApiService.login()` is a port of Astral's `api/Chime.py`. It normalizes the pasted
  input (84-char `SGWCMAID…` string, or a `wq.wahlap.net/qrcode/req/….html` link) and POSTs
  `{chipID, openGameID, key, qrCode, timestamp, titlekey}` to the hardcoded aimedb endpoint
  `https://ai.sys-allnet.cn/wc_aime/api/get_data`. The `key` is
  `SHA-256(完整 Keychip + timestamp + 内置签名盐)` upper-hex; `qrCode` is the 64-char payload
  (`input[20:]`), not the whole string. The request **must not carry a Content-Type header** —
  aimedb answers `errorID: 57` when it does — so it is sent via `http.Request` + `bodyBytes`.
  `chipID` uses the full hyphenated Keychip (`TitleServerConfig.fullKeychipId`), while the title
  server keeps using the 11-char short `clientId`. A successful response has `errorID: 0` and
  returns `userID` + `token`.
- **Title server transport**: `TitleApiService` derives the URL path from
  `MD5(apiName + salt + obfuscateParam)`, JSON → ZLib → AES-CBC encodes/decodes, and keeps the
  `JSESSIONID` cookie. `getUserPreview` and every other API go through the same `_callApi` helper.
- **Session and cookies have one owner**: `SessionModel` holds the latest `JSESSIONID`; pages build
  services with `SessionModel.createTitleService(cookies: …)` instead of snapshotting the cookie
  themselves. Any response can rotate the cookie, so `TitleApiService` writes it back through
  `onCookiesChanged` and `SessionModel.updateCookies` notifies listeners — visited tabs then rebuild
  with the fresh value. Directly-constructed page tests fall back to the cookie passed to the page.
  `lastRawResponse` (the homepage debug card) is per service instance, not static; `SessionModel`
  forwards the restored preview body through `SessionRestoreResult`.
- **Home tabs are lazy**: the `HomeTab` enum owns order/title/icons; `HomePage` keeps a
  `_visitedTabs` set and fills unvisited `IndexedStack` slots with `SizedBox.shrink()`, so ticket /
  B50 / risk pages do not fire their startup requests until first opened.
- **User-facing API errors**: call `describeApiError(e)` — `TitleApiException` contributes only its
  message (protocol failures stay readable), anything else keeps `toString()` for debugging.
  Use the `core/json_value.dart` helpers for loose server JSON instead of ad-hoc casts, and
  `core/date_time_format.dart` for UTC+8 timestamps.
- **The login timestamp is the device's local wall-clock time** (`yymmddHHmmss`), matching the
  arcade cabinet; it is not pinned to any fixed UTC offset.

### Notable Dependencies

- `http` — API calls
- `crypto` — MD5 URL hash + SHA-256 Aime key
- `pointycastle` / `archive` — AES-CBC + ZLib for the title-server wire format
- `image_picker` — picking QR images from the device gallery
- `shared_preferences` — persisted `TitleServerConfig`
- `share_plus` — exporting the B50 PNG
