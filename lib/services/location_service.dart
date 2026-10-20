import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<IncidentLocation> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Layanan lokasi perangkat sedang nonaktif.');
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return IncidentLocation(position.latitude, position.longitude);
  }
}

class IncidentLocation {
  const IncidentLocation(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}
