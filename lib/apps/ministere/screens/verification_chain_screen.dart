import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme.dart';
import '../../../widgets/app_icon.dart';
import '../../../core/config/api_config.dart';

class VerificationChainScreen extends StatefulWidget {
  const VerificationChainScreen({super.key});

  @override
  State<VerificationChainScreen> createState() => _VerificationChainScreenState();
}

class _VerificationChainScreenState extends State<VerificationChainScreen> {
  Map<String, dynamic>? _result;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/pesees/verify-chain'),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      setState(() => _result = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SirexeTheme.surfaceLevel0,
      appBar: AppBar(
        backgroundColor: SirexeTheme.surfaceLevel1,
        title: const Text('Vérification chaîne', style: TextStyle(color: SirexeTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(onPressed: _load, icon: AppIcon.fromIconData(Icons.refresh, color: SirexeTheme.textSecondary, size: 18)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: SirexeTheme.accentBlue))
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : _result == null
                  ? const SizedBox.shrink()
                  : _buildBody(),
    );
  }

  Widget _buildBody() {
    final integre = (_result!['integre'] as bool?) ?? false;
    final message = (_result!['message'] as String?) ?? '';

    return Column(children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: integre ? SirexeTheme.success.withValues(alpha: 0.08) : SirexeTheme.danger.withValues(alpha: 0.08),
          border: Border(bottom: BorderSide(color: integre ? SirexeTheme.success.withValues(alpha: 0.3) : SirexeTheme.danger.withValues(alpha: 0.3), width: 1)),
        ),
        child: Row(children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: integre ? SirexeTheme.success.withValues(alpha: 0.12) : SirexeTheme.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: integre
              ? AppIcon.fromIconData(Icons.verified_rounded, color: SirexeTheme.success, size: 28)
              : SizedBox(width: 28, height: 28, child: SvgPicture.asset('assets/images/icon_alert_dark.svg', width: 28, height: 28, color: SirexeTheme.danger)),
          ),
          const SizedBox(width: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(integre ? 'Chaîne intègre' : 'Chaîne compromise', style: TextStyle(color: integre ? SirexeTheme.success : SirexeTheme.danger, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(message, style: const TextStyle(color: SirexeTheme.textSecondary, fontSize: 13)),
          ])),
        ]),
      ),
      Container(height: 0.5, color: SirexeTheme.border),
      Expanded(child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(integre ? Icons.shield_outlined : Icons.warning_amber_rounded, size: 80, color: integre ? SirexeTheme.success.withValues(alpha: 0.3) : SirexeTheme.danger.withValues(alpha: 0.3)),
            const SizedBox(height: 24),
            Text('SHA-256', style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text(integre ? 'Aucune altération détectée' : 'Modification non autorisée détectée', style: TextStyle(color: SirexeTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Vérification côté serveur · ${DateTime.now().toIso8601String().substring(0, 19).replaceAll('T', ' ')}', style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 11, fontFamily: 'monospace')),
          ]),
        ),
      )),
    ]);
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    AppIcon.fromIconData(Icons.wifi_off_rounded, color: SirexeTheme.danger, size: 48),
    const SizedBox(height: 16),
    Text('Impossible de joindre le backend', style: TextStyle(color: SirexeTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
    const SizedBox(height: 6),
    Text(error, style: TextStyle(color: SirexeTheme.textSecondary, fontSize: 12), textAlign: TextAlign.center),
    const SizedBox(height: 20),
    TextButton.icon(onPressed: onRetry, icon: AppIcon.fromIconData(Icons.refresh, color: SirexeTheme.accentBlue), label: const Text('Réessayer', style: TextStyle(color: SirexeTheme.accentBlue))),
  ]));
}
