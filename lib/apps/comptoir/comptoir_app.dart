import 'package:flutter/material.dart';
import 'screens/comptoir_scan_screen.dart';

class ComptoirApp extends StatelessWidget {
  const ComptoirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ComptoirScanScreen(),
    );
  }
}
