import 'package:subscribe_manager/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/subscription.dart';
import 'add_subsc_page.dart';
import 'setting_page.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:subscribe_manager/services/notification_service.dart'; // ← 通知管理用サービスをimport

class SubscListPage extends StatefulWidget {
  const SubscListPage({super.key});
  @override
  SubscListPageState createState() => SubscListPageState();
}

class SubscListPageState extends State<SubscListPage> {
  String _selectedPaymentFilter = '全て'; // 支払い方法フィルター
  List<Subscription> subscList = [];     // サブスクデータ本体

  /// 支払い方法でフィルタリングしたリスト
  List<Subscription> get filteredSubscList {
    if (_selectedPaymentFilter == '全て') {
      return subscList;
    } else {
      return subscList.where((subsc) => subsc.paymentMethod == _selectedPaymentFilter).toList();
    }
  }

  @override
  void initState() {
    super.initState();
    loadSubscList(); // アプリ起動時にローカル保存データをロード
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('サブスク管理'),
        actions: [
          // 設定ボタン（通知時間設定画面への遷移）
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final rescheduleNeeded = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (context) => const SettingPage()),
              );
              // 戻り値がtrueならリスケ
              if (rescheduleNeeded == true) {
                await NotificationService.rescheduleAllNotifications(subscList);
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 合計金額表示
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '合計：$totalMonthlyCost円',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          // フィルター選択ドロップダウン
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: _selectedPaymentFilter,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPaymentFilter = newValue!;
                });
              },
              items: paymentMethodsForFilter.map(
                (method) => DropdownMenuItem(
                  value: method,
                  child: Text(method),
                ),
              ).toList(),
            ),
          ),
          // サブスク一覧表示エリア
          Expanded(
            child: filteredSubscList.isEmpty
                ? const Center(child: Text('登録されているサブスクがありません'))
                : ListView.builder(
                    itemCount: filteredSubscList.length,
                    itemBuilder: (context, index) {
                      final subsc = filteredSubscList[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Slidable(
                            key: Key(subsc.name),
                            endActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              dismissible: DismissiblePane(
                                onDismissed: () async {
                                  await _deleteSubscription(subsc);
                                },
                              ),
                              children: [
                                SlidableAction(
                                  onPressed: (context) async {
                                    await _deleteSubscription(subsc);
                                  },
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete,
                                  label: '削除',
                                ),
                              ],
                            ),
                            child: ListTile(
                              // サブスクタップで編集画面へ遷移
                              onTap: () async {
                                final editedSubsc = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddSubscPage(subscription: subsc),
                                  ),
                                );

                                if (editedSubsc != null) {
                                  setState(() {
                                    subscList[subscList.indexOf(subsc)] = editedSubsc;
                                  });
                                  await saveSubscList();
                                  await NotificationService.setNotificationSchedule(editedSubsc);
                                }
                              },
                              title: Text(
                                subsc.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '${subsc.price}円 / 支払日: ${subsc.payDay}日 / ${subsc.paymentMethod}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      // サブスク追加ボタン
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newSubsc = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddSubscPage()),
          );

          if (newSubsc != null) {
            setState(() {
              subscList.add(newSubsc);
            });
            await saveSubscList();
            await NotificationService.setNotificationSchedule(newSubsc);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// フィルター済みリストの合計金額を計算
  int get totalMonthlyCost {
    return filteredSubscList.fold(0, (sum, item) => sum + item.price);
  }

  /// サブスクデータをローカル保存
  Future<void> saveSubscList() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> subscJsonList = subscList.map((subsc) {
      return jsonEncode({
        'name': subsc.name,
        'price': subsc.price,
        'payDay': subsc.payDay,
        'paymentMethod': subsc.paymentMethod,
      });
    }).toList();

    await prefs.setStringList('subscList', subscJsonList);
  }

  /// サブスクデータをローカルからロード
  Future<void> loadSubscList() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? subscJsonList = prefs.getStringList('subscList');

    if (subscJsonList != null) {
      setState(() {
        subscList = subscJsonList.map((jsonStr) {
          final Map<String, dynamic> map = jsonDecode(jsonStr);
          return Subscription(
            name: map['name'],
            price: map['price'],
            payDay: map['payDay'],
            paymentMethod: map['paymentMethod'],
          );
        }).toList();
      });
    }
  }

  /// サブスクをリストから削除＋通知キャンセル
  Future<void> _deleteSubscription(Subscription subsc) async {
    setState(() {
      subscList.remove(subsc);
    });
    await saveSubscList();
    await NotificationService.cancelNotificationForSubscription(subsc);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${subsc.name}を削除しました')),
    );
  }
}