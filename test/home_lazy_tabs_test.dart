import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ichino/config/strings.dart';
import 'package:ichino/config/title_server_config.dart';
import 'package:ichino/dev/ui_preview_data.dart';
import 'package:ichino/models/session_model.dart';
import 'package:ichino/pages/about_page.dart';
import 'package:ichino/pages/best50_page.dart';
import 'package:ichino/pages/high_risk_feature_page.dart';
import 'package:ichino/pages/home/home_tab_view.dart';
import 'package:ichino/pages/home_page.dart';
import 'package:ichino/pages/settings_page.dart';
import 'package:ichino/pages/ticket_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await TitleServerConfigHolder().clear();
    SessionModel.instance.reset();
  });

  testWidgets('主页启动时只构建首页，其他页签首次访问才创建', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomePage(userId: 1, token: 't')),
    );
    await tester.pump();

    expect(find.byType(HomeTabView), findsOneWidget);
    expect(find.byType(TicketPage), findsNothing);
    expect(find.byType(Best50Page), findsNothing);
    expect(find.byType(HighRiskFeaturePage), findsNothing);
    expect(find.byType(SettingsPage), findsNothing);
    expect(find.byType(AboutPage), findsNothing);

    await tester.tap(find.byIcon(Icons.bar_chart_outlined));
    await tester.pump();

    expect(find.byType(Best50Page), findsOneWidget);
    expect(find.widgetWithText(AppBar, AppStrings.tabBest50), findsOneWidget);
    // 其余页签仍未构建。
    expect(find.byType(TicketPage), findsNothing);
    expect(find.byType(SettingsPage), findsNothing);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();

    expect(find.byType(SettingsPage), findsOneWidget);
    // 已访问过的页签保留在 IndexedStack 里，切换回来不重建。
    expect(find.byType(Best50Page, skipOffstage: false), findsOneWidget);
    expect(find.byType(TicketPage), findsNothing);
  });

  testWidgets('有预览种子数据时，未配置 Title Server 也展示主页数据', (tester) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(
          userId: uiPreviewUserId,
          token: uiPreviewToken,
          restored: SessionRestoreResult(
            reusedCookie: true,
            userData: uiPreviewUserData,
            preview: uiPreviewPreview,
            loggedIn: true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(AppStrings.titleServerNotConfigured), findsNothing);
    expect(find.text('Ichino'), findsOneWidget);
  });
}
