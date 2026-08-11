import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'screens/terrain_home_screen.dart';

class TerrainApp extends StatelessWidget {
  const TerrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GEODEX Terrain',
      debugShowCheckedModeBanner: false,
      theme: SirexeTheme.dark,
      home: const TerrainHomeScreen(),
    );
  }
}

