import 'package:subscribe_manager/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // JSON変換用
import 'package:flutter/material.dart';
import '../models/subscription.dart';
import 'add_subsc_page.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class SubscListPage extends StatefulWidget {
  const SubscListPage({super.key});
  @override
  SubscListPageState createState() => SubscListPageState();
}

class SubscListPageState extends State<SubscListPage> {
  String _selectedPaymentFilter = '全て'; // 初期値は「全て」

  List<Subscription> get filteredSubscList {
    if (_selectedPaymentFilter == '全て') {
      return subscList;
    } else {
      return subscList
          .where((subsc) => subsc.paymentMethod == _selectedPaymentFilter)
          .toList();
    }
  }

  List<Subscription> subscList = [];

  @override
  void initState() {
    super.initState();
    loadSubscList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('サブスク管理')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '合計：$totalMonthlyCost円',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: _selectedPaymentFilter,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPaymentFilter = newValue!;
                });
              },
              items:
                  paymentMethodsForFilter
                      .map(
                        (method) => DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        ),
                      )
                      .toList(),
            ),
          ),
          Expanded(
            child:
                filteredSubscList.isEmpty
                    ? Center(child: Text('登録されているサブスクがありません'))
                    : ListView.builder(
                      itemCount: filteredSubscList.length,
                      itemBuilder: (context, index) {
                        final subsc = filteredSubscList[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Card(
                            margin: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Slidable(
                              key: Key(subsc.name),
                              endActionPane: ActionPane(
                                motion: ScrollMotion(),
                                dismissible: DismissiblePane(
                                  onDismissed: () {
                                    setState(() {
                                      subscList.remove(subsc);
                                    });
                                    saveSubscList();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${subsc.name}を削除しました'),
                                      ),
                                    );
                                  },
                                ),
                                children: [
                                  SlidableAction(
                                    onPressed: (context) {
                                      setState(() {
                                        subscList.remove(subsc);
                                      });
                                      saveSubscList();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('${subsc.name}を削除しました'),
                                        ),
                                      );
                                    },
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete,
                                    label: '削除',
                                  ),
                                ],
                              ),
                              child: ListTile(
                                onTap: () async {
                                  final editedSubsc = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => AddSubscPage(
                                            subscription: subsc, // ← 編集対象を渡す！！
                                          ),
                                    ),
                                  );

                                  if (editedSubsc != null) {
                                    setState(() {
                                      subscList[subscList.indexOf(subsc)] =
                                          editedSubsc;
                                    });
                                    saveSubscList();
                                  }
                                },
                                title: Text(
                                  subsc.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    '${subsc.price}円 / 支払日: ${subsc.payDay}日 / ${subsc.paymentMethod}',
                                    style: TextStyle(fontSize: 14),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newSubsc = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddSubscPage()),
          );

          if (newSubsc != null) {
            setState(() {
              subscList.add(newSubsc);
            });
            saveSubscList();
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  int get totalMonthlyCost {
    return filteredSubscList.fold(0, (sum, item) => sum + item.price);
  }

  Future<void> saveSubscList() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> subscJsonList =
        subscList.map((subsc) {
          return jsonEncode({
            'name': subsc.name,
            'price': subsc.price,
            'payDay': subsc.payDay,
            'paymentMethod': subsc.paymentMethod,
          });
        }).toList();

    await prefs.setStringList('subscList', subscJsonList);
  }

  Future<void> loadSubscList() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? subscJsonList = prefs.getStringList('subscList');

    if (subscJsonList != null) {
      setState(() {
        subscList =
            subscJsonList.map((jsonStr) {
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
}
