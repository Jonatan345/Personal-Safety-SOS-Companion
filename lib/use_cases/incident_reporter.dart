import '../models/emergency_contact.dart';
import '../models/incident.dart';
import '../models/incident_status.dart';
import '../services/alert_service.dart';
import '../services/app_logger.dart';
import '../services/location_service.dart';
import '../utils/formatters.dart';
import '../utils/sos_message.dart';

typedef LocateCallback = Future<IncidentLocation> Function();
typedef SaveIncidentCallback = Future<void> Function(Incident incident);
typedef LoadContactCallback = Future<EmergencyContact?> Function();
typedef LoadContactsCallback = Future<List<EmergencyContact>> Function();
typedef NotesCallback = void Function(List<String> notes);

/// Hasil memproses satu insiden. [notes] berisi kegagalan yang perlu
/// diberitahukan ke pengguna (Bahasa Indonesia).
class IncidentReport {
  const IncidentReport({
    required this.incident,
    this.contact,
    this.contacts = const [],
    this.message = '',
    this.notes = const [],
  });

  final Incident incident;
  final EmergencyContact? contact;
  final List<EmergencyContact> contacts;

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
    LoadContactCallback? loadContact,
    LoadContactsCallback? loadContacts,
    required AlertGateway alerts,
    DateTime Function()? clock,
  })  : _locate = locate,
        _save = save,
        _loadContact = loadContact,
        _loadContacts = loadContacts,
        _alerts = alerts,
        _clock = clock ?? DateTime.now;

  final LocateCallback _locate;
  final SaveIncidentCallback _save;
  final LoadContactCallback? _loadContact;
  final LoadContactsCallback? _loadContacts;
  final AlertGateway _alerts;
  final DateTime Function() _clock;

  Future<IncidentReport> report(String status, {String? source}) async {
    final isSent = status == IncidentStatus.sent;
    AppLogger.instance.info(
      'incident',
      'Insiden diproses: status=$status${source != null ? ', source=$source' : ''}',
    );
    // Waktu insiden dicatat sebelum menunggu GPS (yang bisa sampai belasan detik).
    final occurredAt = _clock();
    final location = isSent ? await _tryLocate() : const _Located();

    final incident = Incident(
      id: occurredAt.microsecondsSinceEpoch.toString(),
      timestamp: occurredAt,
      latitude: location.latitude,
      longitude: location.longitude,
      status: status,
      source: source,
      isEstimatedLocation: location.isEstimated,
      locationNote: location.estimatedAgeNote,
    );
    final storageFailure = await _trySave(incident);

    if (!isSent) {
      return IncidentReport(
        incident: incident,
        notes: [if (storageFailure != null) storageFailure],
      );
    }

    final contactLoad = await _tryLoadContacts();
    final contacts = contactLoad.contacts;
    AppLogger.instance.info(
      'incident',
      'Insiden terkirim: lokasi=${incident.hasLocation}, kontak=${contacts.isNotEmpty}',
    );
    return IncidentReport(
      incident: incident,
      contact: contacts.firstOrNull,
      contacts: contacts,
      message: buildSosMessage(
        latitude: incident.latitude,
        longitude: incident.longitude,
        isEstimated: location.isEstimated,
        estimatedNote: location.estimatedAgeNote,
      ),
      notes: [
        if (location.failure != null)
          '${location.failure} Alert tetap dikirim tanpa lokasi.',
        if (location.isEstimated)
          'Menggunakan lokasi perkiraan terakhir${location.estimatedAgeNote != null ? ' (${location.estimatedAgeNote})' : ''}.',
        if (storageFailure != null) storageFailure,
        if (contactLoad.failure != null) contactLoad.failure!,
        if (contacts.isEmpty && contactLoad.failure == null)
          'Kontak darurat belum diatur, SMS tidak disiapkan.',
      ],
    );
  }

  /// Menampilkan notifikasi lalu membuka SMS composer. [onNotes] dipanggil
  /// sebelum SMS dibuka (karena aplikasi SMS memindahkan app ke latar) dan
  /// sekali lagi bila SMS gagal dibuka.
  Future<void> dispatch(IncidentReport report, NotesCallback onNotes) async {
    final contacts = report.contacts.isNotEmpty
        ? report.contacts
        : [if (report.contact != null) report.contact!];
    final notes = [...report.notes];

    final timeStr = formatClock(report.incident.timestamp);
    final notificationId = (int.tryParse(report.incident.id) ??
            report.incident.id.hashCode) &
        0x7FFFFFFF;

    final String notificationBody;
    if (contacts.isEmpty) {
      notificationBody =
          'Insiden tersimpan ($timeStr). Atur kontak untuk mengirim SMS.';
    } else if (contacts.length == 1) {
      notificationBody = 'Alert siap dikirim ke ${contacts.first.name} ($timeStr).';
    } else {
      notificationBody =
          'Alert siap dikirim ke ${contacts.length} kontak (${contacts.map((c) => c.name).join(', ')}) ($timeStr).';
    }

    final notificationFailure = await _alerts.showEmergencyNotification(
      notificationBody,
      id: notificationId,
      title: 'SOS alert dipicu ($timeStr)',
    );
    if (notificationFailure != null) {
      AppLogger.instance.warning('alert', notificationFailure);
      notes.add(notificationFailure);
    }
    if (notes.isNotEmpty) onNotes(notes);

    if (contacts.isEmpty) return;
    // Hubungkan beberapa penerima sekaligus (sms:0812...,0813...) (Feature #11)
    final phones = contacts.map((c) => c.phoneNumber).join(',');
    final smsFailure = await _alerts.openSmsComposer(
      phone: phones,
      message: report.message,
    );
    if (smsFailure != null) {
      AppLogger.instance.warning('alert', smsFailure);
      onNotes([smsFailure]);
    }
  }

  Future<_Located> _tryLocate() async {
    try {
      final position = await _locate();
      return _Located(
        latitude: position.latitude,
        longitude: position.longitude,
        isEstimated: position.isEstimated,
        estimatedAgeNote:
            position.isEstimated ? position.estimatedAgeNote : null,
      );
    } catch (error) {
      AppLogger.instance.warning('incident', 'Lokasi gagal diambil', error);
      return _Located(failure: locationFailureMessage(error));
    }
  }

  Future<String?> _trySave(Incident incident) async {
    try {
      await _save(incident);
      return null;
    } catch (error) {
      // Gagal menyimpan riwayat tidak boleh menghentikan alert darurat.
      AppLogger.instance.error(
          'incident', 'Riwayat insiden gagal disimpan', error);
      return 'Riwayat insiden gagal disimpan.';
    }
  }

  Future<_ContactLoad> tryLoadContacts() async {
    try {
      if (_loadContacts != null) {
        final list = await _loadContacts();
        return _ContactLoad(contacts: list);
      }
      if (_loadContact != null) {
        final single = await _loadContact();
        return _ContactLoad(contacts: [if (single != null) single]);
      }
      return const _ContactLoad(contacts: []);
    } catch (error) {
      AppLogger.instance.error(
          'incident', 'Kontak darurat gagal dimuat', error);
      return const _ContactLoad(
        contacts: [],
        failure: 'Kontak darurat tidak dapat dimuat.',
      );
    }
  }
}

class _Located {
  const _Located({
    this.latitude,
    this.longitude,
    this.isEstimated = false,
    this.estimatedAgeNote,
    this.failure,
  });

  final double? latitude;
  final double? longitude;
  final bool isEstimated;
  final String? estimatedAgeNote;
  final String? failure;
}

class _ContactLoad {
  const _ContactLoad({this.contacts = const [], this.failure});

  final List<EmergencyContact> contacts;
  final String? failure;
}
