import 'incident_status.dart';

class Incident {
  const Incident({
    required this.id,
    required this.timestamp,
    this.latitude,
    this.longitude,
    required this.status,
  });

  final String id;
  final DateTime timestamp;

  /// null = lokasi tidak tersedia (GPS mati, izin ditolak, timeout, atau
  /// insiden dibatalkan sebelum lokasi diambil). Jangan diganti 0.0.
  final double? latitude;
  final double? longitude;

  /// Salah satu nilai di [IncidentStatus].
  final String status;

  /// Data lama yang tersimpan sebagai 0,0 juga dianggap tidak punya lokasi.
  bool get hasLocation {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) return false;
    return !(lat == 0 && lng == 0);
  }

  String get locationLabel {
    if (hasLocation) {
      return '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}';
    }
    return status == IncidentStatus.cancelled
        ? 'Lokasi tidak diambil (dibatalkan)'
        : 'Lokasi tidak tersedia';
  }

  Incident copyWith({String? status}) => Incident(
        id: id,
        timestamp: timestamp,
        latitude: latitude,
        longitude: longitude,
        status: status ?? this.status,
      );

  factory Incident.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final timestampValue = json['timestamp'];
    final latitudeValue = json['latitude'];
    final longitudeValue = json['longitude'];
    final status = json['status'];

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
      if (latitudeValue is! num ||
          !latitudeValue.toDouble().isFinite ||
          latitudeValue < -90 ||
          latitudeValue > 90) {
        throw const FormatException('Incident latitude is invalid.');
      }
      if (longitudeValue is! num ||
          !longitudeValue.toDouble().isFinite ||
          longitudeValue < -180 ||
          longitudeValue > 180) {
        throw const FormatException('Incident longitude is invalid.');
      }
      latitude = latitudeValue.toDouble();
      longitude = longitudeValue.toDouble();
    }

    if (status is! String ||
        !IncidentStatus.all.contains(status)) {
      throw const FormatException('Incident status is invalid.');
    }

    return Incident(
      id: id,
      timestamp: DateTime.parse(timestampValue),
      latitude: latitude,
      longitude: longitude,
      status: status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'status': status,
      };
}
