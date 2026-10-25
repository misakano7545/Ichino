import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;

import '../config/title_server_config.dart';
import '../models/session_model.dart';
import '../models/user_data.dart';
import '../models/user_preview.dart';
import '../services/title_api_service.dart';
import 'about_page.dart';
import 'best50_page.dart';
import 'high_risk_feature_page.dart';
import 'home/home_tab.dart';
import 'home/home_tab_view.dart';
import 'settings_page.dart';
import 'ticket_page.dart';

class HomePage extends StatefulWidget {
  final int userId;
  final String token;
  final bool forcePreviewApi;

  /// 会话由登录页粘贴「连接信息」恢复而来：登录态（或 Cookie）已经是现成的，
  /// 主页不要再发一次 UserLoginApi 去顶掉它。
  ///
  /// 其中 `loggedIn` 为 true 时（服务器说这次会话还挂在机上，或刚用令牌登录成功），
  /// 票据与风险页照常开放，只按登录后 60 秒冷却计时。
  final SessionRestoreResult? restored;

  const HomePage({
    super.key,
    required this.userId,
    required this.token,
    this.forcePreviewApi = false,
    this.restored,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HomeTab _currentTab = HomeTab.home;

  /// 只有用户真正打开过的页签才构建。否则 IndexedStack 会在启动时把
  /// 票据 / B50 / 风险 hub 全部建出来，各自立刻发一轮请求。
  final Set<HomeTab> _visitedTabs = {HomeTab.home};

  UserPreviewDataBean? _preview;
  UserDataBean? _userData;
  String? _rawResponse;
  String? _error;
  bool _loading = true;
  bool _loggingOut = false;

  SessionModel get _session => SessionModel.instance;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final restored = widget.restored;
    final seed = restored?.userData;
    if (restored != null && seed != null) {
      // 恢复来的 JSESSIONID 已在 SessionModel._resumeCookieSession 里验证过，并
      // 顺带拉回数据与概要，这里直接展示，不再发 GetUserPreviewApi / UserLoginApi。
      // 这条路径不依赖 Title Server 配置，所以要在配置检查之前处理。
      setState(() {
        _preview = restored.preview;
        _userData = seed;
        _rawResponse = restored.rawPreviewResponse;
        _loading = false;
      });
      return;
    }

    if (!TitleServerConfigHolder().isConfigured) {
      setState(() {
        _loading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _preview = null;
      _userData = null;
    });

    if (restored == null) _session.setGameLogin(null);

    final service = _session.createTitleService()!;

    try {
      final preview = await service.getUserPreview(
        userId: widget.userId,
        token: widget.token,
      );
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _rawResponse = service.lastRawResponse;
      });

      // isLogin == true => 已有人登录, 不再走完整登录, 直接展示 preview 概要
      // forcePreviewApi => 跳过 UserLoginApi, 仅展示 preview + Login 按钮
      // 但恢复来的登录态就是自己这次会话，isLogin 为 true 不代表「别人在玩」。
      final ownsLogin = _session.gameLogin != null;
      if (!ownsLogin && (preview.isLogin || widget.forcePreviewApi)) {
        setState(() => _loading = false);
        return;
      }

      if (!ownsLogin) {
        await _session.loginGame(userId: widget.userId, token: widget.token);
        if (!mounted) return;
      }

      final userDataService = _session.createTitleService()!;
      final userData = await userDataService.getUserDataTyped(widget.userId);
      if (!mounted) return;
      setState(() {
        _userData = userData;
        _loading = false;
      });
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _performLogin() async {
    if (!TitleServerConfigHolder().isConfigured) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _session.loginGame(userId: widget.userId, token: widget.token);
      if (!mounted) return;

      final service = _session.createTitleService()!;
      final userData = await service.getUserDataTyped(widget.userId);
      if (!mounted) return;
      setState(() {
        _userData = userData;
        _loading = false;
      });
    } catch (e) {
      _fail(e);
    }
  }

  void _fail(Object error) {
    if (!mounted) return;
    setState(() {
      _error = describeApiError(error);
      _loading = false;
    });
  }

  Future<void> _logoutSession() async {
    await _session.logoutGame(userId: widget.userId);
  }

  /// 退登并回到主标题页。供 AppBar 的退出按钮与风险操作完成后的
  /// onExitToTitle 使用——这两处都是「明确要回标题」，与主页上的
  /// 系统返回手势不同（后者见 [_exitApp]）。
  Future<void> _performLogoutAndExit() async {
    setState(() => _loggingOut = true);
    if (_session.gameLogin != null) {
      await Future.delayed(const Duration(seconds: 2));
      await _logoutSession();
    }
    _session.reset();
    if (mounted) {
      // 解锁/收藏品/旅行伙伴这些页是 push 在 HomePage 之上的，只 pop() 一层会
      // 退回「风险」hub，而此时 _loggingOut 仍为 true，PopScope(canPop:false) +
      // 返回键转圈 = 卡死。必须一路 pop 回根路由（主标题）。
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  /// 主页上的原生返回手势 = 结束应用。
  void _exitApp() {
    // iOS 不允许程序化退出，且根路由本来也没有返回手势。
    if (_session.gameLogin != null) {
      _logoutSession();
    }
    if (Platform.isIOS) return;
    SystemNavigator.pop();
  }

  /// 切换页签；首次访问时才把对应页面加入构建集合。
  void _selectTab(HomeTab tab) {
    setState(() {
      _currentTab = tab;
      _visitedTabs.add(tab);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _session,
      builder: (context, _) {
        return PopScope(
          // 根路由锁死在主页。之前 canPop 为 !_loggingOut（平时即 true），系统返回
          // 手势会直接把 HomePage 弹掉、落回 Login Page，而且因为 didPop==true，
          // 回调里的退登根本不会执行——既回错页面又没退登。
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop || _loggingOut) return;
            _exitApp();
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: _loggingOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_back),
                onPressed: _loggingOut ? null : _performLogoutAndExit,
              ),
              title: Text(_currentTab.title),
            ),
            body: IndexedStack(
              index: _currentTab.index,
              children: [
                for (final tab in HomeTab.values)
                  if (_visitedTabs.contains(tab))
                    _buildTab(tab)
                  else
                    const SizedBox.shrink(),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentTab.index,
              onDestinationSelected: (i) => _selectTab(HomeTab.values[i]),
              destinations: [
                for (final tab in HomeTab.values)
                  NavigationDestination(
                    icon: Icon(tab.icon),
                    selectedIcon: Icon(tab.selectedIcon),
                    label: tab.title,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTab(HomeTab tab) {
    switch (tab) {
      case HomeTab.home:
        return HomeTabView(
          userId: widget.userId,
          token: widget.token,
          cookies: _session.cookies,
          preview: _preview,
          userData: _userData,
          loading: _loading,
          error: _error,
          isGameLoggedIn: _session.gameLogin != null,
          forcePreviewApi: widget.forcePreviewApi,
          showRestoredNotice:
              widget.restored != null && _session.gameLogin == null,
          rawJson: _rawResponse,
          onRetry: _bootstrap,
          onOpenSettings: () => _selectTab(HomeTab.settings),
          onLogin: _performLogin,
        );
      case HomeTab.tickets:
        return TicketPage(
          userId: widget.userId,
          cookies: _session.cookies,
          loginDateTime: _session.gameLogin?.loginDateTime,
          playerRating:
              _userData?.playerRating ?? _preview?.playerRating ?? 0,
          onLogoutRequested: _session.gameLogin != null
              ? _logoutSession
              : null,
        );
      case HomeTab.best50:
        return Best50Page(
          userId: widget.userId,
          cookies: _session.cookies,
          userName: _userData?.userName ?? _preview?.userName ?? '',
          iconId: _userData?.iconId ?? _preview?.iconId ?? 0,
          playerRating:
              _userData?.playerRating ?? _preview?.playerRating ?? 0,
        );
      case HomeTab.risk:
        return HighRiskFeaturePage(
          userId: widget.userId,
          cookies: _session.cookies,
          loginDateTime: _session.gameLogin?.loginDateTime,
          loginId: _session.gameLogin?.loginId,
          lastLoginDate: _session.gameLogin?.lastLoginDate,
          onExitToTitle: _session.gameLogin != null
              ? _performLogoutAndExit
              : null,
        );
      case HomeTab.settings:
        return SettingsPage(showAppBar: false);
      case HomeTab.about:
        return const AboutPage();
    }
  }
}
