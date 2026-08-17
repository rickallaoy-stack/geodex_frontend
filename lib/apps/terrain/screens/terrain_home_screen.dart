import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme.dart';
import '../../../widgets/app_icon.dart';
import '../../../core/local/sync_queue.dart';
import '../../../models/pesee.dart';
import '../../../models/permis_minier.dart';
import '../../../core/services/permis_service.dart';
import '../../../core/services/geofence_alert.dart';

class TerrainHomeScreen extends StatefulWidget {
  const TerrainHomeScreen({super.key});
  @override
  State<TerrainHomeScreen> createState() => _TerrainHomeScreenState();
}

class _TerrainHomeScreenState extends State<TerrainHomeScreen> {
  Position? _position;
  bool _gpsLoading = false;
  bool _gpsOk      = false;

  final _camionCtrl   = TextEditingController();
  final _capteurCtrl  = TextEditingController();
  final _poidsCtrl    = TextEditingController();
  final _tapeCtrl     = TextEditingController(text: '18.5');

  bool   _submitting   = false;
  Pesee? _dernierePesee;
  String? _erreur;

  int _enAttente = 0;
  int _tabIndex  = 0;

  List<PermisMinier> _permis = [];
  bool _permisLoaded = false;
  bool _dansZoneAutorisee = false;

  final MapController _terrainMapController = MapController();

  static const _sitesTest = [
    ('Ma position réelle', null, null),
    ('Tongon (zone valide)', 9.167, -6.483),
    ('Séguéla (zone valide)', 7.967, -6.667),
    ('Boundiali Nord (illégal)', 9.52, -6.48),
    ('Hiré (suspendu)', 5.733, -4.383),
    ('Koun-Fao (expiré)', 7.283, -3.000),
  ];

  Position? _positionSimulee;

  Position? get _positionActive => _positionSimulee ?? _position;

  @override
  void initState() {
    super.initState();
    _getGPS();
    _refreshQueue();
    _loadPermis();
  }

  @override
  void dispose() {
    _camionCtrl.dispose();
    _capteurCtrl.dispose();
    _poidsCtrl.dispose();
    _tapeCtrl.dispose();
    super.dispose();
  }

  void _verifierZone() {
    if (_positionActive == null || _permis.isEmpty) return;
    
    final pos = _positionActive!;
    bool dansZone = false;
    
    for (final p in _permis) {
      if (p.statut != StatutPermis.valide) continue;
      final lats = p.polygone.map((pt) => pt.latitude);
      final lngs = p.polygone.map((pt) => pt.longitude);
      if (pos.latitude  >= lats.reduce((a,b) => a < b ? a : b) &&
          pos.latitude  <= lats.reduce((a,b) => a > b ? a : b) &&
          pos.longitude >= lngs.reduce((a,b) => a < b ? a : b) &&
          pos.longitude <= lngs.reduce((a,b) => a > b ? a : b)) {
        dansZone = true;
        break;
      }
    }
    setState(() => _dansZoneAutorisee = dansZone);
  }

  Future<void> _refreshQueue() async {
    final n = await SyncQueue.countPending();
    setState(() => _enAttente = n);
  }

  Future<void> _loadPermis() async {
    final permis = await PermisService.fetchPermis();
    setState(() {
      _permis       = permis;
      _permisLoaded = true;
    });
    _detecterCas();
    _verifierZone();
  }

  Future<void> _getGPS() async {
    setState(() => _gpsLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('GPS désactivé');

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) throw Exception('Permission refusée');
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _position   = pos;
        _gpsOk      = true;
        _gpsLoading = false;
      });
      _detecterCas();
    } catch (e) {
      setState(() {
        _gpsLoading = false;
        _gpsOk      = false;
        _erreur     = e.toString();
      });
    }
  }

  void _detecterCas() {
    if (_positionActive == null || !_permisLoaded) {
      geofenceAlert.value = null;
      return;
    }
    final pos = _positionActive!;
    String? message;
    String severity = 'info';
    for (final p in _permis) {
      final distance = Geolocator.distanceBetween(
        pos.latitude, pos.longitude,
        p.centre.latitude, p.centre.longitude,
      );
      if (distance < 15000) {
        if (p.statut == StatutPermis.illegal) {
          message = 'ZONE ILLÉGALE : ${p.id}';
          severity = 'danger';
        } else if (p.statut == StatutPermis.revoque) {
          message = 'PERMIS RÉVOQUÉ : ${p.id}';
          severity = 'danger';
        } else if (p.statut == StatutPermis.suspendu) {
          message = 'PERMIS SUSPENDU : ${p.id}';
          severity = 'warning';
        } else if (p.statut == StatutPermis.valide) {
          message = 'Zone autorisée : ${p.id}';
          severity = 'info';
        }
        break;
      }
    }
    geofenceAlert.value = message == null
        ? null
        : GeofenceAlert(message, severity, DateTime.now());
  }

  Future<void> _enregistrerPesee() async {
    if (_camionCtrl.text.isEmpty ||
        _capteurCtrl.text.isEmpty ||
        _poidsCtrl.text.isEmpty) {
      setState(() => _erreur = 'Remplir tous les champs');
      return;
    }
    if (_positionActive == null) {
      setState(() => _erreur = 'GPS requis — réessayer');
      return;
    }

    final poidsBrut = double.tryParse(_poidsCtrl.text);
    final tare      = double.tryParse(_tapeCtrl.text);
    if (poidsBrut == null || tare == null || poidsBrut <= tare) {
      setState(() => _erreur = 'Poids invalide (brut doit être > tare)');
      return;
    }

    setState(() { _submitting = true; _erreur = null; });

    final poidsNet  = poidsBrut - tare;
    final timestamp = DateTime.now();
    final camionId  = _camionCtrl.text.trim().toUpperCase();
    final capteurId = _capteurCtrl.text.trim();

    final sigPayload = '$capteurId-$camionId-${timestamp.millisecondsSinceEpoch}';
    final signature  = sha256
      .convert(utf8.encode(sigPayload))
      .toString()
      .substring(0, 16);

    final hash = Pesee.genererHash(
      permisId:  capteurId,
      camionId:  camionId,
      poidsNet:  poidsNet,
      timestamp: timestamp,
      latitude:  _positionActive!.latitude,
      longitude: _positionActive!.longitude,
    );

    final pesee = Pesee(
      id:        'PSE-${timestamp.millisecondsSinceEpoch}',
      camionId:  camionId,
      permisId:  capteurId,
      nomSite:   'Terrain',
      poidsNet:  double.parse(poidsNet.toStringAsFixed(2)),
      poidsBrut: poidsBrut,
      tare:      tare,
      timestamp: timestamp,
      latitude:  _positionActive!.latitude,
      longitude: _positionActive!.longitude,
      hash:      hash,
      statut:    StatutPesee.valide,
    );

    bool envoye = false;
    try {
      envoye = false;
    } catch (_) {}

    if (!envoye) {
      await SyncQueue.enqueue(pesee, signature: signature);
    }

    await _refreshQueue();

    setState(() {
      _dernierePesee = pesee;
      _submitting    = false;
      _camionCtrl.clear();
      _poidsCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SirexeTheme.background,
      body: SafeArea(
        child: Column(children: [
          _Topbar(enAttente: _enAttente, onSync: () async {
            await SyncQueue.syncAll();
            await _refreshQueue();
          }),
          Container(
            color: SirexeTheme.surface,
            child: Row(children: [
              _TerrainTab(
                label: 'Pesée',
                icon: Icons.scale_outlined,
                active: _tabIndex == 0,
                onTap: () => setState(() => _tabIndex = 0)),
              _TerrainTab(
                label: 'Ma zone',
                icon: Icons.map_outlined,
                active: _tabIndex == 1,
                onTap: () => setState(() => _tabIndex = 1)),
            ]),
          ),
          Container(height: 0.5, color: SirexeTheme.border),
          Expanded(child: _tabIndex == 0
            ? _buildPeseeTab()
            : _buildMapTab()),
        ]),
      ),
    );
  }

  Widget _buildPeseeTab() {
    final cas = geofenceAlert.value;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        if (_permisLoaded)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _dansZoneAutorisee
                ? SirexeTheme.accent.withOpacity(0.08)
                : SirexeTheme.danger.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _dansZoneAutorisee
                  ? SirexeTheme.accent.withOpacity(0.4)
                  : SirexeTheme.danger.withOpacity(0.4))),
            child: Row(children: [
              _dansZoneAutorisee
                ? AppIcon.fromIconData(Icons.check_circle_outline,
                    size: 16, color: SirexeTheme.accent)
                : SizedBox(width: 16, height: 16,
                    child: SvgPicture.asset(
                      'assets/images/icon_alert_dark.svg',
                      width: 16, height: 16, color: SirexeTheme.danger)),
              const SizedBox(width: 10),
              Expanded(child: Text(
                _dansZoneAutorisee
                  ? 'Vous êtes dans une zone autorisée. La pesée sera validée.'
                  : 'Attention — position hors permis actif. '
                    'Une alerte sera transmise au ministère.',
                style: TextStyle(
                  color: _dansZoneAutorisee
                    ? SirexeTheme.accent : SirexeTheme.danger,
                  fontSize: 12))),
            ]),
          ),
        _GpsCard(
          loading:  _gpsLoading,
          ok:       _gpsOk,
          position: _positionActive,
          onRetry:  _getGPS,
        ),
        if (cas != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cas.severity == 'danger'
                  ? SirexeTheme.danger.withOpacity(0.1)
                  : SirexeTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: cas.severity == 'danger'
                    ? SirexeTheme.danger.withOpacity(0.35)
                    : SirexeTheme.warning.withOpacity(0.35),
              ),
            ),
            child: Row(children: [
              cas.severity == 'danger'
                ? SizedBox(width: 18, height: 18,
                    child: SvgPicture.asset(
                      'assets/images/icon_alert_dark.svg',
                      width: 18, height: 18, color: SirexeTheme.danger))
                : AppIcon.fromIconData(Icons.info_outlined,
                  color: SirexeTheme.warning, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cas.message,
                  style: TextStyle(
                    color: SirexeTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 16),
        _FormCard(
          camionCtrl:  _camionCtrl,
          capteurCtrl: _capteurCtrl,
          poidsCtrl:   _poidsCtrl,
          tapeCtrl:    _tapeCtrl,
          submitting:  _submitting,
          erreur:      _erreur,
          onSubmit:    _enregistrerPesee,
        ),
        const SizedBox(height: 16),
        if (_dernierePesee != null)
          _ResultCard(pesee: _dernierePesee!),
      ]),
    );
  }

  Widget _buildMapTab() {
    final center = _positionActive != null
      ? LatLng(_positionActive!.latitude, _positionActive!.longitude)
      : const LatLng(7.5, -5.5);

    return Stack(children: [
      FlutterMap(
        mapController: _terrainMapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: _positionActive != null ? 10.0 : 6.2,
          minZoom: 3,
          maxZoom: 16,
        ),
        children: [
          TileLayer(
            urlTemplate:
              'https://api.maptiler.com/maps/dataviz-dark/{z}/{x}/{y}.png?key={key}',
            additionalOptions: const {'key': '6tZxrsJMAnTertUR2ILg'},
            userAgentPackageName: 'ci.geodex.app',
          ),
          if (_permisLoaded)
            PolygonLayer(
              polygons: _permis.map((p) => Polygon(
                points: p.polygone,
                color: p.couleur.withOpacity(0.12),
                borderColor: p.couleur,
                borderStrokeWidth: 1.5,
              )).toList(),
            ),
          CircleLayer(
            circles: _permis
              .where((p) => p.statut == StatutPermis.valide)
              .map((p) => CircleMarker(
                point: p.centre,
                radius: 15000,
                useRadiusInMeter: true,
                color: SirexeTheme.accent.withOpacity(0.04),
                borderColor: SirexeTheme.accent.withOpacity(0.5),
                borderStrokeWidth: 1.5,
              )).toList(),
          ),
          if (_positionActive != null)
            MarkerLayer(markers: [
              Marker(
                point: LatLng(
                  _positionActive!.latitude,
                  _positionActive!.longitude,
                ),
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: SirexeTheme.accentBlue.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: SirexeTheme.accentBlue, width: 2),
                  ),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: SvgPicture.asset(
                      'assets/images/icon_user_dark.svg',
                      width: 20,
                      height: 20,
                    ),
                  ),
                ),
              ),
            ]),
        ],
      ),
      Positioned(top: 12, left: 12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: SirexeTheme.surface.withOpacity(0.95),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _positionSimulee != null
                ? SirexeTheme.warning : SirexeTheme.border)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            AppIcon.fromIconData(Icons.science_outlined,
              color: _positionSimulee != null
                ? SirexeTheme.warning : SirexeTheme.textSecondary,
              size: 13),
            const SizedBox(width: 6),
            DropdownButton<int>(
              value: null,
              hint: Text(
                _positionSimulee != null ? 'Mode simulation' : 'Téléporter →',
                style: TextStyle(
                  color: _positionSimulee != null
                    ? SirexeTheme.warning : SirexeTheme.textSecondary,
                  fontSize: 11)),
              underline: const SizedBox(),
              isDense: true,
              dropdownColor: SirexeTheme.surface,
              items: _sitesTest.asMap().entries.map((e) =>
                DropdownMenuItem<int>(
                  value: e.key,
                  child: Text(e.value.$1, style: const TextStyle(
                    color: SirexeTheme.textPrimary, fontSize: 12)),
                )
              ).toList(),
              onChanged: (i) {
                if (i == null) return;
                final site = _sitesTest[i];
                if (site.$2 == null) {
                  setState(() => _positionSimulee = null);
                  if (_position != null) {
                    _terrainMapController.move(
                      LatLng(_position!.latitude, _position!.longitude), 10);
                  }
                } else {
                  setState(() => _positionSimulee = _fakePosition(
                    site.$2!, site.$3!));
                  _terrainMapController.move(
                    LatLng(site.$2!, site.$3!), 11);
                }
                _detecterCas();
                _verifierZone();
              },
            ),
          ]),
        ),
      ),
      if (_positionActive != null)
        Positioned(bottom: _positionActive != null ? 60 : 16, left: 16,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _dansZoneAutorisee
                ? SirexeTheme.accent.withOpacity(0.15)
                : SirexeTheme.danger.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _dansZoneAutorisee
                  ? SirexeTheme.accent : SirexeTheme.danger,
                width: 1.5),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              AppIcon.fromIconData(
                _dansZoneAutorisee
                  ? Icons.verified_outlined
                  : Icons.block_outlined,
                size: 14,
                color: _dansZoneAutorisee
                  ? SirexeTheme.accent : SirexeTheme.danger),
              const SizedBox(width: 6),
              Text(
                _dansZoneAutorisee
                  ? 'Zone autorisée — pesée valide'
                  : 'Hors zone — pesée bloquée',
                style: TextStyle(
                  color: _dansZoneAutorisee
                    ? SirexeTheme.accent : SirexeTheme.danger,
                  fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      if (_positionActive != null)
        Positioned(bottom: 16, left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: SirexeTheme.surface.withOpacity(0.95),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: SirexeTheme.border)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              AppIcon.fromIconData(Icons.gps_fixed,
                color: _positionSimulee != null
                  ? SirexeTheme.warning : SirexeTheme.accentBlue,
                size: 12),
              const SizedBox(width: 6),
              Text(
                '${_positionActive!.latitude.toStringAsFixed(4)}°N  '
                '${_positionActive!.longitude.toStringAsFixed(4)}°W'
                '${_positionSimulee != null ? '  · SIMULATION' : ''}',
                style: TextStyle(
                  color: _positionSimulee != null
                    ? SirexeTheme.warning : SirexeTheme.textPrimary,
                  fontSize: 11, fontFamily: 'monospace')),
            ]),
          ),
        ),
      Positioned(top: 12, right: 12,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: SirexeTheme.surface.withOpacity(0.95),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: SirexeTheme.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _LegendRow(color: SirexeTheme.accent,      label: 'Zone autorisée'),
              _LegendRow(color: SirexeTheme.warning,     label: 'Suspendu'),
              _LegendRow(color: SirexeTheme.danger,      label: 'Illégal / révoqué'),
              _LegendRow(color: SirexeTheme.accentBlue,  label: 'Ma position'),
            ],
          ),
        ),
      ),
      Positioned(bottom: 16, right: 16,
        child: GestureDetector(
          onTap: () {
            if (_positionActive != null) {
              _terrainMapController.move(
                LatLng(_positionActive!.latitude, _positionActive!.longitude),
                12.0);
            }
          },
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: SirexeTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SirexeTheme.border),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3),
                  blurRadius: 8)
              ]),
            child: AppIcon.fromIconData(Icons.my_location,
              color: SirexeTheme.accentBlue, size: 18)),
        ),
      ),
    ]);
  }

  Position _fakePosition(double lat, double lng) => Position(
    latitude:         lat,
    longitude:        lng,
    accuracy:         5.0,
    altitude:         200.0,
    altitudeAccuracy: 5.0,
    heading:          0.0,
    headingAccuracy:  0.0,
    speed:            0.0,
    speedAccuracy:    0.0,
    timestamp:        DateTime.now(),
  );
}

class _Topbar extends StatelessWidget {
  final int enAttente;
  final VoidCallback onSync;
  const _Topbar({required this.enAttente, required this.onSync});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: const BoxDecoration(
      color: SirexeTheme.surface,
      border: Border(bottom: BorderSide(
        color: SirexeTheme.border, width: 0.5))),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: SirexeTheme.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: SirexeTheme.accent.withOpacity(0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 7, height: 7,
            decoration: const BoxDecoration(
              color: SirexeTheme.accent, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          const Text('GEODEX', style: TextStyle(
            color: SirexeTheme.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 13, letterSpacing: 2)),
          const SizedBox(width: 6),
          const Text('Terrain', style: TextStyle(
            color: SirexeTheme.textSecondary, fontSize: 12)),
        ]),
      ),
      const Spacer(),
      if (enAttente > 0)
        GestureDetector(
          onTap: onSync,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: SirexeTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: SirexeTheme.warning.withOpacity(0.4))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              AppIcon.fromIconData(Icons.cloud_upload_outlined,
                color: SirexeTheme.warning, size: 13),
              const SizedBox(width: 5),
              Text('$enAttente en attente · Sync',
                style: const TextStyle(
                  color: SirexeTheme.warning, fontSize: 11)),
            ]),
          ),
        )
      else
          Row(mainAxisSize: MainAxisSize.min, children: [
          AppIcon.fromIconData(Icons.cloud_done_outlined,
            color: SirexeTheme.accent, size: 13),
          const SizedBox(width: 5),
          const Text('Synchronisé', style: TextStyle(
            color: SirexeTheme.accent, fontSize: 11)),
        ]),
    ]),
  );
}

class _GpsCard extends StatelessWidget {
  final bool loading, ok;
  final Position? position;
  final VoidCallback onRetry;
  const _GpsCard({required this.loading, required this.ok,
    this.position, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: SirexeTheme.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: loading
          ? SirexeTheme.border
          : ok
            ? SirexeTheme.accent.withOpacity(0.4)
            : SirexeTheme.danger.withOpacity(0.4))),
    child: Row(children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: (ok ? SirexeTheme.accent : SirexeTheme.danger)
            .withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
        child: loading
          ? const Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(
                strokeWidth: 2, color: SirexeTheme.accentBlue))
            : AppIcon.fromIconData(
              ok ? Icons.gps_fixed : Icons.gps_off,
              size: 18, color: ok ? SirexeTheme.accent : SirexeTheme.danger)),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loading ? 'Acquisition GPS...'
              : ok ? 'Position verrouillée'
              : 'GPS indisponible',
            style: TextStyle(
              color: ok ? SirexeTheme.accent : SirexeTheme.danger,
              fontSize: 13, fontWeight: FontWeight.w600)),
          if (ok && position != null)
            Text(
              '${position!.latitude.toStringAsFixed(5)}°N  '
              '${position!.longitude.toStringAsFixed(5)}°W  '
              '±${position!.accuracy.toStringAsFixed(0)}m',
              style: const TextStyle(
                color: SirexeTheme.textSecondary,
                fontSize: 11, fontFamily: 'monospace')),
        ],
      )),
      if (!loading && !ok)
        GestureDetector(
          onTap: onRetry,
          child: AppIcon.fromIconData(Icons.refresh,
            color: SirexeTheme.textSecondary, size: 18)),
    ]),
  );
}

class _FormCard extends StatelessWidget {
  final TextEditingController camionCtrl, capteurCtrl, poidsCtrl, tapeCtrl;
  final bool submitting;
  final String? erreur;
  final VoidCallback onSubmit;
  const _FormCard({required this.camionCtrl, required this.capteurCtrl,
    required this.poidsCtrl, required this.tapeCtrl,
    required this.submitting, required this.erreur,
    required this.onSubmit});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: SirexeTheme.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: SirexeTheme.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('NOUVELLE PESÉE', style: TextStyle(
        color: SirexeTheme.textSecondary, fontSize: 11,
        fontWeight: FontWeight.w500, letterSpacing: 1)),
      const SizedBox(height: 14),
      _TerrainField(label: 'ID Camion', ctrl: camionCtrl,
        hint: 'ex: CAM-TG-04', icon: Icons.local_shipping_outlined),
      const SizedBox(height: 10),
      _TerrainField(label: 'ID Capteur IoT', ctrl: capteurCtrl,
        hint: 'UUID du capteur ESP32', icon: Icons.sensors),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _TerrainField(
          label: 'Poids brut (kg)', ctrl: poidsCtrl,
          hint: '0.00', icon: Icons.scale_outlined, numeric: true)),
        const SizedBox(width: 10),
        Expanded(child: _TerrainField(
          label: 'Tare (kg)', ctrl: tapeCtrl,
          hint: '18.5', icon: Icons.remove_circle_outline, numeric: true)),
      ]),
        if (erreur != null) ...[
        const SizedBox(height: 10),
        Row(children: [
          AppIcon.fromIconData(Icons.error_outline,
            color: SirexeTheme.danger, size: 13),
          const SizedBox(width: 6),
          Expanded(child: Text(erreur!, style: const TextStyle(
            color: SirexeTheme.danger, fontSize: 12))),
        ]),
      ],
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: GestureDetector(
          onTap: submitting ? null : onSubmit,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: submitting
                ? SirexeTheme.surfaceElevated
                : SirexeTheme.accent,
              borderRadius: BorderRadius.circular(9)),
            child: Center(child: submitting
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppIcon.fromIconData(Icons.scale, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    const Text('Enregistrer la pesée',
                      style: TextStyle(color: Colors.white,
                        fontSize: 14, fontWeight: FontWeight.w700)),
                  ])),
          ),
        ),
      ),
    ]),
  );
}

class _TerrainField extends StatelessWidget {
  final String label, hint;
  final TextEditingController ctrl;
  final IconData icon;
  final bool numeric;
  const _TerrainField({required this.label, required this.hint,
    required this.ctrl, required this.icon, this.numeric = false});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(
        color: SirexeTheme.textSecondary, fontSize: 11,
        fontWeight: FontWeight.w500)),
      const SizedBox(height: 5),
      TextField(
        controller: ctrl,
        keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
        style: const TextStyle(
          color: SirexeTheme.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: SirexeTheme.textSecondary, fontSize: 12),
          prefixIcon: AppIcon.fromIconData(icon,
            color: SirexeTheme.textSecondary, size: 15),
          filled: true,
          fillColor: SirexeTheme.surfaceElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: SirexeTheme.border, width: 0.5)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: SirexeTheme.border, width: 0.5)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: SirexeTheme.accent, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 12)),
      ),
    ],
  );
}

class _ResultCard extends StatelessWidget {
  final Pesee pesee;
  const _ResultCard({required this.pesee});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: SirexeTheme.accent.withOpacity(0.06),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: SirexeTheme.accent.withOpacity(0.35))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        AppIcon.fromIconData(Icons.check_circle_outline,
          color: SirexeTheme.accent, size: 16),
        const SizedBox(width: 8),
        const Text('Pesée enregistrée localement',
          style: TextStyle(color: SirexeTheme.accent,
            fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 12),
      _Line('Camion',    pesee.camionId),
      _Line('Poids net', '${pesee.poidsNet} kg'),
      _Line('GPS',
        '${pesee.latitude.toStringAsFixed(5)}°N · '
        '${pesee.longitude.toStringAsFixed(5)}°W'),
      const SizedBox(height: 10),
      const Text('Hash SHA-256', style: TextStyle(
        color: SirexeTheme.textSecondary, fontSize: 10,
        fontWeight: FontWeight.w500, letterSpacing: 0.5)),
      const SizedBox(height: 5),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: SirexeTheme.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: SirexeTheme.border)),
        child: Text(pesee.hash,
          style: const TextStyle(
            color: SirexeTheme.textPrimary,
            fontSize: 10, fontFamily: 'monospace',
            letterSpacing: 0.5)),
      ),
      const SizedBox(height: 8),
      Row(children: [
        AppIcon.fromIconData(Icons.cloud_upload_outlined,
          color: SirexeTheme.warning, size: 12),
        const SizedBox(width: 5),
        const Text('En attente de synchronisation',
          style: TextStyle(color: SirexeTheme.warning, fontSize: 11)),
      ]),
    ]),
  );
}

class _Line extends StatelessWidget {
  final String label, value;
  const _Line(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(children: [
      SizedBox(width: 80, child: Text(label, style: const TextStyle(
        color: SirexeTheme.textSecondary, fontSize: 12))),
      Expanded(child: Text(value, style: const TextStyle(
        color: SirexeTheme.textPrimary, fontSize: 12))),
    ]),
  );
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendRow({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(
        color: SirexeTheme.textPrimary, fontSize: 10)),
    ]),
  );
}

class _TerrainTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _TerrainTab({required this.label, required this.icon,
    required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(
          color: active ? SirexeTheme.accent : Colors.transparent,
          width: 2))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        AppIcon.fromIconData(icon, size: 14,
          color: active
            ? SirexeTheme.accent : SirexeTheme.textSecondary),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(
          color: active
            ? SirexeTheme.accent : SirexeTheme.textSecondary,
          fontSize: 13,
          fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
      ]),
    ),
  );
}
