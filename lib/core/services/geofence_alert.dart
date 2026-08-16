import 'package:flutter/foundation.dart';

class GeofenceAlert {
  final String message;
  final String severity;
  final DateTime timestamp;
  const GeofenceAlert(this.message, this.severity, this.timestamp);
}

final geofenceAlert = ValueNotifier<GeofenceAlert?>(null);
