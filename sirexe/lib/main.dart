import 'package:flutter/material.dart';
import 'core/config/app_dependencies.dart';
import 'core/theme.dart';
import 'apps/auth/login_screen.dart';

void main() {
  AppDependencies.init();
  runApp(const GeodesApp());
}

class GeodesApp extends StatelessWidget {
  const GeodesApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GEODEX',
      debugShowCheckedModeBanner: false,
      theme: SirexeTheme.dark,
      home: const LoginScreen(),
    );
  }
}
