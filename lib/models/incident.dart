enum IncidentStatus { sent, cancelled, pending }

class Incident {
  final String id;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final IncidentStatus status;

  Incident({
    required this.id,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.status,
  });
}
