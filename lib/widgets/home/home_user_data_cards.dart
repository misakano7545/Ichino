import 'package:flutter/material.dart';

import '../../config/strings.dart';
import '../../models/user_data.dart';
import '../../models/user_preview.dart';
import '../app_card.dart';
import 'home_common.dart';

class RatingBreakdownCard extends StatelessWidget {
  final UserDataBean data;

  const RatingBreakdownCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return HomeSectionCard(
      title: AppStrings.ratingBreakdown,
      rows: [
        (AppStrings.musicRating, '${data.musicRating}'),
        (AppStrings.newChartRating, '${data.playerNewRating}'),
        (AppStrings.oldChartRating, '${data.playerOldRating}'),
        (AppStrings.highestRating, '${data.highestRating}'),
      ],
    );
  }
}

class FirstPlayCard extends StatelessWidget {
  final UserDataBean data;

  const FirstPlayCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return HomeSectionCard(
      title: AppStrings.firstPlay,
      rows: [
        (AppStrings.joinDate, data.firstPlayDate),
        (AppStrings.firstGame, data.firstGameId),
        (AppStrings.firstRomVersion, data.firstRomVersion),
        (AppStrings.firstDataVersion, data.firstDataVersion),
      ],
    );
  }
}

class GameInfoFromUserDataCard extends StatelessWidget {
  final UserDataBean data;

  const GameInfoFromUserDataCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return HomeSectionCard(
      title: AppStrings.gameInfo,
      rows: [
        (AppStrings.lastGame, data.lastGameId),
        (AppStrings.lastPlay, data.lastPlayDate),
        (AppStrings.lastLogin, data.lastLoginDate),
        (AppStrings.romVersion, data.lastRomVersion),
        (AppStrings.dataVersion, data.lastDataVersion),
        (
          AppStrings.lastRegion,
          '${data.lastRegionName}${data.lastRegionId > 0 ? ' (${data.lastRegionId})' : ''}',
        ),
      ],
    );
  }
}

class PlayStatsCard extends StatelessWidget {
  final UserDataBean data;

  const PlayStatsCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return HomeSectionCard(
      title: AppStrings.playStats,
      rows: [
        (AppStrings.playCount, '${data.playCount}'),
        (AppStrings.currentPlayCount, '${data.currentPlayCount}'),
        (AppStrings.totalAchievement, '${data.totalAchievement}'),
        (AppStrings.totalDxScore, '${data.totalDeluxscore}'),
        (AppStrings.totalSync, '${data.totalSync}'),
        (AppStrings.totalAwake, '${data.totalAwake}'),
      ],
    );
  }
}

class StatusFromUserDataCard extends StatelessWidget {
  /// 用连接信息（仅 JSESSIONID）恢复的会话没有走 GetUserPreviewApi，可为空。
  final UserPreviewDataBean? preview;
  final UserDataBean data;

  const StatusFromUserDataCard({
    super.key,
    required this.preview,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final p = preview;

    return HomeStatusCard(
      chips: [
        HomeStatusChip(AppStrings.netMember, data.isNetMember),
        if (p != null) HomeStatusChip(AppStrings.inherit, p.isInherit),
        HomeStatusChip(
          AppStrings.banState,
          data.banState == 0,
          trueText: AppStrings.clean,
          falseText: '已封禁 (${data.banState})',
        ),
        HomeStatusChip(
          AppStrings.dailyBonus,
          data.dailyBonusDate.isNotEmpty &&
              !data.dailyBonusDate.startsWith('1970'),
          trueText: data.dailyBonusDate,
          falseText: AppStrings.notClaimed,
        ),
      ],
    );
  }
}

/// 可展开的原始字段卡。
class UserDataDetailCard extends StatefulWidget {
  final UserDataBean data;

  const UserDataDetailCard({super.key, required this.data});

  @override
  State<UserDataDetailCard> createState() => _UserDataDetailCardState();
}

class _UserDataDetailCardState extends State<UserDataDetailCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = widget.data;

    return AppCard(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.moreDetails,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 14),
            _detailRow(theme, AppStrings.userId, '${data.userId}'),
            _detailRow(theme, AppStrings.point, '${data.point}'),
            _detailRow(theme, AppStrings.totalPoint, '${data.totalPoint}'),
            _detailRow(theme, AppStrings.iconId, '${data.iconId}'),
            _detailRow(theme, AppStrings.nameplateId, '${data.nameplateId}'),
            _detailRow(theme, AppStrings.plateId, '${data.plateId}'),
            _detailRow(theme, AppStrings.frameId, '${data.frameId}'),
            _detailRow(theme, AppStrings.titleId, '${data.titleId}'),
            _detailRow(theme, AppStrings.trophyId, '${data.trophyId}'),
            _detailRow(theme, AppStrings.partnerId, '${data.partnerId}'),
            _detailRow(theme, AppStrings.gradeRank, '${data.gradeRank}'),
            _detailRow(theme, AppStrings.courseRank, '${data.courseRank}'),
            _detailRow(theme, AppStrings.classRank, '${data.classRank}'),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
