import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:url_launcher/url_launcher.dart'; // 使ってなければ消してOK

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);
  int _offsetDays = 1;        // 0=当日, 1=前日, 3, 7
  bool _changed = false;      // 戻るときに true を返す用

  @override
  void initState() {
    super.initState();
    loadNotificationTime();
    loadOffsetDays();
  }

  @override
Widget build(BuildContext context) {
  return PopScope(
    // システム戻る（ジェスチャ含む）も一旦ここに来させる
    canPop: false,
    onPopInvokedWithResult: (bool didPop, Object? result) {
      // 既に pop 済みなら何もしない
      if (didPop) return;
      // ここで「結果つき」で戻る
      Navigator.pop(context, _changed);
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        // 明示的な戻るボタンも「結果つき」で pop
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _changed),
        ),
      ),
      body: ListView(
          children: [
            // 基準の明示
            ListTile(
              title: const Text('通知タイミング'),
              subtitle: Text(
                '支払日の${_labelForOffset(_offsetDays)} の ${_notificationTime.format(context)} に通知',
              ),
            ),

            // ◯日前の選択
            ListTile(
              title: const Text('通知日（何日前）'),
              trailing: DropdownButton<int>(
                value: _offsetDays,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('当日')),
                  DropdownMenuItem(value: 1, child: Text('1日前')),
                  DropdownMenuItem(value: 3, child: Text('3日前')),
                  DropdownMenuItem(value: 7, child: Text('7日前')),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  setState(() => _offsetDays = v);
                  await saveOffsetDays(v);
                  _changed = true;
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('通知日を更新しました')),
                    );
                  }
                },
              ),
            ),

            // 通知時間の変更
            ListTile(
              title: const Text('通知時間の変更'),
              subtitle: Text(_notificationTime.format(context)),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _notificationTime,
                );
                if (picked != null) {
                  setState(() => _notificationTime = picked);
                  await saveNotificationTime(picked);
                  _changed = true;
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('通知時間を更新しました')),
                    );
                  }
                }
              },
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '※ サービスにより解約期限は異なる場合があります。必要に応じて「◯日前」を調整してください。',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelForOffset(int d) {
    switch (d) {
      case 0:
        return '当日';
      case 1:
        return '前日';
      default:
        return '$d日前';
    }
  }

  Future<void> saveOffsetDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_offset_days', days);
  }

  Future<void> loadOffsetDays() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _offsetDays = prefs.getInt('notification_offset_days') ?? 1;
    });
  }

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