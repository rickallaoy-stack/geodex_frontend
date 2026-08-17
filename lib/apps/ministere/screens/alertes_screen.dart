import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme.dart';
import '../../../core/services/pesee_service.dart';
import '../../../widgets/app_icon.dart';

class AlertesScreen extends StatefulWidget {
  const AlertesScreen({super.key});
  @override
  State<AlertesScreen> createState() => _AlertesScreenState();
}

class _AlertesScreenState extends State<AlertesScreen> {
  List<AlerteBackend> _alertes = [];
  bool _loading = true;
  bool _integre = true;
  String _integreMsg = '';
  bool _verifying = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final alertes = await PeseeService.fetchAlertes();
    setState(() {
      _alertes = alertes;
      _loading = false;
    });
  }

  Future<void> _verifierChaine() async {
    setState(() => _verifying = true);
    final res = await PeseeService.verifierIntegrite();
    setState(() {
      _integre    = res['integre'] as bool;
      _integreMsg = res['message'] as String;
      _verifying  = false;
    });
  }

  String _formatDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} '
    '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SirexeTheme.background,
      body: Row(children: [
        Container(
          width: 400,
          color: SirexeTheme.surface,
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(border: Border(
                bottom: BorderSide(color: SirexeTheme.border, width: 0.5))),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: SirexeTheme.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: SirexeTheme.danger.withOpacity(0.4))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(width: 14, height: 14,
                      child: SvgPicture.asset('assets/images/icon_alert_dark.svg', width: 14, height: 14, color: SirexeTheme.danger)),
                    const SizedBox(width: 6),
                    Text('${_alertes.length} alertes fraude',
                      style: const TextStyle(
                        color: SirexeTheme.danger,
                        fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _loading ? null : _load,
                  child: AppIcon.fromIconData(Icons.refresh,
                    color: SirexeTheme.textSecondary, size: 18)),
              ]),
            ),
            Expanded(
              child: _loading
                ? const Center(child: CircularProgressIndicator(
                    color: SirexeTheme.accentBlue, strokeWidth: 2))
                : _alertes.isEmpty
                  ? _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _alertes.length,
                      itemBuilder: (_, i) {
                        final a = _alertes[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: SirexeTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: SirexeTheme.danger.withOpacity(0.3),
                              width: 0.5)),
                          child: Row(children: [
                            Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                color: SirexeTheme.danger.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(7)),
                              child: AppIcon.fromIconData(Icons.location_off,
                                color: SirexeTheme.danger, size: 16)),
                            const SizedBox(width: 10),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.typeLabel, style: const TextStyle(
                                  color: SirexeTheme.textPrimary,
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(a.description, style: const TextStyle(
                                  color: SirexeTheme.textSecondary,
                                  fontSize: 11),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Row(children: [
                                  AppIcon.fromIconData(Icons.scale_outlined,
                                    size: 11,
                                    color: SirexeTheme.textSecondary),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${a.poidsMesureKg.toStringAsFixed(1)} kg',
                                    style: const TextStyle(
                                      color: SirexeTheme.textSecondary,
                                      fontSize: 10)),
                                  const SizedBox(width: 10),
                                  AppIcon.fromIconData(Icons.access_time,
                                    size: 11,
                                    color: SirexeTheme.textSecondary),
                                  const SizedBox(width: 3),
                                  Text(_formatDate(a.dateAlerte),
                                    style: const TextStyle(
                                      color: SirexeTheme.textSecondary,
                                      fontSize: 10)),
                                ]),
                              ],
                            )),
                          ]),
                        );
                      },
                    ),
            ),
          ]),
        ),

        Container(width: 0.5, color: SirexeTheme.border),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('REGISTRE CRYPTOGRAPHIQUE',
                  style: TextStyle(
                    color: SirexeTheme.textSecondary, fontSize: 11,
                    fontWeight: FontWeight.w500, letterSpacing: 1)),
                const SizedBox(height: 16),

                if (_integreMsg.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _integre
                        ? SirexeTheme.accent.withOpacity(0.07)
                        : SirexeTheme.danger.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _integre
                          ? SirexeTheme.accent.withOpacity(0.3)
                          : SirexeTheme.danger.withOpacity(0.3))),
                    child: Row(children: [
                      AppIcon.fromIconData(
                        _integre
                          ? Icons.verified_outlined
                          : Icons.gpp_bad_outlined,
                        color: _integre
                          ? SirexeTheme.accent : SirexeTheme.danger,
                        size: 22),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_integreMsg,
                        style: TextStyle(
                          color: _integre
                            ? SirexeTheme.accent : SirexeTheme.danger,
                          fontSize: 13))),
                    ]),
                  ),

                const SizedBox(height: 20),

                GestureDetector(
                  onTap: _verifying ? null : _verifierChaine,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 20),
                    decoration: BoxDecoration(
                      color: SirexeTheme.accentBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: SirexeTheme.accentBlue.withOpacity(0.4))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (_verifying)
                        const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: SirexeTheme.accentBlue))
                      else
                        AppIcon.fromIconData(Icons.link,
                          color: SirexeTheme.accentBlue, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        _verifying
                          ? 'Vérification en cours...'
                          : 'Vérifier l\'intégrité de la chaîne',
                        style: const TextStyle(
                          color: SirexeTheme.accentBlue,
                          fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SirexeTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SirexeTheme.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Comment ça fonctionne',
                        style: TextStyle(
                          color: SirexeTheme.textPrimary,
                          fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      ...[
                        ('1.', 'Chaque pesée génère un hash SHA-256 unique.'),
                        ('2.', 'Ce hash intègre le hash de la pesée précédente.'),
                        ('3.', 'Modifier une pesée brise toute la chaîne.'),
                        ('4.', 'Le serveur vérifie chaque lien en séquence.'),
                      ].map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 20,
                              child: Text(e.$1, style: const TextStyle(
                                color: SirexeTheme.accentBlue,
                                fontSize: 12, fontWeight: FontWeight.w600))),
                            Expanded(child: Text(e.$2, style: const TextStyle(
                              color: SirexeTheme.textSecondary,
                              fontSize: 12))),
                          ]),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      AppIcon.fromIconData(Icons.check_circle_outline,
        color: SirexeTheme.accent, size: 40),
      const SizedBox(height: 12),
      const Text('Aucune alerte fraude détectée',
        style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 14)),
    ]),
  );
}
