import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subscribe_manager/models/subscription.dart';
import 'package:subscribe_manager/utils/notification_plugin_helper.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  /// 初期化を保証するパブリック API  
  /// 何度呼んでも内部は 1 回しか実行されない。
  static Future<void> ensureInitialized() => _initializer;
  /// _initializer は late final Future で再入防止。
  static final Future<void> _initializer = _initInternal();

  /// 内部で実際に初期化を行うプライベートメソッド。
  static Future<void> _initInternal() async {
    // Flutterバインディング
    WidgetsFlutterBinding.ensureInitialized();

    // ① TimeZone DB をロード
    tz.initializeTimeZones();

    // ② 端末のローカルタイムゾーンを設定
    final String localName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localName));

    // ③ 通知プラグイン自体を初期化
    await initializeNotifications();
  }

  /// 全サブスクの通知をリスケする
  static Future<void> rescheduleAllNotifications(List<Subscription> subscList) async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('notification_hour') ?? 9;
    final minute = prefs.getInt('notification_minute') ?? 0;
    final notificationTime = TimeOfDay(hour: hour, minute: minute);

    for (final subsc in subscList) {
      await scheduleNotificationForSubscription(subsc, notificationTime);
    }
  }

  /// 1つのサブスクだけ通知キャンセルする
  static Future<void> cancelNotificationForSubscription(Subscription subsc) async {
    await flutterLocalNotificationsPlugin.cancel(subsc.hashCode);
  }

  /// 全通知キャンセル
  static Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  /// 1つのサブスクの通知を設定する
  static Future<void> setNotificationSchedule(Subscription subsc) async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('notification_hour') ?? 9;
    final minute = prefs.getInt('notification_minute') ?? 0;
    final notificationTime = TimeOfDay(hour: hour, minute: minute);

    await scheduleNotificationForSubscription(subsc, notificationTime);
  }
}