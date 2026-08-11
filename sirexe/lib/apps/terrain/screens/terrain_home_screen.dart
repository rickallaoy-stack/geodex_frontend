import 'package:flutter/material.dart';
import 'pesee_screen.dart';
import 'classification_screen.dart';
import 'history_screen.dart';
import '../../../core/theme.dart';

class TerrainHomeScreen extends StatefulWidget {
  const TerrainHomeScreen({super.key});

  @override
  State<TerrainHomeScreen> createState() => _TerrainHomeScreenState();
}

class _TerrainHomeScreenState extends State<TerrainHomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SirexeTheme.background,
      body: IndexedStack(
        index: _index,
        children: const [
          PeseeScreen(),
          ClassificationScreen(),
          HistoryScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: SirexeTheme.surface,
        selectedItemColor: SirexeTheme.accent,
        unselectedItemColor: SirexeTheme.textSecondary,
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.scale_outlined),
            activeIcon: Icon(Icons.scale_rounded),
            label: 'Pesée',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt_rounded),
            label: 'Classer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history_rounded),
            label: 'Historique',
          ),
        ],
      ),
    );
  }
}
