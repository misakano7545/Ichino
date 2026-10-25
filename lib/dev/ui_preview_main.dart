import 'package:flutter/material.dart';

import '../main.dart';
import '../pages/home_page.dart';
import 'ui_preview_data.dart';

/// 开发期 UI 预览入口：跳过二维码登录，直接用假数据进主页。
///
/// flutter run -d windows -t lib/dev/ui_preview_main.dart --no-pub
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final restored = createUiPreviewSession();
  runApp(
    MyApp(
      home: HomePage(
        userId: uiPreviewUserId,
        token: uiPreviewToken,
        restored: restored,
      ),
    ),
  );
}
