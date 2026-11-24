import 'incident_status.dart';

class Incident {
  const Incident({
    required this.id,
    required this.timestamp,
    this.latitude,
    this.longitude,
    required this.status,
    this.source,
    this.isEstimatedLocation = false,
    this.locationNote,
  });

  final String id;
  final DateTime timestamp;

  /// null = lokasi tidak tersedia (GPS mati, izin ditolak, timeout, atau
  /// insiden dibatalkan sebelum lokasi diambil). Jangan diganti 0.0.
  final double? latitude;
  final double? longitude;

  /// Salah satu nilai di [IncidentStatus].
  final String status;

  /// Sumber pemicu insiden: 'manual', 'motion', 'sound', atau null untuk versi lama.
  final String? source;

  /// Apakah lokasi adalah perkiraan / lokasi terakhir yang diketahui.
  final bool isEstimatedLocation;

  /// Catatan perkiraan lokasi (mis. '± 4 menit lalu').
  final String? locationNote;

  /// Label sumber pemicu dalam Bahasa Indonesia.
  String? get sourceLabel {
    return switch (source) {
      'manual' => 'Manual',
      'motion' => 'Guncangan',
      'sound' => 'Suara keras',
      _ => source,
    };
  }

  /// Data lama yang tersimpan sebagai 0,0 juga dianggap tidak punya lokasi.
  bool get hasLocation {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) return false;
    return !(lat == 0 && lng == 0);
  }

  String get locationLabel {
    if (hasLocation) {
      final base =
          '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}';
      if (isEstimatedLocation) {
        final note = (locationNote != null && locationNote!.isNotEmpty)
            ? ' $locationNote'
            : '';
        return '$base (perkiraan$note)';
      }
      return base;
    }
    return status == IncidentStatus.cancelled
        ? 'Lokasi tidak diambil (dibatalkan)'
        : 'Lokasi tidak tersedia';
  }

  Incident copyWith({
    String? status,
    String? source,
    bool? isEstimatedLocation,
    String? locationNote,
  }) =>
      Incident(
        id: id,
        timestamp: timestamp,
        latitude: latitude,
        longitude: longitude,
        status: status ?? this.status,
        source: source ?? this.source,
        isEstimatedLocation: isEstimatedLocation ?? this.isEstimatedLocation,
        locationNote: locationNote ?? this.locationNote,
      );

  factory Incident.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final timestampValue = json['timestamp'];
    final latitudeValue = json['latitude'];
    final longitudeValue = json['longitude'];
    final status = json['status'];
    final source = json['source'];
    final isEstimatedLocation = json['isEstimatedLocation'] == true;
    final locationNote = json['locationNote'];

    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('Incident id must be a non-empty string.');
    }
    if (timestampValue is! String ||
        DateTime.tryParse(timestampValue) == null) {
      throw const FormatException('Incident timestamp must be a valid date.');
    }

    double? latitude;
    double? longitude;
    if (latitudeValue != null || longitudeValue != null) {
      latitude = _coordinate(latitudeValue, 90, 'latitude');
      longitude = _coordinate(longitudeValue, 180, 'longitude');
    }

    if (status is! String ||
        !IncidentStatus.all.contains(status)) {
      throw const FormatException('Incident status is invalid.');
    }

    if (source != null && source is! String) {
      throw const FormatException('Incident source must be a string.');
    }

    if (locationNote != null && locationNote is! String) {
      throw const FormatException('Incident locationNote must be a string.');
    }

    return Incident(
      id: id,
      timestamp: DateTime.parse(timestampValue),
      latitude: latitude,
      longitude: longitude,
      status: status,
      source: source as String?,
      isEstimatedLocation: isEstimatedLocation,
      locationNote: locationNote as String?,
    );
  }

  static double _coordinate(Object? value, double limit, String name) {
    if (value is! num ||
        !value.toDouble().isFinite ||
        value < -limit ||
        value > limit) {
      throw FormatException('Incident $name is invalid.');
    }
    return value.toDouble();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'status': status,
        if (source != null) 'source': source,
        if (isEstimatedLocation) 'isEstimatedLocation': true,
        if (locationNote != null) 'locationNote': locationNote,
      };
}
