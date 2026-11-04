import '../models/emergency_contact.dart';
import '../models/incident.dart';
import '../models/incident_status.dart';
import '../services/alert_service.dart';
import '../services/location_service.dart';
import '../utils/sos_message.dart';

typedef LocateCallback = Future<IncidentLocation> Function();
typedef SaveIncidentCallback = Future<void> Function(Incident incident);
typedef LoadContactCallback = Future<EmergencyContact?> Function();
typedef NotesCallback = void Function(List<String> notes);

/// Hasil memproses satu insiden. [notes] berisi kegagalan yang perlu
/// diberitahukan ke pengguna (Bahasa Indonesia).
class IncidentReport {
  const IncidentReport({
    required this.incident,
    this.contact,
    this.message = '',
    this.notes = const [],
  });

  final Incident incident;
  final EmergencyContact? contact;

  /// Isi SMS darurat (kosong untuk insiden yang dibatalkan).
  final String message;
  final List<String> notes;

  bool get isSent => incident.status == IncidentStatus.sent;
}

/// Alur satu insiden, dipecah menjadi langkah kecil: lokasi, simpan, kontak,
/// lalu kirim notifikasi dan SMS. Semua dependensi masuk lewat constructor.
/// Tidak ada langkah yang melempar error: kegagalan dicatat di
/// [IncidentReport.notes] sehingga alert darurat tidak ikut berhenti.
class IncidentReporter {
  IncidentReporter({
    required LocateCallback locate,
    required SaveIncidentCallback save,
    required LoadContactCallback loadContact,
    required AlertGateway alerts,
    DateTime Function()? clock,
  })  : _locate = locate,
        _save = save,
        _loadContact = loadContact,
        _alerts = alerts,
        _clock = clock ?? DateTime.now;

  final LocateCallback _locate;
  final SaveIncidentCallback _save;
  final LoadContactCallback _loadContact;
  final AlertGateway _alerts;
  final DateTime Function() _clock;

  Future<IncidentReport> report(String status) async {
    final isSent = status == IncidentStatus.sent;
    // Waktu insiden dicatat sebelum menunggu GPS (yang bisa sampai belasan detik).
    final occurredAt = _clock();
    final location = isSent ? await _tryLocate() : const _Located();

    final incident = Incident(
      id: occurredAt.microsecondsSinceEpoch.toString(),
      timestamp: occurredAt,
      latitude: location.latitude,
      longitude: location.longitude,
      status: status,
    );
    final storageFailure = await _trySave(incident);

    if (!isSent) {
      return IncidentReport(
        incident: incident,
        notes: [if (storageFailure != null) storageFailure],
      );
    }

    final contact = await _tryLoadContact();
    return IncidentReport(
      incident: incident,
      contact: contact.contact,
      message: buildSosMessage(
        latitude: incident.latitude,
        longitude: incident.longitude,
      ),
      notes: [
        if (location.failure != null)
          '${location.failure} Alert tetap dikirim tanpa lokasi.',
        if (storageFailure != null) storageFailure,
        if (contact.failure != null) contact.failure!,
        if (contact.contact == null && contact.failure == null)
          'Kontak darurat belum diatur, SMS tidak disiapkan.',
      ],
    );
  }

  /// Menampilkan notifikasi lalu membuka SMS composer. [onNotes] dipanggil
  /// sebelum SMS dibuka (karena aplikasi SMS memindahkan app ke latar) dan
  /// sekali lagi bila SMS gagal dibuka.
  Future<void> dispatch(IncidentReport report, NotesCallback onNotes) async {
    final contact = report.contact;
    final notes = [...report.notes];

    final notificationFailure = await _alerts.showEmergencyNotification(
      contact == null
          ? 'Insiden tersimpan. Atur kontak untuk mengirim SMS.'
          : 'Alert siap dikirim ke ${contact.name}.',
    );
    if (notificationFailure != null) notes.add(notificationFailure);
    if (notes.isNotEmpty) onNotes(notes);

    if (contact == null) return;
    final smsFailure = await _alerts.openSmsComposer(
      phone: contact.phoneNumber,
      message: report.message,
    );
    if (smsFailure != null) onNotes([smsFailure]);
  }

  Future<_Located> _tryLocate() async {
    try {
      final position = await _locate();
      return _Located(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (error) {
      return _Located(failure: locationFailureMessage(error));
    }
  }

  Future<String?> _trySave(Incident incident) async {
    try {
      await _save(incident);
      return null;
    } catch (_) {
      // Gagal menyimpan riwayat tidak boleh menghentikan alert darurat.
      return 'Riwayat insiden gagal disimpan.';
    }
  }

  Future<_ContactLoad> _tryLoadContact() async {
    try {
      return _ContactLoad(contact: await _loadContact());
    } catch (_) {
      return const _ContactLoad(failure: 'Kontak darurat tidak dapat dimuat.');
    }
  }
}

class _Located {
  const _Located({this.latitude, this.longitude, this.failure});

  final double? latitude;
  final double? longitude;
  final String? failure;
}

class _ContactLoad {
  const _ContactLoad({this.contact, this.failure});

  final EmergencyContact? contact;
  final String? failure;
}
