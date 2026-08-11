# GEODEX Frontend

Application Flutter (web + Android) pour le cadastre minier de la Côte d'Ivoire.

## Structure du projet

```
sirexe/
├── lib/
│   ├── main.dart                      # Point d'entrée → LoginScreen
│   ├── core/
│   │   ├── theme.dart                 # Palette sombre GEODEX
│   │   ├── network/
│   │   │   └── api_client.dart        # Client HTTP générique (base URL, headers, timeout)
│   │   └── services/
│   │       ├── permis_service.dart    # GET /api/pesees/concessions → GeoJSON
│   │       ├── alerte_service.dart    # GET /api/pesees/alertes (polling 15s)
│   │       └── verification_service.dart # GET /api/pesees/verify-chain
│   ├── models/
│   │   ├── permis_minier.dart         # Modèle permis + parse GeoJSON
│   │   ├── pesee.dart                 # Pesée IoT + hash SHA-256
│   │   ├── alerte_model.dart          # Alerte backend
│   │   └── terrain_modules.dart       # Interfaces services terrain
│   ├── apps/
│   │   ├── auth/
│   │   │   └── login_screen.dart      # Écran login (démo ministère / opérateur terrain)
│   │   ├── ministere/
│   │   │   ├── ministere_app.dart     # App ministere avec drawer navigation
│   │   │   ├── screens/
│   │   │   │   ├── dashboard_screen.dart    # Onglets : Carte / Pesées / Alertes / Chaîne
│   │   │   │   ├── pesees_screen.dart       # Liste pesées + détail hash
│   │   │   │   └── verification_chain_screen.dart # Vérification intégrité ledger
│   │   │   └── widgets/
│   │   │       ├── stats_topbar.dart        # Topbar compteurs + logo
│   │   │       ├── sidebar_permis.dart      # Sidebar filtres + liste permis
│   │   │       └── permis_detail_panel.dart # Panneau détail permis sélectionné
│   │   └── terrain/
│   │       ├── terrain_app.dart      # App terrain dédiée
│   │       └── screens/
│   │           ├── terrain_home_screen.dart # Bottom nav : Pesée / Classer / Historique
│   │           ├── pesee_screen.dart        # Formulaire pesée camion
│   │           ├── classification_screen.dart # Classification roche
│   │           └── history_screen.dart      # Historique pesées
│   ├── screens/
│   │   ├── map_screen.dart            # Carte flutter_map + sidebar + permis panel
│   │   ├── sidebar_panel.dart         # Sidebar générique couches + filtres
│   │   └── map/
│   │       └── geo_map_screen.dart    # Carte couche géologique avec zoom +/- 
│   └── widgets/
│       ├── geo_top_bar.dart           # Topbar alternative avec chips statut
│       └── permis_panel.dart          # Panel bas pour permis sélectionné
└── assets/
    └── geology_ci.geojson             # Données géologie BGS
```

## Communication avec le backend

### Base URL
Configurée dans `lib/core/config/api_config.dart`.

### Endpoints consommés

| Méthode | Endpoint | Utilisé par | Description |
|---------|----------|-------------|-------------|
| GET | `/api/pesees/concessions` | `PermisService` | Liste des permis en GeoJSON FeatureCollection |
| GET | `/api/pesees/alertes` | `AlerteService` | Alertes fraude avec coordonnées GPS |
| GET | `/api/pesees/verify-chain` | `VerificationService` | Intégrité chaîne hash |
| POST | `/api/pesees` | `IPeseeService` | Enregistrement pesée IoT |

### Modèle de données attendu

**Concessions (`/api/pesees/concessions`)**
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": { "type": "MultiPolygon", "coordinates": [...] },
      "properties": {
        "id": "uuid",
        "code_permis": "PM-CI-2024-001",
        "nom_entreprise": "Rangold Resources CI",
        "minerai": "OR",
        "statut": "VALIDE",
        "date_attribution": "2024-01-15",
        "date_expiration": "2028-06-15"
      }
    }
  ]
}
```

**Alertes (`/api/pesees/alertes`)**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "type_anomalie": "HORS_ZONE",
      "description_detaillee": "Camion détecté hors zone autorisée",
      "date_alerte": "2026-08-10T14:30:00Z",
      "latitude": 9.52,
      "longitude": -6.48,
      "poids_mesure_kg": 38500
    }
  ]
}
```

**Vérification chaîne (`/api/pesees/verify-chain`)**
```json
{
  "valid": true,
  "total": 150,
  "invalid": 0,
  "chain": [
    {
      "id": "PSE-001",
      "hash_actuel": "a1b2c3...",
      "hash_precedent": "0000...",
      "valid": true,
      "erreur": ""
    }
  ]
}
```

## Navigation

- **Login** : sélection rôle Ministère / Opérateur terrain
- **Dashboard Ministère** : 4 onglets
  - Carte : flutter_map + sidebar permis + geofences
  - Pesées : liste + simulation live + détail hash SHA-256
  - Alertes : polling backend + toast + centrage carte
  - Chaîne : vérification intégrité ledger
- **App Terrain** : bottom navigation
  - Pesée camion
  - Classification roche
  - Historique
- **Carte Géologique** : vue dédiée avec contrôles zoom +/- et couche géologie BGS

## Map

- **Carte principale** : `lib/screens/map_screen.dart`
  - Tiles MapTiler `dataviz-dark`
  - Zoom : `minZoom: 3`, `maxZoom: 16`
  - Contrôles zoom `+`/`-` en superposition
- **Carte géologique** : `lib/screens/map/geo_map_screen.dart`
  - Couche GeoJSON géologie
  - Contrôles zoom +/- intégrés

## Lancer le projet

```bash
cd sirexe
flutter pub get
flutter run -d chrome
```

Build web :
```bash
flutter build web
```

## Note

Les données de démo sont dans `lib/models/permis_minier.dart` (`permisDemo`) et `lib/models/pesee.dart` (`genererPeseesDemo()`). Si le backend est indisponible, le frontend bascule automatiquement en mode démo.
