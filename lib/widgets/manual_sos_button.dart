import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../routes/app_routes.dart';
import '../theme/app_theme.dart';

/// Tombol SOS manual besar di Beranda dengan mekanisme tekan-tahan (2 detik)
/// untuk mencegah sentuhan tidak sengaja, aksesibel untuk pembaca layar.
class ManualSosButton extends StatefulWidget {
  const ManualSosButton({
    super.key,
    this.holdDuration = const Duration(seconds: 2),
    this.onTriggered,
  });

  /// Durasi tekan-tahan yang diperlukan sebelum SOS dipicu.
  final Duration holdDuration;

  /// Callback opsional ketika SOS dipicu (misalnya untuk pengujian).
  /// Jika null, default melakukan navigasi ke [AppRoutes.incident] dengan argumen 'manual'.
  final VoidCallback? onTriggered;

  @override
  State<ManualSosButton> createState() => _ManualSosButtonState();
}

class _ManualSosButtonState extends State<ManualSosButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _holdTimer;
  bool _isHolding = false;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.holdDuration,
    );
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startHold() {
    if (_isHolding || _triggered) return;
    setState(() => _isHolding = true);
    HapticFeedback.lightImpact();
    _controller.forward();
    _holdTimer?.cancel();
    _holdTimer = Timer(widget.holdDuration, _triggerSos);
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (!_isHolding || _triggered) return;
    setState(() => _isHolding = false);
    _controller.reverse();
  }

  void _triggerSos() {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (_triggered) return;
    _triggered = true;
    HapticFeedback.heavyImpact();
    setState(() => _isHolding = false);

    if (widget.onTriggered != null) {
      widget.onTriggered!();
      _controller.reset();
      _triggered = false;
    } else {
      Navigator.pushNamed(
        context,
        AppRoutes.incident,
        arguments: 'manual',
      ).then((_) {
        if (mounted) {
          _controller.reset();
          setState(() => _triggered = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const label = 'Tombol SOS manual darurat';
    const hint = 'Tekan dan tahan selama 2 detik untuk mengirim SOS';

    return Semantics(
      button: true,
      label: label,
      hint: hint,
      onLongPress: _triggerSos,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          return Listener(
            onPointerDown: (_) => _startHold(),
            onPointerUp: (_) => _cancelHold(),
            onPointerCancel: (_) => _cancelHold(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.danger.withValues(alpha: 0.35),
                    blurRadius: _isHolding ? 14 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isHolding)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: progress,
                            heightFactor: 1.0,
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          const Icon(
                            Icons.emergency_outlined,
                            color: Colors.white,
                            size: 26,
                          ),
                          Text(
                            _isHolding
                                ? 'TAHAN ${(widget.holdDuration.inSeconds * (1 - progress)).toStringAsFixed(1)}s...'
                                : 'SOS MANUAL',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isHolding
                            ? 'Lepaskan untuk membatalkan'
                            : 'Tekan dan tahan 2 detik bila merasa terancam',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
