import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import '../../../core/theme.dart';
import '../../../widgets/app_icon.dart';
import '../../../models/pesee.dart';
import '../../../models/permis_minier.dart';
import '../../../core/services/pesee_service.dart';

class PeseesScreen extends StatefulWidget {
  const PeseesScreen({super.key});
  @override
  State<PeseesScreen> createState() => _PeseesScreenState();
}

class _PeseesScreenState extends State<PeseesScreen> {
  late List<Pesee> _pesees;
  Pesee? _selected;
  bool _simulating = false;

  @override
  void initState() {
    super.initState();
    _pesees = genererPeseesDemo();
  }

  void _simulerPesee() async {
    setState(() => _simulating = true);
    await Future.delayed(const Duration(milliseconds: 1200));

    final rng    = Random();
    final permis = permisDemo[rng.nextInt(permisDemo.length)];
    final now    = DateTime.now();
    final poidsNet = 40.0 + rng.nextDouble() * 20;
    final tare   = 17.5 + rng.nextDouble() * 2;
    final camionNum = rng.nextInt(20).toString().padLeft(2, '0');
    final prefix = permis.nom.split(' ').last.substring(0, 2).toUpperCase();

    final latitude = permis.centre.latitude + (rng.nextDouble() - 0.5) * 0.001;
    final longitude = permis.centre.longitude + (rng.nextDouble() - 0.5) * 0.001;

    final signature = 'SECURE_HARDWARE_SIGN_METER_${rng.nextInt(5) + 1}';

    try {
      final res = await PeseeService.envoyerPesee(
        capteurId: 'SENSOR-${permis.id.split('-').last}',
        poidsMesureKg: poidsNet + tare,
        latitude: latitude,
        longitude: longitude,
        signatureEquipement: signature,
      );

      if (res['success'] == true) {
        final hash = res['hash'] ?? Pesee.genererHash(
          permisId: permis.id,
          camionId: 'CAM-$prefix-$camionNum',
          poidsNet: poidsNet,
          timestamp: now,
          latitude: latitude,
          longitude: longitude,
        );

        final nouvelle = Pesee(
          id:        res['releve_id'] ?? 'PSE-${(_pesees.length + 1).toString().padLeft(3, '0')}',
          camionId:  'CAM-$prefix-$camionNum',
          permisId:  permis.id,
          nomSite:   permis.nom,
          poidsNet:  double.parse(poidsNet.toStringAsFixed(1)),
          poidsBrut: double.parse((poidsNet + tare).toStringAsFixed(1)),
          tare:      double.parse(tare.toStringAsFixed(1)),
          timestamp: now,
          latitude:  latitude,
          longitude: longitude,
          hash:      hash,
          statut:    permis.statut == StatutPermis.illegal
            ? StatutPesee.fraudeSuspectee
            : StatutPesee.valide,
        );

        setState(() {
          _pesees.insert(0, nouvelle);
          _selected   = nouvelle;
          _simulating = false;
        });
        return;
      }
    } catch (_) {}

    final hash = Pesee.genererHash(
      permisId:  permis.id,
      camionId:  'CAM-$prefix-$camionNum',
      poidsNet:  poidsNet,
      timestamp: now,
      latitude:  permis.centre.latitude,
      longitude: permis.centre.longitude,
    );

    final nouvelle = Pesee(
      id:        'PSE-${(_pesees.length + 1).toString().padLeft(3, '0')}',
      camionId:  'CAM-$prefix-$camionNum',
      permisId:  permis.id,
      nomSite:   permis.nom,
      poidsNet:  double.parse(poidsNet.toStringAsFixed(1)),
      poidsBrut: double.parse((poidsNet + tare).toStringAsFixed(1)),
      tare:      double.parse(tare.toStringAsFixed(1)),
      timestamp: now,
      latitude:  permis.centre.latitude,
      longitude: permis.centre.longitude,
      hash:      hash,
      statut:    permis.statut == StatutPermis.illegal
        ? StatutPesee.fraudeSuspectee
        : StatutPesee.valide,
    );

    setState(() {
      _pesees.insert(0, nouvelle);
      _selected   = nouvelle;
      _simulating = false;
    });
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final fraudes = _pesees.where(
      (p) => p.statut != StatutPesee.valide).length;
    final tonnage = _pesees
      .where((p) => p.statut == StatutPesee.valide)
      .fold(0.0, (s, p) => s + p.poidsNet);

    return Scaffold(
      backgroundColor: SirexeTheme.background,
      body: Row(children: [
        Container(
          width: 360,
          color: SirexeTheme.surface,
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(
                  color: SirexeTheme.border, width: 0.5))),
              child: Column(children: [
                Row(children: [
                  _StatCard(label: 'Pesées',
                    value: '${_pesees.length}',
                    color: SirexeTheme.accentBlue),
                  const SizedBox(width: 8),
                  _StatCard(label: 'Tonnage validé',
                    value: '${tonnage.toStringAsFixed(0)} t',
                    color: SirexeTheme.accent),
                  const SizedBox(width: 8),
                  _StatCard(label: 'Fraudes',
                    value: '$fraudes',
                    color: fraudes > 0
                      ? SirexeTheme.danger : SirexeTheme.textSecondary),
                ]),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _simulating ? null : _simulerPesee,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _simulating
                        ? SirexeTheme.surfaceElevated
                        : SirexeTheme.accentBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _simulating
                          ? SirexeTheme.border
                          : SirexeTheme.accentBlue.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_simulating)
                          const SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: SirexeTheme.accentBlue))
                        else
                          AppIcon.fromIconData(Icons.sensors,
                            color: SirexeTheme.accentBlue, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _simulating
                            ? 'Pesée en cours...'
                            : 'Simuler une pesée',
                          style: TextStyle(
                            color: _simulating
                              ? SirexeTheme.textSecondary
                              : SirexeTheme.accentBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _pesees.length,
                itemBuilder: (_, i) {
                  final p   = _pesees[i];
                  final sel = _selected?.id == p.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: sel
                          ? SirexeTheme.accentBlue.withOpacity(0.08)
                          : p.statut != StatutPesee.valide
                            ? SirexeTheme.danger.withOpacity(0.04)
                            : SirexeTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: sel
                            ? SirexeTheme.accentBlue
                            : p.statut != StatutPesee.valide
                              ? SirexeTheme.danger.withOpacity(0.35)
                              : SirexeTheme.border,
                          width: sel ? 1.5 : 0.5),
                      ),
                      child: Row(children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: p.couleur.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6)),
                          child: p.statut == StatutPesee.valide
                            ? AppIcon.fromIconData(Icons.check_circle_outline, color: p.couleur, size: 16)
                            : SizedBox(width: 16, height: 16, child: SvgPicture.asset('assets/images/icon_alert_dark.svg', width: 16, height: 16, color: p.couleur))),
                        const SizedBox(width: 10),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(p.camionId, style: const TextStyle(
                                color: SirexeTheme.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: p.couleur.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4)),
                                child: Text(p.statutLabel, style: TextStyle(
                                  color: p.couleur, fontSize: 9,
                                  fontWeight: FontWeight.w600))),
                            ]),
                            const SizedBox(height: 2),
                            Text(p.nomSite, style: const TextStyle(
                              color: SirexeTheme.textSecondary,
                              fontSize: 11),
                              overflow: TextOverflow.ellipsis),
                          ],
                        )),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${p.poidsNet} t', style: const TextStyle(
                              color: SirexeTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                            Text(_formatTime(p.timestamp),
                              style: const TextStyle(
                                color: SirexeTheme.textSecondary,
                                fontSize: 10)),
                          ],
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
        Container(width: 0.5, color: SirexeTheme.border),
        Expanded(
          child: _selected == null
            ? _EmptyState()
            : _PeseeDetail(
                pesee: _selected!,
                onClose: () => setState(() => _selected = null),
              ),
        ),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard({required this.label,
    required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: SirexeTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: SirexeTheme.border)),
      child: Column(children: [
        Text(value, style: TextStyle(
          color: color, fontSize: 18, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(
          color: SirexeTheme.textSecondary, fontSize: 10)),
      ]),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      AppIcon.fromIconData(Icons.scale_outlined,
        color: SirexeTheme.textSecondary, size: 40),
      const SizedBox(height: 12),
      const Text('Sélectionner une pesée',
        style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 14)),
    ]),
  );
}

class _PeseeDetail extends StatelessWidget {
  final Pesee pesee;
  final VoidCallback onClose;
  const _PeseeDetail({required this.pesee, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final hashOk = pesee.hashValide;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: pesee.couleur.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: pesee.couleur.withOpacity(0.4))),
            child: Text(pesee.statutLabel, style: TextStyle(
              color: pesee.couleur, fontSize: 12,
              fontWeight: FontWeight.w700))),
          const SizedBox(width: 10),
          Text(pesee.id, style: const TextStyle(
            color: SirexeTheme.textPrimary,
            fontSize: 16, fontWeight: FontWeight.w700)),
          const Spacer(),
          IconButton(
            icon: AppIcon.fromIconData(Icons.close,
              color: SirexeTheme.textSecondary, size: 18),
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints()),
        ]),
        const SizedBox(height: 20),
        _Section(title: 'DONNÉES DE PESÉE', children: [
          _Row('Camion',    pesee.camionId),
          _Row('Site',      pesee.nomSite),
          _Row('Permis',    pesee.permisId),
          _Row('Poids net', '${pesee.poidsNet} tonnes'),
          _Row('Poids brut','${pesee.poidsBrut} tonnes'),
          _Row('Tare',      '${pesee.tare} tonnes'),
          _Row('Horodatage',
            '${pesee.timestamp.day}/${pesee.timestamp.month}/${pesee.timestamp.year} '
            '${pesee.timestamp.hour.toString().padLeft(2,'0')}:'
            '${pesee.timestamp.minute.toString().padLeft(2,'0')}'),
          _Row('GPS',
            '${pesee.latitude.toStringAsFixed(4)}°N, '
            '${pesee.longitude.toStringAsFixed(4)}°W'),
        ]),
        const SizedBox(height: 16),
        _Section(title: 'REGISTRE CRYPTOGRAPHIQUE', children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: hashOk
                ? SirexeTheme.accent.withOpacity(0.06)
                : SirexeTheme.danger.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hashOk
                  ? SirexeTheme.accent.withOpacity(0.3)
                  : SirexeTheme.danger.withOpacity(0.3))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(children: [
                AppIcon.fromIconData(
                  hashOk
                    ? Icons.lock_outline
                    : Icons.lock_open_outlined,
                  color: hashOk
                    ? SirexeTheme.accent : SirexeTheme.danger,
                  size: 16),
                const SizedBox(width: 8),
                Text(
                  hashOk
                    ? 'Hash valide — données intègres'
                    : 'Hash invalide — données falsifiées',
                  style: TextStyle(
                    color: hashOk
                      ? SirexeTheme.accent : SirexeTheme.danger,
                    fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Clipboard.setData(
                  ClipboardData(text: pesee.hash)),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: SirexeTheme.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: SirexeTheme.border)),
                  child: Row(children: [
                    Expanded(child: Text(pesee.hash,
                      style: const TextStyle(
                        color: SirexeTheme.textPrimary,
                        fontSize: 11,
                        fontFamily: 'monospace',
                        letterSpacing: 0.5))),
                    const SizedBox(width: 8),
                    AppIcon.fromIconData(Icons.copy,
                      color: SirexeTheme.textSecondary, size: 14),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'SHA-256(${pesee.permisId}|${pesee.camionId}|'
                '${pesee.poidsNet}|timestamp|GPS)',
                style: const TextStyle(
                  color: SirexeTheme.textSecondary,
                  fontSize: 10, fontFamily: 'monospace')),
            ]),
          ),
          if (!hashOk) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SirexeTheme.danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: SirexeTheme.danger.withOpacity(0.4))),
              child: Row(children: [
                  SizedBox(width: 14, height: 14, child: SvgPicture.asset('assets/images/icon_alert_dark.svg', width: 14, height: 14, color: SirexeTheme.danger)),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'Les données de cette pesée ont été modifiées '
                  'après signature. Transmission automatique aux '
                  'autorités minières.',
                  style: TextStyle(
                    color: SirexeTheme.danger, fontSize: 11))),
              ]),
            ),
          ],
        ]),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(
        color: SirexeTheme.textSecondary, fontSize: 10,
        fontWeight: FontWeight.w500, letterSpacing: 1)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SirexeTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: SirexeTheme.border)),
        child: Column(children: children)),
    ],
  );
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      SizedBox(width: 110,
        child: Text(label, style: const TextStyle(
          color: SirexeTheme.textSecondary, fontSize: 12))),
      Expanded(child: Text(value, style: const TextStyle(
        color: SirexeTheme.textPrimary, fontSize: 12))),
    ]),
  );
}
