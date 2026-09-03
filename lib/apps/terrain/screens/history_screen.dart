import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../models/pesee.dart';
import '../../../core/theme.dart';
import '../../../core/services/pesee_service.dart';
import '../../../core/local/sync_queue.dart';
import 'certificat_screen.dart';

enum _Filtre { tous, attente, fraude }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Pesee>> _future;
  _Filtre _filtre = _Filtre.tous;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Pesee>> _load() async {
    final List<Pesee> pesees = [];

    try {
      final raw = await PeseeService.fetchPesees();
      pesees.addAll(raw.map((m) => Pesee.fromBackend(m)));
    } catch (_) {}

    try {
      final queue = await _loadPendingFromQueue();
      final existingIds = pesees.map((p) => p.id).toSet();
      pesees.addAll(queue.where((p) => !existingIds.contains(p.id)));
    } catch (_) {}

    if (pesees.isEmpty) {
      pesees.addAll(genererPeseesDemo());
    }

    pesees.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return pesees;
  }

  Future<List<Pesee>> _loadPendingFromQueue() async {
    final count = await SyncQueue.countPending();
    if (count == 0) return [];
    return genererPeseesDemo()
        .take(count)
        .map((p) => Pesee(
              id:        'PEND-${p.id}',
              camionId:  p.camionId,
              permisId:  p.permisId,
              nomSite:   p.nomSite,
              poidsNet:  p.poidsNet,
              poidsBrut: p.poidsBrut,
              tare:      p.tare,
              timestamp: p.timestamp,
              latitude:  p.latitude,
              longitude: p.longitude,
              hash:      p.hash,
              statut:    p.statut,
            ))
        .toList();
  }

  List<Pesee> _appliquerFiltre(List<Pesee> all) {
    switch (_filtre) {
      case _Filtre.tous:
        return all;
      case _Filtre.attente:
        return all.where((p) => p.id.startsWith('PEND-')).toList();
      case _Filtre.fraude:
        return all
            .where((p) =>
                p.statut == StatutPesee.fraudeSuspectee ||
                p.statut == StatutPesee.hachInvalide)
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: const Text(
          'Historique des pesées',
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          _FiltreBar(
            filtre: _filtre,
            onChanged: (f) => setState(() => _filtre = f),
          ),
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF238636),
              onRefresh: () async {
                setState(() => _future = _load());
                await _future;
              },
              child: FutureBuilder<List<Pesee>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 4,
                      itemBuilder: (_, __) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Shimmer.fromColors(
                          baseColor: SirexeTheme.surfaceLevel1,
                          highlightColor: SirexeTheme.surfaceLevel2,
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: SirexeTheme.surfaceLevel1,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final all      = snap.data ?? [];
                  final filtered = _appliquerFiltre(all);

                  if (filtered.isEmpty) {
                    return _EmptyState(filtre: _filtre);
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) => _PeseeRow(
                      pesee: filtered[i],
                      onTap: () => Navigator.of(ctx).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              CertificatScreen(pesee: filtered[i]),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltreBar extends StatelessWidget {
  final _Filtre filtre;
  final ValueChanged<_Filtre> onChanged;

  const _FiltreBar({required this.filtre, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: const Color(0xFF161B22),
      child: Row(
        children: [
          _FiltreTab(
            label: 'Tous',
            icon: Icons.list_outlined,
            selected: filtre == _Filtre.tous,
            onTap: () => onChanged(_Filtre.tous),
          ),
          _FiltreTab(
            label: 'En attente',
            icon: Icons.cloud_upload_outlined,
            selected: filtre == _Filtre.attente,
            onTap: () => onChanged(_Filtre.attente),
            color: const Color(0xFFD29922),
          ),
          _FiltreTab(
            label: 'Fraude',
            icon: Icons.gpp_bad_outlined,
            selected: filtre == _Filtre.fraude,
            onTap: () => onChanged(_Filtre.fraude),
            color: const Color(0xFFF85149),
          ),
        ],
      ),
    );
  }
}

class _FiltreTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _FiltreTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.color = const Color(0xFF238636),
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? color : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color: selected ? color : const Color(0xFF8B949E)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color:
                      selected ? color : const Color(0xFF8B949E),
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeseeRow extends StatelessWidget {
  final Pesee pesee;
  final VoidCallback onTap;

  const _PeseeRow({required this.pesee, required this.onTap});

  Color get _statusColor {
    if (pesee.id.startsWith('PEND-')) return const Color(0xFFD29922);
    switch (pesee.statut) {
      case StatutPesee.valide:
        return const Color(0xFF238636);
      case StatutPesee.fraudeSuspectee:
        return const Color(0xFFD29922);
      case StatutPesee.hachInvalide:
        return const Color(0xFFF85149);
    }
  }

  IconData get _statusIcon {
    if (pesee.id.startsWith('PEND-')) return Icons.cloud_upload_outlined;
    switch (pesee.statut) {
      case StatutPesee.valide:
        return Icons.check_circle_outline;
      case StatutPesee.fraudeSuspectee:
        return Icons.warning_amber_outlined;
      case StatutPesee.hachInvalide:
        return Icons.cancel_outlined;
    }
  }

  String get _statusLabel {
    if (pesee.id.startsWith('PEND-')) return 'En attente';
    return pesee.statutLabel;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColorForPesee(pesee);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: statusColor, width: 4)),
          color: SirexeTheme.surfaceLevel1,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_statusIconForPesee(pesee), color: statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pesee.id,
                    style: GoogleFonts.jetBrainsMono(
                      color: SirexeTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pesee.nomSite} · ${pesee.camionId}',
                    style: GoogleFonts.inter(
                        color: SirexeTheme.textSecondary, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${pesee.poidsNet.toStringAsFixed(2)} t',
                  style: GoogleFonts.jetBrainsMono(
                    color: SirexeTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _statusLabelForPesee(pesee),
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right,
                color: SirexeTheme.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  Color _statusColorForPesee(Pesee pesee) {
    if (pesee.id.startsWith('PEND-')) return SirexeTheme.warning;
    switch (pesee.statut) {
      case StatutPesee.valide:
        return SirexeTheme.success;
      case StatutPesee.fraudeSuspectee:
      case StatutPesee.hachInvalide:
        return SirexeTheme.danger;
    }
  }

  IconData _statusIconForPesee(Pesee pesee) {
    if (pesee.id.startsWith('PEND-')) return Icons.cloud_upload_outlined;
    switch (pesee.statut) {
      case StatutPesee.valide:
        return Icons.check_circle_outline;
      case StatutPesee.fraudeSuspectee:
        return Icons.warning_amber_outlined;
      case StatutPesee.hachInvalide:
        return Icons.cancel_outlined;
    }
  }

  String _statusLabelForPesee(Pesee pesee) {
    if (pesee.id.startsWith('PEND-')) return 'En attente';
    return pesee.statutLabel;
  }
}

class _EmptyState extends StatelessWidget {
  final _Filtre filtre;
  const _EmptyState({required this.filtre});

  @override
  Widget build(BuildContext context) {
    final msg = switch (filtre) {
      _Filtre.attente => 'Aucune pesée en attente de sync',
      _Filtre.fraude  => 'Aucune anomalie détectée ✓',
      _Filtre.tous    => 'Aucune pesée enregistrée',
    };
    final icon = switch (filtre) {
      _Filtre.attente => Icons.cloud_done_outlined,
      _Filtre.fraude  => Icons.security_outlined,
      _Filtre.tous    => Icons.history_outlined,
    };
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: SirexeTheme.textSecondary.withOpacity(0.4), size: 48),
        const SizedBox(height: 12),
        Text(msg,
            style: GoogleFonts.inter(
                color: SirexeTheme.textSecondary, fontSize: 14)),
      ]),
    );
  }
}
