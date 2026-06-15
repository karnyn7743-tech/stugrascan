import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تقرير الرصد الحسابي')),
      body: const Center(
          child: Text('تم رصد وحفظ جميع الدرجات بنجاح في كشف الإكسيل!')),
    );
  }
}
