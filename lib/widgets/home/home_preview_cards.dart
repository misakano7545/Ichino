import 'package:flutter/material.dart';

import '../../config/strings.dart';
import '../../models/user_preview.dart';
import 'home_common.dart';

class PreviewGameInfoCard extends StatelessWidget {
  final UserPreviewDataBean preview;

  const PreviewGameInfoCard({super.key, required this.preview});

  @override
  Widget build(BuildContext context) {
    return HomeSectionCard(
      title: AppStrings.gameInfo,
      rows: [
        (AppStrings.lastGame, preview.lastGameId),
        (AppStrings.lastPlay, preview.lastPlayDate),
        (AppStrings.lastLogin, preview.lastLoginDate),
        (AppStrings.romVersion, preview.lastRomVersion),
        (AppStrings.dataVersion, preview.lastDataVersion),
      ],
    );
  }
}

class PreviewStatusCard extends StatelessWidget {
  final UserPreviewDataBean preview;

  const PreviewStatusCard({super.key, required this.preview});

  @override
  Widget build(BuildContext context) {
    return HomeStatusCard(
      chips: [
        HomeStatusChip(AppStrings.netMember, preview.isNetMember),
        HomeStatusChip(AppStrings.inherit, preview.isInherit),
        HomeStatusChip(
          AppStrings.banState,
          preview.banState == 0,
          trueText: AppStrings.clean,
          falseText: '已封禁 (${preview.banState})',
        ),
      ],
    );
  }
}
