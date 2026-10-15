import 'package:hive/hive.dart';

part 'incident.g.dart';

@HiveType(typeId: 0)
class Incident extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime timestamp;

  @HiveField(2)
  double latitude;

  @HiveField(3)
  double longitude;

  @HiveField(4)
  String status; // 'sent' | 'cancelled' | 'pending'

  Incident({
    required this.id,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

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
    if (status is! String ||
        !const {'sent', 'cancelled', 'pending'}.contains(status)) {
      throw const FormatException('Incident status is invalid.');
    }

    return Incident(
      id: id,
      timestamp: DateTime.parse(timestampValue),
      latitude: latitudeValue.toDouble(),
      longitude: longitudeValue.toDouble(),
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
