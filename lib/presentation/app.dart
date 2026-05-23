import 'package:flutter/material.dart';
import 'screens/loading_screen.dart';
import 'theme/app_theme.dart';

class HolyQuranApp extends StatelessWidget {
  const HolyQuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Holy Quran',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LoadingScreen(),
    );
  }
}
