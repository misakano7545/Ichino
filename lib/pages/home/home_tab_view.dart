import 'package:flutter/material.dart';

import '../../config/responsive.dart';
import '../../config/strings.dart';
import '../../config/title_server_config.dart';
import '../../models/user_data.dart';
import '../../models/user_preview.dart';
import '../../widgets/account_backup_card.dart';
import '../../widgets/app_notice.dart';
import '../../widgets/connection_share_card.dart';
import '../../widgets/home/home_common.dart';
import '../../widgets/home/home_debug_card.dart';
import '../../widgets/home/home_preview_cards.dart';
import '../../widgets/home/home_user_data_cards.dart';

/// 主页第一个页签的内容：账号概要、统计卡与调试信息。
///
/// 数据与回调都由 [HomePage] 持有，这里只负责按加载状态切换展示。
class HomeTabView extends StatelessWidget {
  final int userId;
  final String token;
  final String? cookies;
  final UserPreviewDataBean? preview;
  final UserDataBean? userData;
  final bool loading;
  final String? error;
  final bool isGameLoggedIn;
  final bool forcePreviewApi;
  final bool showRestoredNotice;
  final String? rawJson;

  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;
  final VoidCallback onLogin;

  const HomeTabView({
    super.key,
    required this.userId,
    required this.token,
    required this.cookies,
    required this.preview,
    required this.userData,
    required this.loading,
    required this.error,
    required this.isGameLoggedIn,
    required this.forcePreviewApi,
    required this.showRestoredNotice,
    required this.rawJson,
    required this.onRetry,
    required this.onOpenSettings,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 开发预览等入口会直接塞入种子数据，此时没配 Title Server 也应该展示。
    if (!TitleServerConfigHolder().isConfigured &&
        userData == null &&
        preview == null) {
      return _ConfigMissingView(onOpenSettings: onOpenSettings);
    }

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return _ErrorView(theme: theme, error: error!, onRetry: onRetry);
    }

    final data = userData;
    if (data != null) {
      return _buildFullData(context, data);
    }

    final p = preview;
    if (p == null) {
      return const SizedBox.shrink();
    }

    final showLoginButton = forcePreviewApi && !isGameLoggedIn;
    if (p.isLogin || showLoginButton) {
      return _buildPreviewOnly(
        context,
        p,
        showLoginButton: showLoginButton,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildPreviewOnly(
    BuildContext context,
    UserPreviewDataBean preview, {
    required bool showLoginButton,
  }) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: responsiveBody(
        context,
        child: Column(
          children: [
            if (preview.errorId != 0) ErrorIdBanner(errorId: preview.errorId),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                showLoginButton
                    ? 'Preview API 模式，点击下方按钮登录。'
                    : AppStrings.inheritedAccountNotice,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ),
            if (showLoginButton) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onLogin,
                  icon: const Icon(Icons.login, size: 20),
                  label: const Text(AppStrings.login),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            HomeProfileCard(
              userName: preview.userName,
              iconId: preview.iconId,
              playerRating: preview.playerRating,
            ),
            const SizedBox(height: 12),
            ...responsiveGrid(
              context: context,
              children: [
                PreviewGameInfoCard(preview: preview),
                PreviewStatusCard(preview: preview),
              ],
            ),
            const SizedBox(height: 12),
            ConnectionShareCard(userId: userId, token: token),
            if (rawJson != null) ...[
              const SizedBox(height: 12),
              DebugRawJsonCard(rawJson: rawJson!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFullData(BuildContext context, UserDataBean data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: responsiveBody(
        context,
        child: Column(
          children: [
            if (showRestoredNotice)
              AppNotice(
                AppStrings.sessionRestoredNotice,
                icon: Icons.science_outlined,
              ),
            HomeProfileCard(
              userName: data.userName,
              iconId: data.iconId,
              playerRating: data.playerRating,
              highestRating: '${data.highestRating}',
            ),
            const SizedBox(height: 12),
            ...responsiveGrid(
              context: context,
              children: [
                RatingBreakdownCard(data: data),
                FirstPlayCard(data: data),
                GameInfoFromUserDataCard(data: data),
                PlayStatsCard(data: data),
                StatusFromUserDataCard(preview: preview, data: data),
                UserDataDetailCard(data: data),
              ],
            ),
            const SizedBox(height: 12),
            ConnectionShareCard(userId: userId, token: token),
            const SizedBox(height: 12),
            AccountBackupCard(userId: userId, cookies: cookies),
            if (rawJson != null) ...[
              const SizedBox(height: 12),
              DebugRawJsonCard(rawJson: rawJson!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConfigMissingView extends StatelessWidget {
  final VoidCallback onOpenSettings;

  const _ConfigMissingView({required this.onOpenSettings});

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
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.titleServerNotConfigured,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.titleServerNotConfiguredDesc,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings, size: 20),
              label: const Text(AppStrings.openSettings),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final ThemeData theme;
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.theme,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(AppStrings.loadFailed, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}
