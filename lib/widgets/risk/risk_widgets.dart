import 'package:flutter/material.dart';

import '../../config/responsive.dart';
import '../app_card.dart';
import '../app_notice.dart';

/// 尚未配置 Title Server 时的占位视图。
class RiskConfigMissingView extends StatelessWidget {
  final String message;

  const RiskConfigMissingView({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.settings_ethernet,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(message, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

/// 高危页统一的滚动容器与内边距。
class RiskPageBody extends StatelessWidget {
  final List<Widget> children;

  const RiskPageBody({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: responsiveBody(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// 未登录 / 冷却横幅。
class RiskStatusNotices extends StatelessWidget {
  final bool isLoggedIn;
  final int cooldownRemaining;
  final String notLoggedInText;
  final String Function(int remaining) cooldownText;

  const RiskStatusNotices({
    super.key,
    required this.isLoggedIn,
    required this.cooldownRemaining,
    required this.notLoggedInText,
    required this.cooldownText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isLoggedIn)
          AppNotice(
            notLoggedInText,
            error: true,
            icon: Icons.warning_amber_rounded,
          ),
        if (isLoggedIn && cooldownRemaining > 0)
          AppNotice(
            cooldownText(cooldownRemaining),
            icon: Icons.timer_outlined,
          ),
      ],
    );
  }
}

/// 功能说明卡。[danger] 用于高危中转页的红色警示卡。
class RiskFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? child;
  final bool danger;

  const RiskFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.child,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = danger ? theme.colorScheme.error : null;
    return AppCard(
      borderColor:
          danger ? theme.colorScheme.error.withValues(alpha: 0.4) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(icon: icon, title: title, color: tint),
          if (description != null) ...[
            const SizedBox(height: 12),
            Text(
              description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
          ?child,
        ],
      ),
    );
  }
}

/// 「已拉取服务器数据」状态 + 刷新按钮。各页原来各抄一份 Row。
class RiskFetchCard extends StatelessWidget {
  final bool hasData;
  final String statusText;
  final String loadingLabel;
  final String actionLabel;
  final String? error;
  final bool loading;
  final bool enabled;
  final VoidCallback onFetch;

  const RiskFetchCard({
    super.key,
    required this.hasData,
    required this.statusText,
    required this.loadingLabel,
    required this.actionLabel,
    required this.loading,
    required this.onFetch,
    this.error,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasData ? Icons.check_circle : Icons.download,
                size: 18,
                color: hasData ? Colors.green : theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: hasData
                        ? Colors.green
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(
                height: 32,
                child: OutlinedButton.icon(
                  onPressed: loading || !enabled ? null : onFetch,
                  icon: loading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 16),
                  label: Text(
                    loading ? loadingLabel : actionLabel,
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
          if (error != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 高危页底部的执行按钮。
class RiskRunButton extends StatelessWidget {
  final bool running;
  final bool enabled;
  final IconData icon;
  final String label;
  final String runningLabel;
  final String? disabledLabel;
  final VoidCallback onPressed;

  const RiskRunButton({
    super.key,
    required this.running,
    required this.enabled,
    required this.icon,
    required this.label,
    required this.runningLabel,
    required this.onPressed,
    this.disabledLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: enabled && !running ? onPressed : null,
        icon: running
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onPrimary,
                ),
              )
            : Icon(icon, size: 20),
        label: Text(
          running ? runningLabel : (disabledLabel ?? label),
        ),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// 勾选行（解锁难度 / 万花筒动作共用）。
class RiskCheckRow extends StatelessWidget {
  final bool value;
  final String label;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const RiskCheckRow({
    super.key,
    required this.value,
    required this.label,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: enabled ? () => onChanged(!value) : null,
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: enabled ? (v) => onChanged(v ?? false) : null,
          ),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: enabled
                    ? null
                    : theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
