import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<IncidentLocation> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Layanan lokasi perangkat sedang nonaktif.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission().timeout(
        const Duration(seconds: 12),
      );
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Izin lokasi diperlukan untuk mengambil posisi SOS.');
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).timeout(const Duration(seconds: 15));
    return IncidentLocation(position.latitude, position.longitude);
  }
}

class IncidentLocation {
  const IncidentLocation(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

/// Alasan gagal lokasi dalam bahasa yang bisa dibaca pengguna.
String locationFailureMessage(Object error) {
  if (error is StateError) return error.message;
  if (error is TimeoutException) {
    return 'Pengambilan lokasi melewati batas waktu.';
  }
  return 'Lokasi tidak dapat diambil.';
}
