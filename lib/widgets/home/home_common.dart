import 'package:flutter/material.dart';

import '../../config/strings.dart';
import '../app_card.dart';

/// 主页头像：iconId 为 0 时显示占位人形。
class HomeAvatar extends StatelessWidget {
  final int iconId;

  const HomeAvatar({super.key, required this.iconId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CircleAvatar(
      radius: 30,
      backgroundColor: theme.colorScheme.primaryContainer,
      backgroundImage: iconId > 0
          ? NetworkImage('https://assets2.lxns.net/maimai/icon/$iconId.png')
          : null,
      child: iconId == 0
          ? Icon(Icons.person, color: theme.colorScheme.onPrimaryContainer)
          : null,
    );
  }
}

/// 主页顶部的账号概要卡，Preview 与完整数据共用。
///
/// [highestRating] 为 null 时不显示「历史最高」一行（Preview 数据里没有）。
class HomeProfileCard extends StatelessWidget {
  final String userName;
  final int iconId;
  final int playerRating;
  final String? highestRating;

  const HomeProfileCard({
    super.key,
    required this.userName,
    required this.iconId,
    required this.playerRating,
    this.highestRating,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          HomeAvatar(iconId: iconId),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName.isEmpty ? AppStrings.unknownUser : userName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.rating(playerRating),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (highestRating != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${AppStrings.highestRating}: $highestRating',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 主页的「标题 + 字段行」信息卡。
class HomeSectionCard extends StatelessWidget {
  final String title;
  final List<(String, String)> rows;

  const HomeSectionCard({
    super.key,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          for (final (label, value) in rows)
            _InfoRow(label: label, value: value),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// 主页状态卡：标题 + 若干 [HomeStatusChip]。
class HomeStatusCard extends StatelessWidget {
  final List<Widget> chips;

  const HomeStatusCard({super.key, required this.chips});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.status,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ...chips,
        ],
      ),
    );
  }
}

/// 状态行：bool 按成功/失败色渲染成胶囊，其他值原样显示。
class HomeStatusChip extends StatelessWidget {
  final String label;
  final Object? value;
  final String trueText;
  final String falseText;

  const HomeStatusChip(
    this.label,
    this.value, {
    super.key,
    this.trueText = 'Yes',
    this.falseText = 'No',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = value;
    final String text;
    final Color color;
    if (v is bool) {
      text = v ? trueText : falseText;
      color = v ? Colors.green : Colors.grey;
    } else {
      text = '$v';
      color = theme.colorScheme.onSurface;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              text,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
