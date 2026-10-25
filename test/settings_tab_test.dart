import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ichino/config/strings.dart';
import 'package:ichino/config/title_server_config.dart';
import 'package:ichino/models/session_model.dart';
import 'package:ichino/pages/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await TitleServerConfigHolder().clear();
    SessionModel.instance.reset();
  });

  testWidgets('设置页作为主页页签保存时不会弹掉根路由', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SettingsPage(showAppBar: false)),
      ),
    );

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(11));
    for (var i = 0; i < 11; i++) {
      await tester.enterText(fields.at(i), 'value');
    }

    final save = find.widgetWithText(FilledButton, AppStrings.save);
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    // 根路由还在，页面没有变成黑屏；改为用 SnackBar 提示已保存。
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text(AppStrings.configSaved), findsOneWidget);
    expect(tester.state<NavigatorState>(find.byType(Navigator)).canPop(), isFalse);
  });
}
