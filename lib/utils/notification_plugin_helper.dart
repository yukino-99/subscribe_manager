import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:subscribe_manager/models/subscription.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// 月の日数を取得（m+1, day=0 で当月末日）
int _daysInMonth(int y, int m) => DateTime(y, m + 1, 0).day;

/// 存在しない日付を安全な範囲に丸める（1〜月末）
int _clampDay(int y, int m, int d) {
  final last = _daysInMonth(y, m);
  return d < 1 ? 1 : (d > last ? last : d);
}

/// サブスク1件分のローカル通知をスケジュール
/// - 支払日の「◯日前」を SharedPreferences から取得（無ければ 1日前）
/// - ユーザーが設定した通知時刻を使用
/// - 毎月の同日・同時刻で繰り返し（dayOfMonthAndTime）
Future<void> scheduleNotificationForSubscription(
  Subscription subsc,
  TimeOfDay notificationTime,
) async {
  // 設定値の取得
  final prefs = await SharedPreferences.getInstance();
  final offsetDays = prefs.getInt('notification_offset_days') ?? 1; // 0=当日, 1=前日 etc.

  final now = tz.TZDateTime.now(tz.local);

  // 今月の通知予定日
  final targetDay = _clampDay(now.year, now.month, subsc.payDay - offsetDays);

  tz.TZDateTime scheduled = tz.TZDateTime(
    tz.local, 
    now.year, 
    now.month, 
    targetDay,
    notificationTime.hour, 
    notificationTime.minute,
  );

  // もう過ぎてたら翌月に
  if (!scheduled.isAfter(now)) {
    final nextMonth = now.month == 12 ? 1 : now.month + 1;
    final nextYear  = now.month == 12 ? now.year + 1 : now.year;
    final nextDay   = _clampDay(nextYear, nextMonth, subsc.payDay - offsetDays);
    scheduled = tz.TZDateTime(
      tz.local, nextYear, nextMonth, nextDay,
      notificationTime.hour, notificationTime.minute,
    );
  }

  // 文言（オフセットに応じて）
  String body;
  if (offsetDays == 0) {
    body = '本日${subsc.payDay}日は${subsc.name}の更新日です';
  } else if (offsetDays == 1) {
    body = '明日${subsc.payDay}日は${subsc.name}の更新日です！';
  } else {
    body = '更新まで残り${offsetDays}日（${subsc.payDay}日：${subsc.name}）';
  }

  await flutterLocalNotificationsPlugin.zonedSchedule(
    subsc.hashCode,
    '${subsc.name}のリマインダー',
    body,
    scheduled,
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
    matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
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

/// アプリ起動時に呼ぶ簡易チェック
Future<void> ensureNotificationPermission() async {
  final status = await Permission.notification.status;

  // ❶ まだ決まっていなければリクエスト
  if (status.isDenied) {
    await Permission.notification.request();
    return;
  }

  // ❷ 永久拒否されている場合は “許可が必要です” という SnackBar などを
  //    表示するだけにとどめ、勝手に openAppSettings() へ飛ばさない
  if (status.isPermanentlyDenied) {
    // Optional: 画面上にバナー表示など
  }
}
