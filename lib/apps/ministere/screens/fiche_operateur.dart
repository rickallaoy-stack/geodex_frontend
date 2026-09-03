import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../widgets/quota_bar.dart';
import '../widgets/historique_pesees.dart';
import '../widgets/historique_pesees_borne.dart';
import '../widgets/alertes_operateur.dart';
import 'rapport_screen.dart';

class FicheOperateurScreen extends StatefulWidget {
  final String operateurId;
  const FicheOperateurScreen({super.key, required this.operateurId});

  @override
  State<FicheOperateurScreen> createState() => _FicheOperateurScreenState();
}

class _FicheOperateurScreenState extends State<FicheOperateurScreen> {
  Map<String, dynamic>? _profile;
  List<dynamic> _pesees = [];
  List<dynamic> _alertes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/inspecteur/operateurs/${widget.operateurId}'),
      ).timeout(const Duration(seconds: 5));
      final data = jsonDecode(res.body);
      setState(() {
        _profile = data['profile'];
        _pesees = data['historique_pesees'] ?? [];
        _alertes = data['alertes'] ?? [];
      });
    } catch (e) {
      print('Erreur fiche operateur: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_profile?['nom'] ?? 'Opérateur')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          CircleAvatar(radius: 32, child: Text((_profile?['nom'] as String?)?.substring(0,1).toUpperCase() ?? '?')),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_profile?['nom'] ?? '', style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 4),
                                Text('Permis: ${_profile?['permis_id'] ?? '—'}'),
                                const SizedBox(height: 4),
                                Text('Site: ${_profile?['site_nom'] ?? '—'}'),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              try {
                                final res = await http.get(
                                  Uri.parse('${ApiConfig.baseUrl}/api/inspecteur/operateurs/${widget.operateurId}/rapport'),
                                ).timeout(const Duration(seconds: 5));
                                final data = jsonDecode(res.body);
                                final rapport = data['rapport'];
                                if (!mounted) return;
                                if (rapport != null) {
                                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => RapportScreen(rapport: rapport)));
                                }
                              } catch (e) {
                                if (!mounted) return;
                                print('Erreur chargement rapport: $e');
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible de charger le rapport')));
                              }
                            },
                            child: const Text('Voir rapport'),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  QuotaBar(profile: _profile),
                  const SizedBox(height: 12),
                  const Text('Historique des pesées', style: TextStyle(fontWeight: FontWeight.bold)),
                  HistoriquePesees(pesees: _pesees),
                  const SizedBox(height: 12),
                  const Text('Historique Borne', style: TextStyle(fontWeight: FontWeight.bold)),
                  HistoriqueBorneTable(rfidUid: _profile?['rfid_uid'] ?? ''),
                  const SizedBox(height: 12),
                  const Text('Alertes', style: TextStyle(fontWeight: FontWeight.bold)),
                  AlertesOperateur(alertes: _alertes),
                ],
              ),
            ),
    );
  }
}
