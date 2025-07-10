import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './services/theme_data.dart';
import './screens/home_screen.dart';
void main() {
  runApp(
    ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Walmart Inventory Management System',
      debugShowCheckedModeBanner: false,
      theme: customTheme,
      home: MainScaffold(),
    );
  }
}
