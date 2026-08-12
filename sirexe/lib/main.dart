import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'core/theme.dart';
import 'core/local/sync_queue.dart';
import 'apps/auth/login_screen.dart';

void main() {
  runApp(const GeodesApp());

  Connectivity().onConnectivityChanged.listen((results) {
    if (results.any((r) => r != ConnectivityResult.none)) {
      SyncQueue.syncAll();
    }
  });
}

class GeodesApp extends StatelessWidget {
  const GeodesApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'GEODEX',
    debugShowCheckedModeBanner: false,
    theme: SirexeTheme.dark,
    home: const LoginScreen(),
  );
}
