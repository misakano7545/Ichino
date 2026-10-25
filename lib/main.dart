import 'package:flutter/material.dart';

import 'config/strings.dart';
import 'config/title_server_config.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TitleServerConfigHolder().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  /// 默认从登录页启动；开发预览等入口可传入别的根页面。
  final Widget? home;

  const MyApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: home ?? const LoginPage(),
    );
  }
}
