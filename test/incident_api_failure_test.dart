import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sos_companion/services/incident_api.dart';
import 'package:sos_companion/utils/error_messages.dart';

IncidentApi _api(
  http.Client client, {
  Duration timeout = const Duration(milliseconds: 30),
}) =>
    IncidentApi(
      baseUrl: 'https://api.example.test/api',
      client: client,
      requestTimeout: timeout,
    );

Matcher _apiError(IncidentApiErrorKind kind, String indonesianPart) =>
    isA<IncidentApiException>()
        .having((e) => e.kind, 'kind', kind)
        .having((e) => e.userMessage, 'userMessage', contains(indonesianPart));

void main() {
  test('a request that never answers becomes a timeout error', () async {
    final api = _api(MockClient((_) => Completer<http.Response>().future));

    await expectLater(
      api.getIncidents(),
      throwsA(_apiError(IncidentApiErrorKind.timeout, 'terlalu lama')),
    );
  });

  test('a network failure becomes a connection error', () async {
    final api = _api(
      MockClient((_) async => throw http.ClientException('Connection refused')),
    );

    await expectLater(
      api.getIncidents(),
      throwsA(_apiError(
          IncidentApiErrorKind.network, 'Tidak dapat terhubung ke server')),
    );
  });

  test('a network failure also fails create, update and delete', () async {
    final api = _api(
      MockClient((_) async => throw http.ClientException('offline')),
    );
    final incidents = <Future<void> Function()>[
      () => api.getIncidents(),
      () => api.deleteIncident('1'),
    ];

    for (final call in incidents) {
      await expectLater(
        call(),
        throwsA(isA<IncidentApiException>()
            .having((e) => e.kind, 'kind', IncidentApiErrorKind.network)),
      );
    }
  });

  test('a 5xx response is reported as a server problem with its code',
      () async {
    final api = _api(MockClient((_) async => http.Response('', 503)));

    await expectLater(
      api.getIncidents(),
      throwsA(_apiError(IncidentApiErrorKind.http, 'Server sedang bermasalah')),
    );
  });

  test('a 4xx response is reported as a rejected request', () async {
    final api = _api(MockClient((_) async => http.Response('', 404)));

    await expectLater(
      api.getIncidents(),
      throwsA(_apiError(IncidentApiErrorKind.http, 'Server menolak')),
    );
  });

  test('broken JSON is reported as invalid data', () async {
    final api = _api(MockClient((_) async => http.Response('{rusak', 200)));

    await expectLater(
      api.getIncidents(),
      throwsA(_apiError(
          IncidentApiErrorKind.invalidResponse, 'Data dari server tidak valid')),
    );
  });

  test('a JSON object instead of an array is reported as invalid data',
      () async {
    final api = _api(MockClient((_) async => http.Response('{}', 200)));

    await expectLater(
      api.getIncidents(),
      throwsA(isA<IncidentApiException>().having(
          (e) => e.kind, 'kind', IncidentApiErrorKind.invalidResponse)),
    );
  });

  test('a bad base URL is reported as a configuration problem', () async {
    final api = IncidentApi(
      baseUrl: 'bukan-url',
      client: MockClient((_) async => http.Response('[]', 200)),
    );

    await expectLater(
      api.getIncidents(),
      throwsA(_apiError(IncidentApiErrorKind.configuration, 'Alamat server')),
    );
  });

  group('userMessageFor', () {
    const englishWords = ['Unable', 'timed out', 'failed', 'Expected', 'Exception'];

    test('never shows English or raw exception text', () {
      final messages = [
        for (final kind in IncidentApiErrorKind.values)
          userMessageFor(IncidentApiException('English log text',
              statusCode: 500, kind: kind)),
        userMessageFor(TimeoutException('x')),
        userMessageFor(const FormatException('bad')),
        userMessageFor(Exception('boom')),
        userMessageFor(StateError('boom')),
      ];

      for (final message in messages) {
        for (final word in englishWords) {
          expect(message, isNot(contains(word)), reason: message);
        }
        expect(message, isNotEmpty);
      }
    });

    test('maps generic errors to a short Indonesian message', () {
      expect(userMessageFor(Exception('boom')), 'Terjadi kesalahan. Coba lagi.');
      expect(userMessageFor(TimeoutException('x')), contains('batas waktu'));
    });
  });
}
