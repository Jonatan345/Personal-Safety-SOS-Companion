/// Isi SMS darurat. Tautan peta hanya dibuat jika koordinat benar-benar ada;
/// tanpa lokasi, pesan jujur menyebut lokasi tidak tersedia (bukan 0,0).
/// Bila lokasi merupakan perkiraan/cadangan terakhir, ditandai dengan label.
String buildSosMessage({
  double? latitude,
  double? longitude,
  bool isEstimated = false,
  String? estimatedNote,
}) {
  const base = 'SOS: kemungkinan insiden terdeteksi.';
  if (latitude == null || longitude == null) {
    return '$base Lokasi saya tidak tersedia. Mohon hubungi saya segera.';
  }
  final notePart = isEstimated
      ? ' (perkiraan${(estimatedNote != null && estimatedNote.isNotEmpty) ? ' $estimatedNote' : ''})'
      : '';
  return '$base Lokasi saya$notePart: https://maps.google.com/?q=$latitude,$longitude';
}
