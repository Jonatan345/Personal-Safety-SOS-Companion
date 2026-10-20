import 'dart:async';
import 'dart:math';

import 'package:noise_meter/noise_meter.dart';
import 'package:sensors_plus/sensors_plus.dart';

enum TriggerSource { motion, sound }

class MonitoringService {
  MonitoringService({required this.onTrigger});
  final void Function(TriggerSource source) onTrigger;
  StreamSubscription<AccelerometerEvent>? _accelerometer;
  StreamSubscription<NoiseReading>? _noise;
  DateTime? _lastTrigger;
  NoiseMeter? _noiseMeter;

  Future<void> start() async {
    _accelerometer = accelerometerEventStream().listen((event) {
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (magnitude >= 25) _trigger(TriggerSource.motion);
    });
    _noiseMeter = NoiseMeter();
    _noise = _noiseMeter!.noise.listen((reading) {
      if (reading.meanDecibel >= 85) _trigger(TriggerSource.sound);
    });
  }

  void simulateMotion() => _trigger(TriggerSource.motion);

  void _trigger(TriggerSource source) {
    final now = DateTime.now();
    if (_lastTrigger != null && now.difference(_lastTrigger!) < const Duration(seconds: 12)) return;
    _lastTrigger = now;
    onTrigger(source);
  }

  Future<void> dispose() async {
    await _accelerometer?.cancel();
    await _noise?.cancel();
  }
}
