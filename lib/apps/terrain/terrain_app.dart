import 'package:flutter/material.dart';
import '../../models/terrain_modules.dart';
import 'screens/terrain_home_screen.dart';

class TerrainApp extends StatefulWidget {
  const TerrainApp({super.key});

  @override
  State<TerrainApp> createState() => _TerrainAppState();
}

class _TerrainAppState extends State<TerrainApp> {
  @override
  void initState() {
    super.initState();
    TerrainServices.init(
      pesee: PeseeServiceStub(),
      classificateur: ClassificateurStub(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const TerrainHomeScreen();
  }
}
