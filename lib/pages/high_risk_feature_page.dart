import 'package:flutter/material.dart';

import '../config/strings.dart';
import '../config/title_server_config.dart';
import '../widgets/cooldown_mixin.dart';
import '../widgets/risk/risk_widgets.dart';
import 'collectibles_page.dart';
import 'kaleidx_scope_page.dart';
import 'map_traverse_page.dart';
import 'number_patch_page.dart';
import 'travel_partner_page.dart';
import 'unlock_music_page.dart';

/// 高危功能中转页：导航到解锁歌曲 / 收藏品获取 / 旅行伙伴 / 数值修改。
/// 各 feature 互相独立，执行流程互不影响。
class HighRiskFeaturePage extends StatefulWidget {
  final int userId;
  final String? cookies;

  /// `loginDateTime` 来自 HomePage 启动时执行的 UserLoginApi。
  /// 为 `null` 时表示当前未持有有效登录态。
  final int? loginDateTime;

  /// UserLoginApi 返回的 loginId / lastLoginDate, 组装 UserAll 需要。
  final int? loginId;
  final String? lastLoginDate;

  /// 完成后自动退出登录并返回标题页，由 HomePage 执行结算+退登+pop。
  final Future<void> Function()? onExitToTitle;

  const HighRiskFeaturePage({
    super.key,
    required this.userId,
    this.cookies,
    this.loginDateTime,
    this.loginId,
    this.lastLoginDate,
    this.onExitToTitle,
  });

  @override
  State<HighRiskFeaturePage> createState() => _HighRiskFeaturePageState();
}

class _HighRiskFeaturePageState extends State<HighRiskFeaturePage>
    with CooldownMixin<HighRiskFeaturePage> {
  @override
  int? get cooldownLoginDateTime => widget.loginDateTime;

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  /// 中转页只是导航入口，七张卡片的差异只有图标、文案和目标页，
  /// 用一张表驱动，避免七份几乎相同的 `Navigator.push`。
  List<({IconData icon, String title, String desc, Widget page})> get _entries {
    return [
      (
        icon: Icons.lock_open,
        title: AppStrings.unlockFeatureTitle,
        desc: AppStrings.unlockFeatureDesc,
        page: UnlockMusicPage(
          userId: widget.userId,
          cookies: widget.cookies,
          loginDateTime: widget.loginDateTime,
          loginId: widget.loginId,
          lastLoginDate: widget.lastLoginDate,
          onExitToTitle: widget.onExitToTitle,
        ),
      ),
      (
        icon: Icons.card_giftcard,
        title: AppStrings.collectiblesFeatureTitle,
        desc: AppStrings.collectiblesFeatureDesc,
        page: CollectiblesPage(
          userId: widget.userId,
          cookies: widget.cookies,
          loginDateTime: widget.loginDateTime,
          loginId: widget.loginId,
          lastLoginDate: widget.lastLoginDate,
          onExitToTitle: widget.onExitToTitle,
        ),
      ),
      (
        icon: Icons.workspace_premium_outlined,
        title: AppStrings.travelPartnerFeatureTitle,
        desc: AppStrings.travelPartnerFeatureDesc,
        page: TravelPartnerPage(
          userId: widget.userId,
          cookies: widget.cookies,
          loginDateTime: widget.loginDateTime,
          loginId: widget.loginId,
          onExitToTitle: widget.onExitToTitle,
        ),
      ),
      (
        icon: Icons.speed,
        title: AppStrings.ratingFeatureTitle,
        desc: AppStrings.ratingFeatureDesc,
        page: NumberPatchPage(
          userId: widget.userId,
          cookies: widget.cookies,
          loginDateTime: widget.loginDateTime,
          loginId: widget.loginId,
          onExitToTitle: widget.onExitToTitle,
          mode: NumberPatchMode.rating,
        ),
      ),
      (
        icon: Icons.commute,
        title: AppStrings.maiMileFeatureTitle,
        desc: AppStrings.maiMileFeatureDesc,
        page: NumberPatchPage(
          userId: widget.userId,
          cookies: widget.cookies,
          loginDateTime: widget.loginDateTime,
          loginId: widget.loginId,
          onExitToTitle: widget.onExitToTitle,
          mode: NumberPatchMode.maiMile,
        ),
      ),
      (
        icon: Icons.map_outlined,
        title: AppStrings.mapFeatureTitle,
        desc: AppStrings.mapFeatureDesc,
        page: MapTraversePage(
          userId: widget.userId,
          cookies: widget.cookies,
          loginDateTime: widget.loginDateTime,
          loginId: widget.loginId,
          onExitToTitle: widget.onExitToTitle,
        ),
      ),
      (
        icon: Icons.science_outlined,
        title: AppStrings.kaleidxFeatureTitle,
        desc: AppStrings.kaleidxFeatureDesc,
        page: KaleidxScopePage(
          userId: widget.userId,
          cookies: widget.cookies,
          loginDateTime: widget.loginDateTime,
          loginId: widget.loginId,
          onExitToTitle: widget.onExitToTitle,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (!TitleServerConfigHolder().isConfigured) {
      return const RiskConfigMissingView(
        message: AppStrings.ticketNotConfigured,
      );
    }

    final entries = _entries;
    return RiskPageBody(
      children: [
        RiskStatusNotices(
          isLoggedIn: isLoggedIn,
          cooldownRemaining: cooldownRemaining,
          notLoggedInText: AppStrings.musicRiskHubNotLoggedIn,
          cooldownText: AppStrings.musicRiskHubCooldownNotice,
        ),
        const RiskFeatureCard(
          icon: Icons.warning_amber_rounded,
          title: AppStrings.musicRiskHubTitle,
          description: AppStrings.musicRiskHubDesc,
          danger: true,
        ),
        for (var i = 0; i < entries.length; i++) ...[
          const SizedBox(height: 12),
          _NavCard(
            icon: entries[i].icon,
            title: entries[i].title,
            desc: entries[i].desc,
            onTap: () => _push(entries[i].page),
          ),
        ],
      ],
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 28, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
