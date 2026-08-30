import 'package:flutter/material.dart';
import 'screens/borne_kiosk_screen.dart';

class BorneApp extends StatelessWidget {
  const BorneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: BorneKioskScreen(),
    );
  }
}
