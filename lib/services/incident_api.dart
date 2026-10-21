import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/incident.dart';

class IncidentApiException implements Exception {
  final String message;
  final int? statusCode;

  const IncidentApiException(this.message, {this.statusCode});

  @override
  String toString() => statusCode == null
      ? 'IncidentApiException: $message'
      : 'IncidentApiException: $message (HTTP $statusCode)';
}

class IncidentApi {
  static const _requestTimeout = Duration(seconds: 15);
  final String baseUrl;
  final http.Client _client;

  IncidentApi({required this.baseUrl, required http.Client client})
      : _client = client;

  Future<List<Incident>> getIncidents() async {
    final response = await _send(() => _client.get(_collectionUri));
    _ensureSuccess(response);

    final decoded = _decodeJson(response.body);
    if (decoded is! List) {
      throw const IncidentApiException(
        'Expected the incidents endpoint to return a JSON array.',
      );
    }

    return decoded.map((item) {
      if (item is! Map || item.keys.any((key) => key is! String)) {
        throw const IncidentApiException(
          'An incident in the response is not a JSON object.',
        );
      }
      return Incident.fromJson(Map<String, dynamic>.from(item));
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<Incident> createIncident(Incident incident) async {
    final response = await _send(
      () => _client.post(
        _collectionUri,
        headers: const {'content-type': 'application/json'},
        body: jsonEncode(incident.toJson()),
      ),
    );
    _ensureSuccess(response);

    if (response.body.trim().isEmpty) return incident;
    return Incident.fromJson(_decodeObject(response.body));
  }

  Future<void> updateIncident(Incident incident) async {
    final response = await _send(
      () => _client.patch(
        _itemUri(incident.id),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode(incident.toJson()),
      ),
    );
    _ensureSuccess(response);
  }

  Future<void> deleteIncident(String id) async {
    final response = await _send(() => _client.delete(_itemUri(id)));
    _ensureSuccess(response);
  }

  Uri get _collectionUri {
    final value = baseUrl.trim();
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasAuthority ||
        !const {'http', 'https'}.contains(uri.scheme) ||
        uri.query.isNotEmpty ||
        uri.fragment.isNotEmpty) {
      throw const IncidentApiException(
        'Set a valid API_BASE_URL using --dart-define.',
      );
    }
    return Uri.parse('${value.replaceFirst(RegExp(r'/+$'), '')}/incidents');
  }

  Uri _itemUri(String id) =>
      Uri.parse('${_collectionUri.toString()}/${Uri.encodeComponent(id)}');

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(_requestTimeout);
    } on TimeoutException {
      throw const IncidentApiException('The incidents request timed out.');
    } on http.ClientException {
      throw const IncidentApiException('Unable to connect to the incidents API.');
    }
  }

  dynamic _decodeJson(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      throw const IncidentApiException('The API returned invalid JSON.');
    }
  }

  Map<String, dynamic> _decodeObject(String body) {
    final decoded = _decodeJson(body);
    if (decoded is! Map || decoded.keys.any((key) => key is! String)) {
      throw const IncidentApiException(
        'Expected the API to return an incident JSON object.',
      );
    }
    return Map<String, dynamic>.from(decoded);
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw IncidentApiException(
        'The incidents request failed.',
        statusCode: response.statusCode,
      );
    }
  }
}
