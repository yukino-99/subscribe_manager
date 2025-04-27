import 'package:flutter/material.dart';
import 'pages/subsc_list_page.dart';

void main() {
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
