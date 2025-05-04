import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:subscribe_manager/models/subscription.dart';
import 'package:permission_handler/permission_handler.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Flutter通知プラグインの初期化
Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

/// 1件のサブスクについて通知をスケジュール登録する
Future<void> scheduleNotificationForSubscription(
  Subscription subsc,
  TimeOfDay notificationTime,
) async {
  final now = DateTime.now();
  final notificationDate = tz.TZDateTime.local(
    now.year,
    now.month,
    subsc.payDay - 1,
    notificationTime.hour,
    notificationTime.minute,
  );

  if (notificationDate.isBefore(now)) {
    return;
  }

  await flutterLocalNotificationsPlugin.zonedSchedule(
    subsc.hashCode,
    '${subsc.name}の支払日リマインダー',
    '明日${subsc.payDay}日は${subsc.name}の支払日です！',
    notificationDate,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'subsc_reminder_channel',
        'サブスクリマインダー',
        channelDescription: 'サブスク支払日のリマインダー通知',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.dateAndTime,
  );
}

/// 通知権限のステータスを確認し、必要に応じてユーザーに許可を求める
Future<void> handleNotificationPermission() async {
  final status = await Permission.notification.status;

  if (status.isDenied || status.isRestricted) {
    final result = await Permission.notification.request();

    if (result.isPermanentlyDenied) {
      openAppSettings();
    }
  }
}
