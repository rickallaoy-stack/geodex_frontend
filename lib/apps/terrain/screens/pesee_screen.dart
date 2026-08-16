import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/permis_minier.dart';
import '../../../models/terrain_modules.dart';

class PeseeScreen extends StatefulWidget {
  const PeseeScreen({super.key});

  @override
  State<PeseeScreen> createState() => _PeseeScreenState();
}

class _PeseeScreenState extends State<PeseeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _camionCtrl = TextEditingController();
  final _tareCtrl = TextEditingController();
  final _brutCtrl = TextEditingController();

  bool _saving = false;
  String? _message;

  @override
  void dispose() {
    _camionCtrl.dispose();
    _tareCtrl.dispose();
    _brutCtrl.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _message = null; });

    final permis = permisDemo.firstWhere(
      (p) => p.statut == StatutPermis.valide,
      orElse: () => permisDemo.first,
    );

    final now = DateTime.now();
    final tare = double.tryParse(_tareCtrl.text.trim()) ?? 0;
    final brut = double.tryParse(_brutCtrl.text.trim()) ?? 0;
    final net = brut - tare;

    final session = SessionPesee(
      id: 'PSE-${Random().nextInt(9000) + 1000}',
      permisId: permis.id,
      camion: _camionCtrl.text.trim(),
      tarePoids: tare,
      brutPoids: brut,
      horodatage: now,
      operateur: 'Terrain',
    );

    await TerrainServices.pesee.enregistrer(session);

    if (!mounted) return;
    setState(() {
      _saving = false;
      _message = 'Pesée enregistrée : ${net.toStringAsFixed(1)} t net';
    });

    _formKey.currentState!.reset();
    _camionCtrl.clear();
    _tareCtrl.clear();
    _brutCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SirexeTheme.background,
      appBar: AppBar(
        backgroundColor: SirexeTheme.surface,
        title: const Text('Nouvelle pesée', style: TextStyle(color: SirexeTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(children: [
              _Field(
                label: 'Immatriculation camion',
                controller: _camionCtrl,
                hint: 'CI-1234-AB',
                icon: Icons.directions_car_outlined,
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Tare (kg)',
                controller: _tareCtrl,
                hint: '18000',
                icon: Icons.scale_outlined,
                keyboard: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Brut (kg)',
                controller: _brutCtrl,
                hint: '53000',
                icon: Icons.scale_rounded,
                keyboard: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _enregistrer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SirexeTheme.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _saving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined, color: Colors.white),
                  label: Text(_saving ? 'Enregistrement...' : 'Enregistrer', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SirexeTheme.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: SirexeTheme.accent.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline, color: SirexeTheme.accent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_message!, style: const TextStyle(color: SirexeTheme.textPrimary, fontSize: 13))),
                  ]),
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboard;
  const _Field({required this.label, required this.hint,
    required this.controller, required this.icon,
    this.keyboard});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(
        color: SirexeTheme.textSecondary, fontSize: 11,
        fontWeight: FontWeight.w500, letterSpacing: 0.5)),
      const SizedBox(height: 5),
      TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        style: const TextStyle(color: SirexeTheme.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: SirexeTheme.textSecondary, fontSize: 13),
          prefixIcon: Icon(icon, color: SirexeTheme.textSecondary, size: 16),
          filled: true,
          fillColor: SirexeTheme.surfaceElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: SirexeTheme.border, width: 0.5)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: SirexeTheme.border, width: 0.5)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: SirexeTheme.accent, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    ],
  );
}
