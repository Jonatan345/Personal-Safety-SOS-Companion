import 'dart:async';
import 'dart:math';

import 'package:noise_meter/noise_meter.dart';
import 'package:sensors_plus/sensors_plus.dart';

enum TriggerSource { motion, sound }

typedef MonitoringErrorCallback = void Function(Object error);

abstract interface class MonitoringController {
  Future<void> start();
  Future<void> dispose();
  void simulateMotion();
}

typedef MonitoringServiceFactory = MonitoringController Function({
  required void Function(TriggerSource source) onTrigger,
  required MonitoringErrorCallback onError,
});

class MonitoringService implements MonitoringController {
  MonitoringService({
    required this.onTrigger,
    required this.onError,
    Stream<AccelerometerEvent> Function()? accelerometerStream,
    Stream<NoiseReading> Function()? noiseStream,
  })  : _accelerometerStream = accelerometerStream ?? accelerometerEventStream,
        _noiseStream = noiseStream;

  final void Function(TriggerSource source) onTrigger;
  final MonitoringErrorCallback onError;
  final Stream<AccelerometerEvent> Function() _accelerometerStream;
  final Stream<NoiseReading> Function()? _noiseStream;
  StreamSubscription<AccelerometerEvent>? _accelerometer;
  StreamSubscription<NoiseReading>? _noise;
  DateTime? _lastTrigger;
  NoiseMeter? _noiseMeter;
  Future<void>? _disposeFuture;
  Object? _startupError;
  bool _disposed = false;
  bool _started = false;

  @override
  Future<void> start() async {
    if (_disposed) throw StateError('Monitoring service has been disposed.');
    if (_started) return;

    try {
      _accelerometer = _accelerometerStream().listen(
        (event) {
          final magnitude =
              sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
          if (magnitude >= 25) _trigger(TriggerSource.motion);
        },
        onError: _reportStreamError,
        onDone: () => _reportStreamEnded('accelerometer'),
      );

      _noiseMeter = NoiseMeter();
      _noise = (_noiseStream?.call() ?? _noiseMeter!.noise).listen(
        (reading) {
          if (reading.meanDecibel >= 85) _trigger(TriggerSource.sound);
        },
        onError: _reportStreamError,
        onDone: () => _reportStreamEnded('microphone'),
      );

      if (_startupError case final error?) throw error;
      if (_disposed) throw StateError('Monitoring service was stopped.');
      // A sensor is ready once its stream subscription is installed. Waiting
      // for the first sample can falsely time out on a quiet microphone.
      _started = true;
    } catch (error, stackTrace) {
      unawaited(dispose());
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void _reportStreamError(Object error, StackTrace stackTrace) {
    if (!_started) {
      _startupError ??= error;
    } else if (!_disposed) {
      onError(error);
    }
  }

  void _reportStreamEnded(String sensor) {
    final error = StateError('Stream sensor $sensor berhenti.');
    if (!_started) {
      _startupError ??= error;
    } else if (!_disposed) {
      onError(error);
    }
  }

  @override
  void simulateMotion() => _trigger(TriggerSource.motion);

  void _trigger(TriggerSource source) {
    if (_disposed || !_started) return;
    final now = DateTime.now();
    if (_lastTrigger != null &&
        now.difference(_lastTrigger!) < const Duration(seconds: 12)) {
      return;
    }
    _lastTrigger = now;
    onTrigger(source);
  }

  @override
  Future<void> dispose() {
    return _disposeFuture ??= _dispose();
  }

  Future<void> _dispose() async {
    _disposed = true;
    await Future.wait([
      if (_accelerometer != null) _accelerometer!.cancel(),
      if (_noise != null) _noise!.cancel(),
    ]);
    _accelerometer = null;
    _noise = null;
    _noiseMeter = null;
  }
}
