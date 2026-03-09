import 'package:flutter/material.dart';
import 'screens/lists_screen.dart';

void main() {
  runApp(const ListRandomizerApp());
}

class ListRandomizerApp extends StatelessWidget {
  const ListRandomizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chooser',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        cardColor: const Color(0xFF1A1A2E),
        fontFamily: 'SF Pro Display',
      ),
      home: ListsScreen(),
    );
  }
}