import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/pesee.dart';
import '../../../core/theme.dart';
import '../../../core/services/pesee_service.dart';
import '../../../core/services/verification_service.dart';
import 'certificat_screen.dart';

class CustodyScreen extends StatefulWidget {
  const CustodyScreen({super.key});

  @override
  State<CustodyScreen> createState() => _CustodyScreenState();
}

class _CustodyScreenState extends State<CustodyScreen> {
  late Future<List<Pesee>> _future;
  bool _auditing = false;

  @override
  void initState() {
    super.initState();
    _future = _loadPesees();
  }

  Future<List<Pesee>> _loadPesees() async {
    try {
      final raw = await PeseeService.fetchPesees();
      return raw.map((m) => Pesee.fromBackend(m)).toList();
    } catch (_) {
      return genererPeseesDemo();
    }
  }

  Future<void> _auditerChaine() async {
    setState(() => _auditing = true);
    try {
      final svc = VerificationService();
      final res = await svc.verifierChaine();
      final integre = res['integre'] as bool? ?? false;
      final msg = res['message']?.toString() ?? '';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  integre ? Icons.verified_outlined : Icons.gpp_bad_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    integre
                        ? 'Chaîne intègre — aucune fraude détectée ✓'
                        : 'ALERTE : $msg',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor:
                integre ? const Color(0xFF238636) : const Color(0xFFF85149),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur audit : $e'),
            backgroundColor: const Color(0xFFD29922),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _auditing = false);
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
          'Chain of custody',
          style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _auditing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF238636)),
                  )
                : IconButton(
                    tooltip: 'Auditer la chaîne',
                    onPressed: _auditerChaine,
                    icon: const Icon(Icons.verified_outlined,
                        color: Color(0xFF238636), size: 22),
                  ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF238636),
        onRefresh: () async {
          setState(() => _future = _loadPesees());
          await _future;
        },
        child: FutureBuilder<List<Pesee>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF238636)),
              );
            }
            if (snap.hasError) {
              return Center(
                child: Text(
                  'Erreur : ${snap.error}',
                  style: const TextStyle(color: Color(0xFFF85149)),
                ),
              );
            }
            final pesees = snap.data ?? [];
            if (pesees.isEmpty) {
              return const Center(
                child: Text(
                  'Aucune pesée enregistrée',
                  style: TextStyle(color: Color(0xFF8B949E)),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: pesees.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _CustodyCard(
                pesee: pesees[i],
                onTap: () => Navigator.of(ctx).push(
                  MaterialPageRoute(
                    builder: (_) => CertificatScreen(pesee: pesees[i]),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CustodyCard extends StatelessWidget {
  final Pesee pesee;
  final VoidCallback onTap;

  const _CustodyCard({required this.pesee, required this.onTap});

  Color _custodyStatusColor(StatutPesee statut) {
    switch (statut) {
      case StatutPesee.valide:
        return SirexeTheme.success;
      case StatutPesee.fraudeSuspectee:
      case StatutPesee.hachInvalide:
        return SirexeTheme.danger;
    }
  }

  String _shortTs(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/'
    '${dt.month.toString().padLeft(2, '0')}  '
    '${dt.hour.toString().padLeft(2, '0')}:'
    '${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final hashOk = pesee.hashValide;
    final statusColor = _custodyStatusColor(pesee.statut);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: statusColor, width: 4)),
          color: SirexeTheme.surfaceLevel1,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hashOk ? Icons.lock_outlined : Icons.lock_open_outlined,
                  color: hashOk
                      ? SirexeTheme.success
                      : SirexeTheme.danger,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pesee.id,
                    style: GoogleFonts.jetBrainsMono(
                      color: SirexeTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    pesee.statutLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _CustodyTimeline(
              steps: [
                _Step(
                    label: 'Extraction',
                    sub: pesee.nomSite,
                    done: true),
                _Step(
                    label: 'Transport',
                    sub: pesee.camionId,
                    done: true),
                _Step(
                    label: 'Réception',
                    sub: 'Client final',
                    done: pesee.statut == StatutPesee.valide),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.monitor_weight_outlined,
                    color: Color(0xFF8B949E), size: 14),
                const SizedBox(width: 6),
                Text(
                  '${pesee.poidsNet.toStringAsFixed(2)} t net',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time_outlined,
                    color: Color(0xFF8B949E), size: 14),
                const SizedBox(width: 6),
                Text(
                  _shortTs(pesee.timestamp),
                  style: const TextStyle(
                      color: Color(0xFF8B949E), fontSize: 12),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right,
                    color: Color(0xFF8B949E), size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

class _Step {
  final String label;
  final String sub;
  final bool done;
  const _Step({required this.label, required this.sub, required this.done});
}

class _CustodyTimeline extends StatelessWidget {
  final List<_Step> steps;
  const _CustodyTimeline({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          Expanded(child: _StepDot(step: steps[i])),
          if (i < steps.length - 1)
            Expanded(
              child: Container(
                height: 2,
                color: steps[i].done && steps[i + 1].done
                    ? const Color(0xFF238636)
                    : const Color(0xFF30363D),
              ),
            ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final _Step step;
  const _StepDot({required this.step});

  @override
  Widget build(BuildContext context) {
    final color =
        step.done ? const Color(0xFF238636) : const Color(0xFF30363D);
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: step.done
              ? const Icon(Icons.check, color: Color(0xFF238636), size: 14)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          step.label,
          style: TextStyle(
            color: step.done ? Colors.white : const Color(0xFF8B949E),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          step.sub,
          style: const TextStyle(color: Color(0xFF8B949E), fontSize: 9),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
