import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  TimeOfDay _notificationTime = TimeOfDay(hour: 9, minute: 0); // デフォルト9:00

  @override
  void initState() {
    super.initState();
    loadNotificationTime();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('設定')),
      body: ListView(
        children: [
          ListTile(
            title: Text('通知時間の変更'),
            subtitle: Text('${_notificationTime.format(context)} に通知'),
            trailing: Icon(Icons.chevron_right),
            onTap: () async {
              TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: _notificationTime,
              );
              if (pickedTime != null) {
                setState(() {
                  _notificationTime = pickedTime;
                });
                saveNotificationTime(pickedTime);
              }
            },
          ),

          /// プライバシーポリシーリンクタイル
          ListTile(
            title: const Text('プライバシーポリシー'),
            leading: const Icon(Icons.privacy_tip),
            onTap: () async {
              final url = Uri.parse(
                'https://yukino-99.github.io/privacy-policy/sub_manager_policy.html',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                debugPrint('URLを開けません: $url');
              }
            },
          ),
        ],
      ),
    );
  }

  ///
  Future<void> saveNotificationTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_hour', time.hour);
    await prefs.setInt('notification_minute', time.minute);
  }

  Future<void> loadNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('notification_hour') ?? 9;
    final minute = prefs.getInt('notification_minute') ?? 0;

    setState(() {
      _notificationTime = TimeOfDay(hour: hour, minute: minute);
    });
  }
}
