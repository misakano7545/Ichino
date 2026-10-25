import 'package:flutter/material.dart';

import '../config/strings.dart';
import '../config/title_server_config.dart';
import '../models/session_model.dart';
import '../services/title_api_service.dart';
import '../widgets/app_card.dart';
import '../widgets/app_notice.dart';
import '../widgets/cooldown_mixin.dart';
import '../widgets/risk/risk_run_mixin.dart';
import '../widgets/risk/risk_widgets.dart';
import '../widgets/step_progress.dart';

class TicketPage extends StatefulWidget {
  final int userId;
  final String? cookies;

  /// `loginDateTime` 来自 HomePage 启动时执行的 UserLoginApi。
  /// 为 `null` 时表示当前未持有有效登录态（例如 isInherit 账号或登录失败）。
  final int? loginDateTime;
  final int playerRating;

  /// 当用户勾选"完成后自动退出登录"时，由 HomePage 负责发送 logout 包。
  final Future<void> Function()? onLogoutRequested;

  const TicketPage({
    super.key,
    required this.userId,
    required this.playerRating,
    this.cookies,
    this.loginDateTime,
    this.onLogoutRequested,
  });

  @override
  State<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage>
    with CooldownMixin<TicketPage>, RiskRunMixin<TicketPage> {
  static const _ticketNameMap = {
    2: '2倍票',
    4: '4倍票',
    5: '5倍票'
  };

  List<Map<String, dynamic>>? _tickets;
  bool _ticketsLoading = false;
  String? _ticketsError;
  int? _selectedTicketId;

  String _ticketName(int chargeId) =>
      _ticketNameMap[chargeId] ?? '票$chargeId';

  @override
  int? get cooldownLoginDateTime => widget.loginDateTime;

  void _snack(String message) => context.showSnack(message);

  Map<String, dynamic>? _findTicket(int chargeId) {
    final tickets = _tickets;
    if (tickets == null) return null;
    for (final t in tickets) {
      if ((t['chargeId'] as num?)?.toInt() == chargeId) return t;
    }
    return null;
  }

  Future<void> _loadTickets() async {
    final service = SessionModel.instance.createTitleService(
      cookies: widget.cookies,
    );
    if (service == null) return;

    setState(() {
      _ticketsLoading = true;
      _ticketsError = null;
      _tickets = null;
      _selectedTicketId = null;
    });

    try {
      final data = await service.getUserCharge(widget.userId);
      if (!mounted) return;

      final rawList = data['userChargeList'] as List<dynamic>? ?? [];
      setState(() {
        _tickets = rawList.map((e) => e as Map<String, dynamic>).toList();
        _ticketsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ticketsError = describeApiError(e);
        _ticketsLoading = false;
      });
    }
  }

  Future<void> _runTicket() async {
    final ticketId = _selectedTicketId;
    if (ticketId == null) {
      _snack(AppStrings.ticketNotSelected);
      return;
    }
    final guard = riskPreconditionError(
      loginDateTime: widget.loginDateTime,
      loginId: null,
      cooldownRemaining: cooldownRemaining,
      notLoggedInMessage: AppStrings.ticketNotLoggedIn,
      cooldownNotice: AppStrings.ticketCooldownNotice,
      requireLoginId: false,
    );
    if (guard != null) {
      _snack(guard);
      return;
    }

    final selectedTicket = _findTicket(ticketId);
    if (selectedTicket != null &&
        (selectedTicket['stock'] as num?)?.toInt() != 0) {
      _snack(AppStrings.ticketStockNotEmpty);
      return;
    }

    final service = SessionModel.instance.createTitleService(
      cookies: widget.cookies,
    )!;
    setRiskRunning(true);
    clearRiskError();

    try {
      updateRiskStep(RiskStep.upload);
      await service.upsertUserChargeLog(
        userId: widget.userId,
        ticketId: ticketId,
        loginDateTime: widget.loginDateTime!,
        playerRating: widget.playerRating,
      );

      if (riskAutoLogout && widget.onLogoutRequested != null) {
        updateRiskStep(RiskStep.logout);
        await Future<void>.delayed(const Duration(seconds: 5));
        await widget.onLogoutRequested!();
      }

      updateRiskStep(
        RiskStep.complete,
        '${AppStrings.ticketUsed}: ${_ticketName(ticketId)}',
      );
    } catch (e) {
      reportRiskError(e);
    } finally {
      setRiskRunning(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!TitleServerConfigHolder().isConfigured) {
      return const RiskConfigMissingView(
        message: AppStrings.ticketNotConfigured,
      );
    }

    return _buildBody(theme);
  }

  Widget _buildBody(ThemeData theme) {
    return RiskPageBody(
      children: [
        RiskStatusNotices(
          isLoggedIn: isLoggedIn,
          cooldownRemaining: cooldownRemaining,
          notLoggedInText: AppStrings.ticketNotLoggedIn,
          cooldownText: AppStrings.ticketCooldownNotice,
        ),
        _buildTicketListCard(theme),
        const SizedBox(height: 16),
        AutoLogoutToggle(
          value: riskAutoLogout,
          enabled: widget.onLogoutRequested != null && !riskRunning,
          onChanged: setRiskAutoLogout,
          label: AppStrings.ticketAutoLogout,
        ),
        const SizedBox(height: 12),
        _buildRunButton(theme),
        if (riskStep != RiskStep.idle) ...[
          const SizedBox(height: 16),
          StepProgressCard(
            step: riskStep,
            message: riskStepMessage,
            error: riskError,
            steps: [
              (RiskStep.upload, AppStrings.stepChargeTicket),
              if (riskAutoLogout) (RiskStep.logout, AppStrings.stepLogout),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTicketListCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _selectedTicketId != null
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.confirmation_number, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.myTickets,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  height: 32,
                  child: OutlinedButton.icon(
                    onPressed: _ticketsLoading ? null : _loadTickets,
                    icon: _ticketsLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 16),
                    label: Text(
                      _ticketsLoading ? AppStrings.loading : AppStrings.refreshTickets,
                      style: theme.textTheme.labelSmall,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_ticketsError != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _ticketsError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            ..._ticketNameMap.keys.map(
              (id) => _ticketRow(theme, id, _findTicket(id)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ticketRow(ThemeData theme, int chargeId, Map<String, dynamic>? ticket) {
    final hasData = ticket != null;
    final stock = (ticket?['stock'] as num?)?.toInt() ?? 0;
    final validDate = ticket?['validDate'] as String? ?? '-';
    final name = _ticketName(chargeId);
    final isSelected = _selectedTicketId == chargeId;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: riskRunning
          ? null
          : () {
              setState(() {
                _selectedTicketId = isSelected ? null : chargeId;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                '$chargeId',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  if (hasData)
                    Text(
                      '有效期: $validDate',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, size: 18, color: theme.colorScheme.primary)
            else if (hasData)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: stock > 0 ? Colors.green.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '剩余 $stock',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: stock > 0 ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunButton(ThemeData theme) {
    final selectedName = _selectedTicketId != null
        ? _ticketName(_selectedTicketId!)
        : null;
    final onCooldown = cooldownRemaining > 0;
    final canRun = widget.loginDateTime != null && !onCooldown;

    return Column(
      children: [
        if (selectedName != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${AppStrings.selectedTicket}: $selectedName (ID: $_selectedTicketId)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        RiskRunButton(
          running: riskRunning,
          enabled: canRun,
          icon: onCooldown ? Icons.timer_outlined : Icons.play_arrow,
          label: AppStrings.runTicket,
          runningLabel: AppStrings.runningTicket,
          disabledLabel: onCooldown
              ? AppStrings.ticketCooldownCountdown(cooldownRemaining)
              : null,
          onPressed: _runTicket,
        ),
      ],
    );
  }
}
