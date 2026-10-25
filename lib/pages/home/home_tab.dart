import 'package:flutter/material.dart';

import '../../config/strings.dart';

/// 主页底部导航的六个页签，顺序即 [IndexedStack] 的下标。
enum HomeTab {
  home(AppStrings.tabHome, Icons.home_outlined, Icons.home),
  tickets(
    AppStrings.tabTickets,
    Icons.confirmation_number_outlined,
    Icons.confirmation_number,
  ),
  best50(AppStrings.tabBest50, Icons.bar_chart_outlined, Icons.bar_chart),
  risk(AppStrings.tabRisk, Icons.warning_outlined, Icons.inventory_2),
  settings(AppStrings.tabSettings, Icons.settings_outlined, Icons.settings),
  about(AppStrings.tabAbout, Icons.info_outlined, Icons.info);

  final String title;
  final IconData icon;
  final IconData selectedIcon;

  const HomeTab(this.title, this.icon, this.selectedIcon);
}
