import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sos_companion/models/incident.dart';
import 'package:sos_companion/services/incident_api.dart';

const _incidentJson = {
  'id': 'incident-1',
  'timestamp': '2026-10-15T05:00:00.000Z',
  'latitude': -6.2088,
  'longitude': 106.8456,
  'status': 'sent',
};

IncidentApi _api(
  Future<http.Response> Function(http.Request request) handler,
) {
  return IncidentApi(
    baseUrl: 'https://api.example.test/v1',
    client: MockClient(handler),
  );
}

void main() {
  test('parses a valid incident model', () {
    final incident = Incident.fromJson(_incidentJson);

    expect(incident.id, 'incident-1');
    expect(incident.timestamp, DateTime.utc(2026, 10, 15, 5));
    expect(incident.latitude, -6.2088);
    expect(incident.toJson(), _incidentJson);
  });

  test('rejects an incident model with invalid coordinates', () {
    expect(
      () => Incident.fromJson({..._incidentJson, 'latitude': 91}),
      throwsFormatException,
    );
  });

  test('loads and mutates incidents through the API', () async {
    var requestCount = 0;
    final api = _api((request) async {
      requestCount++;
      if (request.method == 'GET') {
        expect(
          request.url.toString(),
          'https://api.example.test/v1/incidents',
        );
        return http.Response(jsonEncode([_incidentJson]), 200);
      }
      if (request.method == 'POST') {
        expect(
          request.url.toString(),
          'https://api.example.test/v1/incidents',
        );
        expect(jsonDecode(request.body), _incidentJson);
        return http.Response(jsonEncode(_incidentJson), 201);
      }
      if (request.method == 'PATCH') {
        expect(
          request.url.toString(),
          'https://api.example.test/v1/incidents/incident-1',
        );
        expect(jsonDecode(request.body), _incidentJson);
        return http.Response('', 204);
      }
      expect(request.method, 'DELETE');
      expect(
        request.url.toString(),
        'https://api.example.test/v1/incidents/incident-1',
      );
      return http.Response('', 204);
    });

    final incidents = await api.getIncidents();
    final created = await api.createIncident(Incident.fromJson(_incidentJson));
    await api.updateIncident(created);
    await api.deleteIncident(created.id);

    expect(requestCount, 4);
    expect(incidents.single.id, 'incident-1');
    expect(created.id, 'incident-1');
  });

  test('returns an empty list for an empty API response', () async {
    final api = _api((_) async => http.Response('[]', 200));

    expect(await api.getIncidents(), isEmpty);
  });

  test('reports a failed HTTP response', () async {
    final api = _api((_) async => http.Response('Unavailable', 503));

    await expectLater(
      api.getIncidents(),
      throwsA(
        isA<IncidentApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          503,
        ),
      ),
    );
  });

  test('reports malformed JSON from the API', () async {
    final api = _api((_) async => http.Response('{not-json', 200));

    await expectLater(
      api.getIncidents(),
      throwsA(isA<IncidentApiException>()),
    );
  });
}
