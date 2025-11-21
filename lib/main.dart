// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/todo_page.dart';
import 'services/storage_service.dart';
import 'providers/task_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final storage = StorageService();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider(storage)),
      ],
      child: MaterialApp(
        title: 'Todo Provider App',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const TodoPage(),
      ),
    );
  }
}
