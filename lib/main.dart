import 'package:flutter/material.dart';
import 'package:subscribe_manager/services/notification_service.dart';
import 'pages/subsc_list_page.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ATT ダイアログ （iOS14+）
  final status = await AppTrackingTransparency.trackingAuthorizationStatus;
  if (status == TrackingStatus.notDetermined) {
    await AppTrackingTransparency.requestTrackingAuthorization();
  }

  // AdMob SDK 初期化
  await MobileAds.instance.initialize();

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
