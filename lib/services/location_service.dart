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

    // 1. Percobaan akurasi tinggi
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return IncidentLocation(
        position.latitude,
        position.longitude,
        recordedAt: position.timestamp,
        isEstimated: false,
      );
    } catch (_) {
      // 2. Percobaan kedua yang lebih cepat dengan akurasi medium
      try {
        final mediumPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 4),
          ),
        );
        return IncidentLocation(
          mediumPosition.latitude,
          mediumPosition.longitude,
          recordedAt: mediumPosition.timestamp,
          isEstimated: false,
        );
      } catch (_) {
        // 3. Cadangan: gunakan lokasi terakhir yang diketahui jika tersedia
        try {
          final lastKnown = await Geolocator.getLastKnownPosition();
          if (lastKnown != null) {
            return IncidentLocation(
              lastKnown.latitude,
              lastKnown.longitude,
              recordedAt: lastKnown.timestamp,
              isEstimated: true,
            );
          }
        } catch (_) {
          // Abaikan error pada fallback
        }
        rethrow;
      }
    }
  }
}

class IncidentLocation {
  const IncidentLocation(
    this.latitude,
    this.longitude, {
    this.isEstimated = false,
    this.recordedAt,
  });

  final double latitude;
  final double longitude;
  final bool isEstimated;
  final DateTime? recordedAt;

  String get estimatedAgeNote {
    if (recordedAt == null) return '';
    final age = DateTime.now().difference(recordedAt!);
    if (age.inMinutes < 1) return '± baru saja';
    if (age.inMinutes < 60) return '± ${age.inMinutes} menit lalu';
    final hours = age.inHours;
    if (hours < 24) return '± $hours jam lalu';
    return '± ${age.inDays} hari lalu';
  }
}

/// Alasan gagal lokasi dalam bahasa yang bisa dibaca pengguna.
String locationFailureMessage(Object error) {
  if (error is StateError) return error.message;
  if (error is TimeoutException) {
    return 'Pengambilan lokasi melewati batas waktu.';
  }
  return 'Lokasi tidak dapat diambil.';
}
