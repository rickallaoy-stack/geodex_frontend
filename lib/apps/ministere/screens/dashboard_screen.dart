import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme.dart';
import '../../../widgets/app_icon.dart';
import '../../../models/alerte_model.dart';
import '../../../core/services/alerte_service.dart';
import '../../../apps/borne/screens/borne_kiosk_screen.dart';
import '../widgets/stats_topbar.dart';
import '../widgets/borne_activite_widget.dart';
import 'verification_chain_screen.dart';
import 'alertes_screen.dart';
import 'stats_screen.dart';
import 'investigation_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _tabScrollController = ScrollController();

  int _tabIndex = 0;

  final AlerteService _alerteService = AlerteService();
  StreamSubscription<List<AlerteModel>>? _alerteSubscription;

  List<AlerteModel> _alertes = [];

  @override
  void initState() {
    super.initState();
    _startAlertesWatch();
  }

  @override
  void dispose() {
    _tabScrollController.dispose();
    _alerteSubscription?.cancel();
    _alerteService.dispose();
    super.dispose();
  }

  void _startAlertesWatch() {
    _alerteSubscription = _alerteService.watch().listen(
      (alertes) {
        if (!mounted) return;
        setState(() => _alertes = alertes);
      },
      onError: (e) {
        if (!mounted) return;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SirexeTheme.surfaceLevel0,
      appBar: StatsTopbar(
        alerteCount: _alertes.length,
        onAlerteTap: () => setState(() => _tabIndex = 2),
      ),
      body: Column(children: [
        Container(
          color: SirexeTheme.surfaceLevel1,
          child: Row(children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _Tab(label: 'Carte', icon: Icons.map_outlined, active: _tabIndex == 0, onTap: () => setState(() => _tabIndex = 0)),
                  _Tab(label: 'Kiosk', icon: Icons.qr_code_scanner_outlined, active: _tabIndex == 1, onTap: () => setState(() => _tabIndex = 1)),
                  _Tab(label: 'Alertes', icon: Icons.warning_amber_rounded, active: _tabIndex == 2, badge: _alertes.length, onTap: () => setState(() => _tabIndex = 2)),
                  _Tab(label: 'Stats', icon: Icons.bar_chart_rounded, active: _tabIndex == 3, onTap: () => setState(() => _tabIndex = 3)),
                  _Tab(label: 'Chaîne', icon: Icons.link_rounded, active: _tabIndex == 4, onTap: () => setState(() => _tabIndex = 4)),
                  _Tab(label: 'Bornes', icon: Icons.qr_code_scanner, active: _tabIndex == 5, onTap: () => setState(() => _tabIndex = 5)),
                  _Tab(label: 'Investigation', icon: Icons.search_outlined, active: _tabIndex == 6, onTap: () => setState(() => _tabIndex = 6)),
                ]),
              ),
            ),
            Container(height: 40, width: 0.5, color: SirexeTheme.border),
          ]),
        ),
        Container(height: 0.5, color: SirexeTheme.border),
        Expanded(child: switch(_tabIndex) {
          0 => _buildCarteTab(),
          1 => const BorneKioskScreen(),
          2 => const AlertesScreen(),
          3 => const StatsScreen(),
          4 => const VerificationChainScreen(),
          5 => const BorneActiviteWidget(),
          6 => const InvestigationScreen(),
          _ => _buildCarteTab(),
        }),
      ]),
    );
  }

  Widget _buildCarteTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Row(children: [
          _kpiCard("OR CERTIFIÉ 24H", "18.450 kg", SirexeTheme.success, Icons.diamond),
          const SizedBox(width: 16),
          _kpiCard("PASSPORTS ÉMIS", "124", Colors.white70, Icons.description),
          const SizedBox(width: 16),
          _kpiCard("TENTATIVES FRAUDE", "3", SirexeTheme.danger, Icons.gpp_bad),
          const SizedBox(width: 16),
          _kpiCard("BORNES EN LIGNE", "4/5", SirexeTheme.warning, Icons.dns),
        ]),
        const SizedBox(height: 24),
        Expanded(child: Row(children: [
          Expanded(flex: 2, child: _buildLiveTerminalPasseports()),
          const SizedBox(width: 24),
          Expanded(child: _buildBouclierIntegrite()),
        ])),
      ]),
    );
  }

  Widget _kpiCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: SirexeTheme.surfaceLevel1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 12, spreadRadius: 1)],
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ])),
        ]),
      ),
    );
  }

  Widget _buildLiveTerminalPasseports() {
    final now = DateTime.now();
    final logs = <_LogEntry>[
      _LogEntry(now.subtract(const Duration(seconds: 12)), 'Passeport #PX-8834 émis', SirexeTheme.success),
      _LogEntry(now.subtract(const Duration(seconds: 28)), 'Scan QR Comptoir 03 validé', SirexeTheme.success),
      _LogEntry(now.subtract(const Duration(seconds: 45)), 'Alerte hors-zone Borne 02', SirexeTheme.danger),
      _LogEntry(now.subtract(const Duration(minutes: 1)), 'Passeport #PX-8833 émis', SirexeTheme.success),
      _LogEntry(now.subtract(const Duration(minutes: 1, seconds: 20)), 'Vérification chaîne intégrée', Colors.white70),
      _LogEntry(now.subtract(const Duration(minutes: 2)), 'Passeport #PX-8832 émis', SirexeTheme.success),
      _LogEntry(now.subtract(const Duration(minutes: 3)), 'Quota dépassé opérateur KONÉ', SirexeTheme.warning),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SirexeTheme.surfaceLevel1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SirexeTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.terminal_rounded, color: SirexeTheme.accentBlue, size: 18),
          const SizedBox(width: 8),
          Text('FLUX PASSEPORTS EN DIRECT', style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const Spacer(),
          Container(width: 8, height: 8, decoration: BoxDecoration(color: SirexeTheme.success, shape: BoxShape.circle)),
        ]),
        const SizedBox(height: 16),
        Expanded(child: ListView.builder(
          itemCount: logs.length,
          itemBuilder: (_, i) {
            final log = logs[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Text('${log.time.hour.toString().padLeft(2, '0')}:${log.time.minute.toString().padLeft(2, '0')}:${log.time.second.toString().padLeft(2, '0')}', style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 11, fontFamily: 'monospace')),
                const SizedBox(width: 12),
                Icon(Icons.circle, size: 6, color: log.color),
                const SizedBox(width: 10),
                Expanded(child: Text(log.message, style: TextStyle(color: SirexeTheme.textPrimary, fontSize: 13))),
              ]),
            );
          },
        )),
      ]),
    );
  }

  Widget _buildBouclierIntegrite() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SirexeTheme.surfaceLevel1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SirexeTheme.border),
      ),
      child: Column(children: [
        Icon(Icons.shield_outlined, size: 64, color: SirexeTheme.success.withValues(alpha: 0.3)),
        const SizedBox(height: 16),
        Text('INTÉGRITÉ BLOCKCHAIN', style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Text('100%', style: TextStyle(color: SirexeTheme.success, fontSize: 42, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Chaîne SHA-256 valide', style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 16),
        LinearProgressIndicator(value: 1.0, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation(SirexeTheme.success), minHeight: 6, borderRadius: BorderRadius.circular(3)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _integrityStat('Blocs', '1.247', SirexeTheme.success),
          _integrityStat('Dernier hash', 'a3f7...d92e', Colors.white70),
        ]),
      ]),
    );
  }

  Widget _integrityStat(String label, String value, Color color) {
    return Column(children: [
      Text(label, style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 10)),
      Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
    ]);
  }
}

class _LogEntry {
  final DateTime time;
  final String message;
  final Color color;
  const _LogEntry(this.time, this.message, this.color);
}

class _AlerteToast extends StatefulWidget {
  const _AlerteToast({required this.alerte, required this.onTap, required this.onDismiss});
  final AlerteModel alerte;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  @override
  State<_AlerteToast> createState() => _AlerteToastState();
}

class _AlerteToastState extends State<_AlerteToast> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SirexeTheme.surfaceLevel1,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SirexeTheme.danger, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: SirexeTheme.danger.withValues(alpha: 0.25),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: SirexeTheme.danger.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(width: 36, height: 36,
              child: SvgPicture.asset('assets/images/icon_alert_dark.svg', width: 20, height: 20, color: SirexeTheme.danger)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ALERTE FRAUDE',
                    style: TextStyle(
                        color: SirexeTheme.danger,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(widget.alerte.libelleType,
                    style: const TextStyle(
                            color: SirexeTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                Text(
                  '${widget.alerte.tempsRelatif} · ${(widget.alerte.poidsMesureKg / 1000).toStringAsFixed(2)} t',
                  style: const TextStyle(
                      color: SirexeTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: AppIcon.fromIconData(Icons.close,
                color: SirexeTheme.textSecondary, size: 16),
            onPressed: widget.onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ]),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -1, duration: 400.ms);
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final int badge;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.icon, required this.active, required this.onTap, this.badge = 0});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: active ? SirexeTheme.accentBlue : Colors.transparent, width: 2))), child: Row(mainAxisSize: MainAxisSize.min, children: [
    AppIcon.fromIconData(icon, size: 15, color: active ? SirexeTheme.accentBlue : SirexeTheme.textSecondary),
    const SizedBox(width: 7),
    Text(label, style: TextStyle(color: active ? SirexeTheme.accentBlue : SirexeTheme.textSecondary, fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
    if (badge > 0) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: SirexeTheme.danger, borderRadius: BorderRadius.circular(10)), child: Text(badge > 99 ? '99+' : '$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)))],
  ])));
}
