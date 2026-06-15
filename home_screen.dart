import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final List<String> subjects = [
    'القرآن الكريم',
    'اللغة العربية',
    'الرياضيات',
    'العلوم',
    'الإنجليزي',
  ];

  String selectedSubject = 'الرياضيات';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('رصد درجات الطلاب'),
          centerTitle: true,
        ),

        body: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () {},
                child: const Text(
                  'اختيار ملف Excel',
                  style: TextStyle(fontSize: 18),
                ),
              ),

              const SizedBox(height: 30),

              DropdownButton<String>(
                value: selectedSubject,
                isExpanded: true,

                items: subjects.map((subject) {
                  return DropdownMenuItem(
                    value: subject,
                    child: Text(subject),
                  );
                }).toList(),

                onChanged: (value) {
                  setState(() {
                    selectedSubject = value!;
                  });
                },
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: () {},

                child: const Text(
                  'بدء الرصد',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}