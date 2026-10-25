import 'package:flutter/material.dart';

import '../config/strings.dart';
import '../config/title_server_config.dart';
import '../models/session_model.dart';
import '../services/title_api_service.dart';
import '../services/user_all_payload_builder.dart';
import '../widgets/app_card.dart';
import '../widgets/app_notice.dart';
import '../widgets/cooldown_mixin.dart';
import '../widgets/risk/music_risk_editors.dart';
import '../widgets/risk/risk_list_widgets.dart';
import '../widgets/risk/risk_run_mixin.dart';
import '../widgets/risk/risk_widgets.dart';
import '../widgets/step_progress.dart';

/// Dart port of `eaquira/action/UnlockMusic.py`:
///
/// - 拉取 GetUserData/Extend/Option/Rating/Charge/Activity/MissionData
/// - 组装 UserAll payload (musicData 使用 eaquira settings 中的默认值)
/// - 附加道具 (userItemList / isNewItemList)
/// - UpsertUserAllApi 上传
/// - 可选自动 UserLogout
enum MusicRiskFeatureMode {
  /// 解锁歌曲与谱面 (itemKind 5/6/7)
  unlockMusic,

  /// 收藏品获取 (itemKind 1/2/3/10/11/12)
  collectibles,
}

class MusicRiskFeatureView extends StatefulWidget {
  final int userId;
  final String? cookies;

  /// `loginDateTime` 来自 HomePage 启动时执行的 UserLoginApi。
  /// 为 `null` 时表示当前未持有有效登录态（例如 isInherit 账号或登录失败）。
  final int? loginDateTime;

  /// UserLoginApi 返回的 loginId / lastLoginDate, 组装 UserAll 需要。
  final int? loginId;
  final String? lastLoginDate;

  /// 完成后自动退出登录并返回标题页时调用；由 HomePage 提供，
  /// 内部会等待结算、发 UserLogoutApi、重置会话并 pop 回主标题。
  final Future<void> Function()? onExitToTitle;

  final MusicRiskFeatureMode mode;
  final String featureTitle;
  final String featureDesc;

  const MusicRiskFeatureView({
    super.key,
    required this.userId,
    this.cookies,
    this.loginDateTime,
    this.loginId,
    this.lastLoginDate,
    this.onExitToTitle,
    this.mode = MusicRiskFeatureMode.unlockMusic,
    required this.featureTitle,
    required this.featureDesc,
  });

  @override
  State<MusicRiskFeatureView> createState() => _MusicRiskFeatureViewState();
}

class _MusicRiskFeatureViewState extends State<MusicRiskFeatureView>
    with CooldownMixin<MusicRiskFeatureView>, RiskRunMixin<MusicRiskFeatureView> {
  // ── 待提交列表：userItemList 可以一次带多行 ──
  // 真客户端的 ExportUserItems() 就是把 Plate/Title/Icon/Partner/Frame/Ticket 与
  // MusicUnlock/Master/Remaster 各列表拼成多行 UserItem，BuildListData 再只发增量、
  // isNewItemList 一行一个字符。所以多行同类/异类混发是客户端自己的做法。
  final List<PendingItem> _pendingItems = [];
  final List<PendingMusic> _pendingMusics = [];

  Map<String, Map<String, dynamic>>? _userAllData;
  String? _fetchError;

  bool get _isUnlock => widget.mode == MusicRiskFeatureMode.unlockMusic;

  @override
  int? get cooldownLoginDateTime => widget.loginDateTime;

  void _snack(String message) => context.showSnack(message);

  /// 加入待提交收藏品；重复时提示并保留输入。
  bool _addItem(PendingItem item) {
    if (_pendingItems.any((e) => e.kind == item.kind && e.id == item.id)) {
      _snack(AppStrings.listDuplicate);
      return false;
    }
    setState(() => _pendingItems.add(item));
    return true;
  }

  /// 加入待解锁歌曲；重复时提示并保留输入。
  bool _addMusic(PendingMusic music) {
    if (_pendingMusics.any((e) => e.musicId == music.musicId)) {
      _snack(AppStrings.listDuplicate);
      return false;
    }
    setState(() => _pendingMusics.add(music));
    return true;
  }

  /// eaquira UnlockMusic.py 使用 settings 中的默认 musicData。
  /// 解锁状态本身由 userItemList 的 itemKind 5/6/7 行表达，这里只保留一条
  /// 记录以维持 payload 形状，取列表首条歌曲 ID。
  Map<String, dynamic> _buildMusicData() {
    final musicId = _isUnlock && _pendingMusics.isNotEmpty
        ? _pendingMusics.first.musicId
        : UserAllPayloadBuilder.placeholderMusicId;
    return UserAllPayloadBuilder.placeholderMusicData(musicId: musicId);
  }

  /// 汇总成 wire 上的 userItemList 行。
  List<Map<String, dynamic>> _buildUserItemList() {
    if (_isUnlock) {
      return [
        for (final music in _pendingMusics)
          for (final kind in music.itemKinds)
            {
              'itemKind': kind,
              'itemId': music.musicId,
              'stock': 1,
              'isValid': true,
            },
      ];
    }
    return [
      for (final item in _pendingItems)
        {
          'itemKind': item.kind,
          'itemId': item.id,
          'stock': 1,
          'isValid': true,
        },
    ];
  }

  String? _validateInputs() {
    if (_isUnlock) {
      if (_pendingMusics.isEmpty) return AppStrings.unlockNeedList;
      return null;
    }

    if (_pendingItems.isEmpty) return AppStrings.collectiblesNeedList;
    return null;
  }

  Future<void> _fetchData() async {
    final service = SessionModel.instance.createTitleService(
      cookies: widget.cookies,
    );
    if (service == null) return;

    setState(() {
      riskFetching = true;
      _fetchError = null;
      _userAllData = null;
    });

    try {
      final data = await service.fetchUserAllData(widget.userId);
      if (!mounted) return;
      setState(() {
        _userAllData = data;
        riskFetching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fetchError = describeApiError(e);
        riskFetching = false;
      });
    }
  }

  Future<void> _run() async {
    final validationError = _validateInputs();
    if (validationError != null) {
      _snack(validationError);
      return;
    }
    final guard = riskPreconditionError(
      loginDateTime: widget.loginDateTime,
      loginId: widget.loginId,
      cooldownRemaining: cooldownRemaining,
      notLoggedInMessage: _notLoggedInMessage,
      cooldownNotice: _cooldownNotice,
    );
    if (guard != null) {
      _snack(guard);
      return;
    }

    final loginDateTime = widget.loginDateTime!;
    final loginId = widget.loginId!;
    final service = SessionModel.instance.createTitleService(
      cookies: widget.cookies,
    )!;

    setRiskRunning(true);
    clearRiskError();

    try {
      Map<String, Map<String, dynamic>> data = _userAllData ?? const {};
      if (data.isEmpty) {
        updateRiskStep(RiskStep.fetchData);
        data = await service.fetchUserAllData(widget.userId);
        if (mounted) setState(() => _userAllData = data);
      }

      updateRiskStep(RiskStep.upload);
      final musicData = _buildMusicData();
      final builder = UserAllPayloadBuilder(service.config);
      final packet = builder.build(
        userId: widget.userId,
        loginId: loginId,
        loginDateTime: loginDateTime,
        musicData: musicData,
        generalUserInfo: data,
      );

      final items = _buildUserItemList();
      // isNewItemList 得按 (itemKind, itemId) 主键比对服务器快照来给 0/1，
      // 不能一律发 '1'：重复解锁一首已经存在的歌时，服务器会把插入冲突的
      // 行整行丢掉，表现就是「上传成功但没生效」。
      // 但这次回读不能让整件事失败——私服要是不实现 GetUserItemApi，
      // 退化成一律 '1'（就是加这段之前的行为）总比解锁整个不能用强。
      Set<String>? existingKeys;
      try {
        existingKeys = await service.getUserItemKeys(
          widget.userId,
          items.map((e) => e['itemKind'] as int),
        );
      } catch (_) {
        existingKeys = null;
      }
      builder.applyItemListPatch(
        packet,
        items: items,
        newFlags: existingKeys == null
            ? null
            : [
                for (final item in items)
                  existingKeys.contains(
                    '${item['itemKind']}:${item['itemId']}',
                  )
                      ? '0'
                      : '1',
              ].join(),
      );
      if (_isUnlock) {
        builder.applyMusicDetailPatch(packet, musicData: musicData);
      }

      await service.upsertUserAll(packet, widget.userId);

      updateRiskStep(
        RiskStep.complete,
        _isUnlock
            ? await _verifyUnlock(service, items)
            : AppStrings.collectiblesSuccess,
      );

      // 让成功状态先显示一下，再交给 HomePage 结算、退登并 pop 回主标题。
      await autoLogoutAndExit(widget.onExitToTitle);
    } catch (e) {
      reportRiskError(e);
    } finally {
      setRiskRunning(false);
    }
  }

  /// 上传后回读 GetUserItemApi，把「服务器根本没存这行道具」和「存了但游戏里
  /// 还是没有这首歌」分开——后者是曲目池门禁（机台 Music.xml 没这个 ID、
  /// `eventName` 指向的活动不在开放窗口内、或落在 NG 名单里），
  /// 见 NotesListManager.cs:70，**任何用户数据包都改不动它**。
  Future<String> _verifyUnlock(
    TitleApiService service,
    List<Map<String, dynamic>> items,
  ) async {
    final requested = [
      for (final item in items) '${item['itemKind']}:${item['itemId']}',
    ];
    Set<String> saved;
    try {
      saved = await service.getUserItemKeys(
        widget.userId,
        items.map((e) => e['itemKind'] as int),
      );
    } catch (e) {
      return AppStrings.unlockVerifyFailed(describeApiError(e));
    }

    final missing = requested.where((k) => !saved.contains(k)).toList();
    if (missing.isNotEmpty) {
      return AppStrings.unlockNotSaved(missing.join('  '));
    }
    return AppStrings.unlockVerified(requested.length);
  }

  String get _notLoggedInMessage => _isUnlock
      ? AppStrings.unlockNotLoggedIn
      : AppStrings.collectiblesNotLoggedIn;

  String _cooldownNotice(int remaining) => _isUnlock
      ? AppStrings.unlockCooldownNotice(remaining)
      : AppStrings.collectiblesCooldownNotice(remaining);

  @override
  Widget build(BuildContext context) {
    if (!TitleServerConfigHolder().isConfigured) {
      return const RiskConfigMissingView(
        message: AppStrings.ticketNotConfigured,
      );
    }

    return RiskPageBody(
      children: [
        RiskStatusNotices(
          isLoggedIn: isLoggedIn,
          cooldownRemaining: cooldownRemaining,
          notLoggedInText: _notLoggedInMessage,
          cooldownText: _cooldownNotice,
        ),
        RiskFeatureCard(
          icon: _isUnlock ? Icons.lock_open : Icons.card_giftcard,
          title: widget.featureTitle,
          description: widget.featureDesc,
        ),
        const SizedBox(height: 12),
        if (_isUnlock)
          UnlockMusicEditorCard(
            enabled: !riskRunning,
            onAdd: _addMusic,
            onError: _snack,
            pendingList: _buildUnlockPendingList(),
            showDxNotice: _pendingMusics.any((m) => m.isDeluxeRange),
          )
        else
          CollectiblesEditorCard(
            enabled: !riskRunning,
            onAdd: _addItem,
            onError: _snack,
            pendingList: _buildCollectiblesPendingList(),
          ),
        const SizedBox(height: 12),
        _buildFetchCard(),
        const SizedBox(height: 12),
        AutoLogoutToggle(
          value: riskAutoLogout,
          enabled: widget.onExitToTitle != null && !riskRunning,
          onChanged: setRiskAutoLogout,
        ),
        const SizedBox(height: 12),
        _buildRunButton(),
        if (riskStep != RiskStep.idle) ...[
          const SizedBox(height: 16),
          StepProgressCard(
            step: riskStep,
            message: riskStepMessage,
            error: riskError,
            steps: [
              (RiskStep.fetchData, AppStrings.unlockStepFetch),
              (
                RiskStep.upload,
                _isUnlock
                    ? AppStrings.unlockStepUpload
                    : AppStrings.collectiblesStepUpload,
              ),
              if (riskAutoLogout) (RiskStep.logout, AppStrings.stepLogout),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildUnlockPendingList() {
    return RiskPendingList(
      title: AppStrings.unlockPendingTitle,
      emptyHint: AppStrings.unlockPendingEmpty,
      count: _pendingMusics.length,
      rows: [
        for (var i = 0; i < _pendingMusics.length; i++)
          RiskPendingRow(
            leading: '#${_pendingMusics[i].musicId}',
            trailing: _pendingMusics[i].optionLabel,
            enabled: !riskRunning,
            onRemove: () => setState(() => _pendingMusics.removeAt(i)),
          ),
      ],
    );
  }

  Widget _buildCollectiblesPendingList() {
    return RiskPendingList(
      title: AppStrings.collectiblesPendingTitle,
      emptyHint: AppStrings.collectiblesPendingEmpty,
      count: _pendingItems.length,
      rows: [
        for (var i = 0; i < _pendingItems.length; i++)
          RiskPendingRow(
            leading:
                '${AppStrings.collectiblesItemKindName(_pendingItems[i].kind)} (${_pendingItems[i].kind})',
            trailing: '#${_pendingItems[i].id}',
            enabled: !riskRunning,
            onRemove: () => setState(() => _pendingItems.removeAt(i)),
          ),
      ],
    );
  }

  Widget _buildFetchCard() {
    final hasData = _userAllData != null;

    return RiskFetchCard(
      hasData: hasData,
      statusText:
          hasData ? AppStrings.unlockFetched : AppStrings.unlockNoData,
      loadingLabel: AppStrings.unlockFetching,
      actionLabel:
          hasData ? AppStrings.unlockRefetch : AppStrings.unlockFetchData,
      error: _fetchError,
      loading: riskFetching,
      enabled: !riskRunning,
      onFetch: _fetchData,
    );
  }

  Widget _buildRunButton() {
    final onCooldown = cooldownRemaining > 0;
    final canRun = widget.loginDateTime != null &&
        widget.loginId != null &&
        !onCooldown;

    return RiskRunButton(
      running: riskRunning,
      enabled: canRun,
      icon: onCooldown
          ? Icons.timer_outlined
          : (_isUnlock ? Icons.lock_open : Icons.card_giftcard),
      label: _isUnlock ? AppStrings.unlockMusicRun : AppStrings.collectiblesRun,
      runningLabel: AppStrings.unlockRunning,
      disabledLabel:
          onCooldown ? AppStrings.ticketCooldownCountdown(cooldownRemaining) : null,
      onPressed: _run,
    );
  }
}
