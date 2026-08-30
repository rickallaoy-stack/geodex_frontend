import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'core/theme.dart';
import 'core/local/sync_queue.dart';
import 'apps/auth/login_screen.dart';
import 'apps/borne/borne_app.dart';
import 'apps/ministere/ministere_app.dart';
import 'apps/terrain/terrain_app.dart';
import 'apps/terrain/screens/custody_screen.dart';
import 'apps/terrain/screens/certificat_screen.dart';
import 'models/pesee.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GEODEX',
      debugShowCheckedModeBanner: false,
      theme: SirexeTheme.dark,
      initialRoute: '/borne',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/ministere': (_) => const MinistereApp(),
        '/terrain': (_) => const TerrainApp(),
        '/borne': (_) => const BorneApp(),
        '/terrain/custody': (_) => const CustodyScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/terrain/certificats') {
          final pesee = settings.arguments as Pesee;
          return MaterialPageRoute(
            builder: (_) => CertificatScreen(pesee: pesee),
          );
        }
        return null;
      },
    );
  }
}
