import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'screens/dashboard_screen.dart';

class MinistereApp extends StatelessWidget {
  const MinistereApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GEODEX — Ministère des Mines',
      debugShowCheckedModeBanner: false,
      theme: SirexeTheme.dark,
      home: const DashboardScreen(),
    );
  }
}
