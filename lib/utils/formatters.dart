String _two(int value) => value.toString().padLeft(2, '0');

String formatDate(DateTime time) {
  final local = time.toLocal();
  return '${_two(local.day)}/${_two(local.month)}/${local.year}';
}

String formatClock(DateTime time) {
  final local = time.toLocal();
  return '${_two(local.hour)}:${_two(local.minute)}';
}

String formatDateTime(DateTime time) =>
    '${formatDate(time)} • ${formatClock(time)}';

/// Versi untuk pembaca layar (tanpa simbol titik).
String formatDateTimeSpoken(DateTime time) =>
    '${formatDate(time)} pukul ${formatClock(time)}';
