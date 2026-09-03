import 'package:flutter/material.dart';
import '../../../core/local/sync_queue.dart';
import '../../../models/pesee.dart';
import 'pesee_screen.dart';
import 'history_screen.dart';
import 'classification_screen.dart';

/// Conteneur de navigation commun aux modules utilisés sur le terrain.
/// Les écrans restent montés dans l'IndexedStack, afin de ne pas perdre une
/// pesée ou un filtre lorsque l'agent consulte un autre onglet.
class TerrainHomeScreen extends StatefulWidget {
  const TerrainHomeScreen({super.key});

  @override
  State<TerrainHomeScreen> createState() => _TerrainHomeScreenState();
}

class _TerrainHomeScreenState extends State<TerrainHomeScreen> {
  var _index = 0;

  void _navigateTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: IndexedStack(
        index: _index,
        children: [
          _TerrainDashboard(onNavigate: _navigateTo),
          const PeseeScreen(),
          const HistoryScreen(),
          const _TerrainToolsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _navigateTo,
        backgroundColor: const Color(0xFF161B22),
        indicatorColor: const Color(0xFF238636).withOpacity(0.22),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? const Color(0xFF58A6FF)
                : const Color(0xFF8B949E),
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.scale_outlined),
            selectedIcon: Icon(Icons.scale),
            label: 'Pesée',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historique',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_outlined),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'Outils',
          ),
        ],
      ),
    );
  }
}

class _TerrainDashboard extends StatelessWidget {
  const _TerrainDashboard({required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.scale_outlined, color: Color(0xFF238636), size: 20),
            SizedBox(width: 10),
            Text(
              'GEODEX Terrain',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  _NavCard(
                    title: 'Nouveau pesage',
                    subtitle: 'Enregistrer une pesée industrielle',
                    icon: Icons.scale_outlined,
                    color: const Color(0xFF238636),
                    onTap: () => onNavigate(1),
                  ),
                  const SizedBox(height: 12),
                  _NavCard(
                    title: 'Historique',
                    subtitle: 'Consulter les pesées enregistrées',
                    icon: Icons.history_outlined,
                    color: const Color(0xFF1F6FEB),
                    onTap: () => onNavigate(2),
                  ),
                  const SizedBox(height: 12),
                  _NavCard(
                    title: 'Chain of custody',
                    subtitle: 'Traçabilité complète du chargement',
                    icon: Icons.link_outlined,
                    color: const Color(0xFFD29922),
                    onTap: () => onNavigate(3),
                  ),
                  const SizedBox(height: 12),
                  _NavCard(
                    title: 'Certificats',
                    subtitle: 'Certificats numériques et QR code',
                    icon: Icons.qr_code_2_outlined,
                    color: const Color(0xFF8957E5),
                    onTap: () => onNavigate(3),
                  ),
                ],
              ),
            ),
          ),
          _SyncBanner(),
        ],
      ),
    );
  }
}

// ─── Navigation card ────────────────────────────────────────────────────────

class _NavCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF161B22),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF8B949E),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bandeau sync ────────────────────────────────────────────────────────────

class _SyncBanner extends StatefulWidget {
  @override
  State<_SyncBanner> createState() => _SyncBannerState();
}

class _SyncBannerState extends State<_SyncBanner> {
  int _pending = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final n = await SyncQueue.countPending();
    if (mounted) setState(() => _pending = n);
  }

  @override
  Widget build(BuildContext context) {
    final hasPending = _pending > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        border: Border(top: BorderSide(color: Color(0xFF30363D))),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasPending
                  ? Icons.cloud_upload_outlined
                  : Icons.cloud_done_outlined,
              size: 16,
              color: hasPending
                  ? const Color(0xFFD29922)
                  : const Color(0xFF238636),
            ),
            const SizedBox(width: 8),
            Text(
              hasPending
                  ? '$_pending pesée(s) en attente de synchronisation'
                  : 'Toutes les pesées sont synchronisées',
              style: TextStyle(
                color: hasPending
                    ? const Color(0xFFD29922)
                    : const Color(0xFF8B949E),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (hasPending) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  await SyncQueue.syncAll();
                  _refresh();
                },
                child: const Text(
                  'Sync maintenant',
                  style: TextStyle(
                    color: Color(0xFF1F6FEB),
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TerrainToolsScreen extends StatelessWidget {
  const _TerrainToolsScreen();

  Pesee _demoPesee() => Pesee(
        id: 'DEMO-CERT-001',
        camionId: 'CAM-TG-01',
        permisId: 'PM-CI-2024-001',
        nomSite: 'Concession Tongon',
        poidsNet: 48.2,
        poidsBrut: 66.7,
        tare: 18.5,
        timestamp: DateTime.now(),
        latitude: 9.167,
        longitude: -6.483,
        hash: 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2',
        statut: StatutPesee.valide,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: const Text(
          'Outils terrain',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => Navigator.of(context)
                .pushNamedAndRemoveUntil('/login', (route) => false),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Contrôle et traçabilité',
            style: TextStyle(
              color: Color(0xFF8B949E),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _NavCard(
            title: 'Classifier une roche',
            subtitle: 'Ajouter une photo et lancer l’analyse',
            icon: Icons.auto_fix_high_outlined,
            color: const Color(0xFF58A6FF),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ClassificationScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _NavCard(
            title: 'Chaîne de garde',
            subtitle: 'Auditer la traçabilité des chargements',
            icon: Icons.link_outlined,
            color: const Color(0xFFD29922),
            onTap: () => Navigator.of(context).pushNamed('/terrain/custody'),
          ),
          const SizedBox(height: 12),
          _NavCard(
            title: 'Certificat minéral',
            subtitle: 'Afficher le certificat et son QR code',
            icon: Icons.qr_code_2_outlined,
            color: const Color(0xFF8957E5),
            onTap: () => Navigator.of(context).pushNamed(
              '/terrain/certificats',
              arguments: _demoPesee(),
            ),
          ),
        ],
      ),
    );
  }
}
