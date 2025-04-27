import 'package:subscribe_manager/constants.dart';
import 'package:flutter/material.dart';
import '../models/subscription.dart';

class AddSubscPage extends StatefulWidget {
  final Subscription? subscription;
  AddSubscPage({super.key, this.subscription});

  @override
  AddSubscPageState createState() => AddSubscPageState();
}

class AddSubscPageState extends State<AddSubscPage> {
  late TextEditingController _nameController = TextEditingController();
  late TextEditingController _priceController = TextEditingController();
  late TextEditingController _payDayController = TextEditingController();
  String _selectedPaymentMethod = 'クレカ';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.subscription?.name ?? '',
    );
    _priceController = TextEditingController(
      text: widget.subscription?.price.toString() ?? '',
    );
    _payDayController = TextEditingController(
      text: widget.subscription?.payDay.toString() ?? '',
    );
    _selectedPaymentMethod = widget.subscription?.paymentMethod ?? 'クレカ';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _payDayController.dispose();
    super.dispose();
  }

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

                final editedSubsc = Subscription(
                  name: _nameController.text,
                  price: int.parse(_priceController.text),
                  payDay: int.parse(_payDayController.text),
                  paymentMethod: _selectedPaymentMethod,
                );

                Navigator.pop(context, editedSubsc);
              },
              child: Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
