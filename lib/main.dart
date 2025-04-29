import 'package:flutter/material.dart';
import 'package:subscribe_manager/services/notification_service.dart';
import 'pages/subsc_list_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 通知サービス（tz + プラグイン）の初期化を一度だけ実行
  await NotificationService.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'サブスク管理',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SubscListPage(),
    );
  }
}
