import 'package:flutter/material.dart';
import 'screens/scanner_screen.dart'; // استدعاء شاشة المسح الحية

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام أبو الخضر البعيثي للرصد الذكي',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Cairo',
      ),
      home: const ScannerScreen(), // التشغيل المباشر لشاشة المسح والـ OCR
      locale: const Locale('ar', 'YE'),
      debugShowCheckedModeBanner: false,
    );
  }
}
