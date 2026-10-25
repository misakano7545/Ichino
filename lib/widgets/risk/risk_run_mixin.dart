import 'package:flutter/widgets.dart';

import '../../config/strings.dart';
import '../../config/title_server_config.dart';
import '../../services/title_api_service.dart';
import '../step_progress.dart';

/// 高危功能共用的执行状态：发包中、自动退登、阶段与错误。
///
/// 六个页面原来各自维护一份完全相同的字段和 `_updateStep`，导致同样的
/// 「失败落到哪一步、退登时序怎么走」要在每个文件里各看一遍。
mixin RiskRunMixin<T extends StatefulWidget> on State<T> {
  bool riskFetching = false;
  bool riskRunning = false;
  bool riskAutoLogout = true;
  RiskStep riskStep = RiskStep.idle;
  String riskStepMessage = '';
  String? riskError;

  void updateRiskStep(RiskStep step, [String? message]) {
    if (!mounted) return;
    setState(() {
      riskStep = step;
      riskStepMessage = message ?? '';
    });
  }

  void setRiskFetching(bool value) {
    if (!mounted) return;
    setState(() => riskFetching = value);
  }

  void setRiskRunning(bool value) {
    if (!mounted) return;
    setState(() => riskRunning = value);
  }

  void setRiskAutoLogout(bool value) {
    if (!mounted) return;
    setState(() => riskAutoLogout = value);
  }

  void clearRiskError() {
    if (!mounted || riskError == null) return;
    setState(() => riskError = null);
  }

  /// 把异常写进阶段卡。`TitleApiException` 的 message 已经是给用户看的文案，
  /// 其他异常保留 `toString()` 以便排查。
  void reportRiskError(Object error) {
    final message = describeApiError(error);
    if (!mounted) return;
    setState(() {
      riskError = message;
      riskStep = RiskStep.failed;
      riskStepMessage = message;
    });
  }

  /// 成功后的自动退登：留一点时间让阶段卡显示完成态，再由 HomePage 结算并
  /// pop 回标题页。调用方负责先判断 `onExitToTitle` 是否存在。
  Future<void> autoLogoutAndExit(
    Future<void> Function()? onExitToTitle, {
    Duration delay = const Duration(seconds: 2),
  }) async {
    if (!riskAutoLogout || onExitToTitle == null) return;
    await Future<void>.delayed(delay);
    if (!mounted) return;
    updateRiskStep(RiskStep.logout, AppStrings.exitingToTitle);
    await onExitToTitle();
  }
}

/// 执行前的统一门禁，顺序固定为「配置 → 登录态 → 冷却」。
///
/// 返回要提示给用户的文案，`null` 表示可以继续。功能票只依赖
/// `loginDateTime`，其余 `UpsertUserAll` 页面还需要 `loginId`。
String? riskPreconditionError({
  required int? loginDateTime,
  required int? loginId,
  required int cooldownRemaining,
  required String notLoggedInMessage,
  required String Function(int remaining) cooldownNotice,
  bool requireLoginId = true,
}) {
  if (!TitleServerConfigHolder().isConfigured) {
    return AppStrings.ticketNotConfigured;
  }
  if (loginDateTime == null || (requireLoginId && loginId == null)) {
    return notLoggedInMessage;
  }
  if (cooldownRemaining > 0) {
    return cooldownNotice(cooldownRemaining);
  }
  return null;
}
