import 'package:flutter/material.dart';

/// Satu-satunya tempat SnackBar pesan dibuat, agar durasi, tombol tutup, dan
/// perilaku "ganti pesan lama" konsisten di semua layar.
void showMessage(
  ScaffoldMessengerState messenger,
  String message, {
  Duration duration = const Duration(seconds: 4),
  SnackBarAction? action,
  bool dismissible = false,
  bool replace = false,
}) {
  if (!messenger.mounted) return;
  if (replace) messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      action: action,
      showCloseIcon: dismissible && action == null,
    ),
  );
}
