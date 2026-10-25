import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ichino/config/strings.dart';
import 'package:ichino/main.dart';
import 'package:ichino/models/session_share.dart';

/// 登录页的输入既可能是 QR 令牌，也可能是主页导出的「连接信息」，
/// 两条路都要有可见反馈，不能出现点了没反应。
void main() {
  testWidgets('粘贴不认识的令牌时点登录会给出提示', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // 72 位：既不是 84 位二维码串，也不是二维码链接
    await tester.enterText(find.byType(TextField), 'ABCDEF' * 12);
    await tester.pump();

    await tester.tap(find.text(AppStrings.login));
    await tester.pump();

    expect(
      find.textContaining(AppStrings.qrTokenUnrecognized),
      findsOneWidget,
    );
  });

  testWidgets('粘贴连接信息时按钮切成「恢复会话」', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    const share = SessionShare(
      userId: 7,
      token: 'SGWCMAIDtoken',
      cookie: 'JSESSIONID=x',
    );
    await tester.enterText(find.byType(TextField), share.encode());
    await tester.pump();

    expect(find.text(AppStrings.sessionShareDetected), findsOneWidget);
    expect(find.text(AppStrings.restoreSession), findsOneWidget);
    expect(find.text(AppStrings.login), findsNothing);
  });
}
