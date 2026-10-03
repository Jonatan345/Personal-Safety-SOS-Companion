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
}
