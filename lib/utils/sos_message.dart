/// Isi SMS darurat. Tautan peta hanya dibuat jika koordinat benar-benar ada;
/// tanpa lokasi, pesan jujur menyebut lokasi tidak tersedia (bukan 0,0).
String buildSosMessage({double? latitude, double? longitude}) {
  const base = 'SOS: kemungkinan insiden terdeteksi.';
  if (latitude == null || longitude == null) {
    return '$base Lokasi saya tidak tersedia. Mohon hubungi saya segera.';
  }
  return '$base Lokasi saya: https://maps.google.com/?q=$latitude,$longitude';
}
