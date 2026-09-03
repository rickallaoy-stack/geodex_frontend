import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../widgets/operateur_list_tile.dart';
import 'fiche_operateur.dart';

class InspecteurScreen extends StatefulWidget {
  const InspecteurScreen({super.key});

  @override
  State<InspecteurScreen> createState() => _InspecteurScreenState();
}

class _InspecteurScreenState extends State<InspecteurScreen> {
  List<dynamic> _operateurs = [];
  bool _loading = true;
  String _search = '';
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _loadOperateurs();
  }

  Future<void> _loadOperateurs({String? search, String? type}) async {
    setState(() => _loading = true);
    try {
      final query = <String, String>{};
      if (search != null && search.isNotEmpty) query['search'] = search;
      if (type != null && type.isNotEmpty) query['type'] = type;
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/inspecteur/operateurs');
      final res = await http.get(uri.replace(queryParameters: query.isEmpty ? null : query)).timeout(const Duration(seconds: 5));
      final data = jsonDecode(res.body);
      setState(() {
        _operateurs = data['data'] ?? [];
      });
    } catch (e) {
      print('Erreur chargement operateurs: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inspecteur - Opérateurs')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Rechercher nom, permis ou site'),
                    onChanged: (v) {
                      _search = v;
                      _loadOperateurs(search: _search, type: _selectedType);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    // simple toggle: clear filters
                    setState(() {
                      _search = '';
                      _selectedType = null;
                    });
                    _loadOperateurs();
                  },
                )
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    _buildChip('all', 'Tous'),
                    _buildChip('artisanal', 'Artisanal'),
                    _buildChip('semi_industriel', 'Semi-industriel'),
                    _buildChip('industriel', 'Industriel'),
                    _buildChip('non_repertorie', 'Non répertorié'),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _loadOperateurs(search: _search, type: _selectedType),
                    child: ListView.builder(
                      itemCount: _operateurs.length,
                      itemBuilder: (context, i) {
                        final op = _operateurs[i];
                        return OperateurListTile(
                          operateur: op,
                          onTap: () async {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => FicheOperateurScreen(operateurId: op['id']),
                            ));
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String value, String label) {
    final selected = (value == 'all' && _selectedType == null) || _selectedType == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _selectedType = value == 'all' ? null : value;
        });
        _loadOperateurs(search: _search, type: _selectedType);
      },
    );
  }
}
