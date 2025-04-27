import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/subscription.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  tz.initializeTimeZones();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher'); // アイコン設定（そのままでOK）

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(); // iOS設定（デフォルト）

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> scheduleNotificationForSubscription(Subscription subsc) async {
  final now = DateTime.now();

  // 支払日の1日前
    final notificationDate = tz.TZDateTime.local(
    now.year,
    now.month,
    subsc.payDay - 1,
    9, 0, 0,
  ); // 朝9時に通知

  if (notificationDate.isBefore(now)) {
    // すでに過ぎてたらスキップ
    return;
  }

  await flutterLocalNotificationsPlugin.zonedSchedule(
    subsc.hashCode, // 通知ID（ユニーク）
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
