import 'package:subscribe_manager/constants.dart';
import 'package:flutter/material.dart';
import '../models/subscription.dart';

class AddSubscPage extends StatefulWidget {
  const AddSubscPage({super.key});
  @override
  AddSubscPageState createState() => AddSubscPageState();
}

class AddSubscPageState extends State<AddSubscPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _payDayController = TextEditingController();
  String _selectedPaymentMethod = 'クレカ';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('サブスク追加')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'サービス名'),
            ),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: '月額料金（円）'),
            ),
            TextField(
              controller: _payDayController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: '支払日（1〜31）'),
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              items:
                  paymentMethods
                      .map(
                        (method) => DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
              decoration: InputDecoration(labelText: '支払い方法'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isEmpty ||
                    _priceController.text.isEmpty ||
                    _payDayController.text.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('全て入力してね')));
                  return;
                }

                final newSubsc = Subscription(
                  name: _nameController.text,
                  price: int.parse(_priceController.text),
                  payDay: int.parse(_payDayController.text),
                  paymentMethod: _selectedPaymentMethod,
                );
                Navigator.pop(context, newSubsc);
              },
              child: Text('追加'),
            ),
          ],
        ),
      ),
    );
  }
}
