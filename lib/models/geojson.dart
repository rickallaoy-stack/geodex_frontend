import 'package:latlong2/latlong.dart';

class GeoJsonGeometry {
  GeoJsonGeometry({
    required this.type,
    required this.coordinates,
  });

  final String type;
  final dynamic coordinates;

  factory GeoJsonGeometry.fromJson(Map<String, dynamic> json) {
    return GeoJsonGeometry(
      type: json['type'] as String,
      coordinates: json['coordinates'],
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'coordinates': coordinates,
      };

  bool get isPoint => type == 'Point';
  bool get isLineString => type == 'LineString';
  bool get isPolygon => type == 'Polygon';
  bool get isMultiPolygon => type == 'MultiPolygon';

  List<LatLng> toLatLngList() {
    if (isPoint) {
      final coords = coordinates as List;
      return [LatLng((coords[1] as num).toDouble(), (coords[0] as num).toDouble())];
    }

    if (isLineString || isPolygon) {
      final list = coordinates as List;
      final ring = isPolygon ? list.first as List : list;
      return ring
          .map<LatLng>((coord) => LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble()))
          .toList();
    }

    if (isMultiPolygon) {
      final polygons = coordinates as List;
      final firstRing = polygons.first as List;
      final list = firstRing.first as List;
      return list
          .map<LatLng>((coord) => LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble()))
          .toList();
    }

    return const [];
  }
}

class GeoJsonFeature {
  GeoJsonFeature({
    this.id,
    required this.type,
    required this.geometry,
    required this.properties,
  });

  final String? id;
  final String type;
  final GeoJsonGeometry geometry;
  final Map<String, dynamic> properties;

  factory GeoJsonFeature.fromJson(Map<String, dynamic> json) {
    return GeoJsonFeature(
      id: json['id']?.toString(),
      type: json['type'] as String,
      geometry: GeoJsonGeometry.fromJson(json['geometry'] as Map<String, dynamic>),
      properties: Map<String, dynamic>.from(json['properties'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'type': type,
        'geometry': geometry.toJson(),
        'properties': properties,
      };
}

class GeoJsonFeatureCollection {
  GeoJsonFeatureCollection({
    required this.type,
    required this.features,
  });

  final String type;
  final List<GeoJsonFeature> features;

  factory GeoJsonFeatureCollection.fromJson(Map<String, dynamic> json) {
    final featuresJson = json['features'] as List<dynamic>? ?? [];
    return GeoJsonFeatureCollection(
      type: json['type'] as String,
      features: featuresJson
          .map((featureJson) => GeoJsonFeature.fromJson(featureJson as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'features': features.map((feature) => feature.toJson()).toList(),
      };
}
