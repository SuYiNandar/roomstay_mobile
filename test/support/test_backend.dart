import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roomstay_mobile/data/user_session.dart';

import '../fixtures/demo_viewings.dart';
import '../fixtures/sample_properties.dart';

final favoriteRows = <Map<String, dynamic>>[];
final favoriteRequests = <http.Request>[];
final apiRequests = <http.Request>[];
FutureOr<http.Response> Function(http.Request)? favoritesResponse;
FutureOr<http.Response?> Function(http.Request)? apiResponse;
String testEmail = 'renter@example.com';

void resetTestBackend() {
  favoriteRows.clear();
  favoriteRequests.clear();
  apiRequests.clear();
  favoritesResponse = null;
  apiResponse = null;
  testEmail = 'renter@example.com';
  resetDemoViewings();
  UserSession.clear();
  UserSession.accessToken = 'test-access-token';
  UserSession.userId = 'test-user-id';
}

// The HTTP override exists only inside these widget tests.
void testWithApi(String description, WidgetTesterCallback callback) {
  testWidgets(description, (tester) async {
    await http.runWithClient(() => callback(tester), createTestClient);
  });
}

http.Response jsonResponse(Object data, [int status = 200]) {
  return http.Response(
    jsonEncode(data),
    status,
    headers: {'content-type': 'application/json'},
  );
}

http.Client createTestClient() => MockClient((request) async {
  apiRequests.add(request);
  if (apiResponse != null) {
    final response = await apiResponse!(request);
    if (response != null) return response;
  }

  switch (request.url.path) {
    case '/auth/v1/token':
      testEmail = jsonDecode(request.body)['email'] as String;
      return jsonResponse({
        'access_token': 'test-access-token',
        'refresh_token': 'test-refresh-token',
        'user': {'id': 'test-user-id', 'email': testEmail},
      });
    case '/auth/v1/signup':
      return jsonResponse({
        'user': {'id': 'test-user-id'},
      });
    case '/rest/v1/profiles':
      return jsonResponse([
        {
          'id': 'test-user-id',
          'full_name': 'Test User',
          'email': testEmail,
          'role': testEmail.startsWith('partner@') ? 'partner' : 'renter',
        },
      ]);
    case '/rest/v1/properties':
      final idFilter = request.url.queryParameters['id'];
      if (idFilter == null) return jsonResponse(samplePropertyMaps);
      return jsonResponse([
        for (final property in samplePropertyMaps)
          if ('eq.${property['id']}' == idFilter) property,
      ]);
    case '/rest/v1/viewings':
      return handleViewings(request);
    case '/rest/v1/favorites':
      favoriteRequests.add(request);
      if (favoritesResponse != null) return await favoritesResponse!(request);
      return handleFavorites(request);
    default:
      throw StateError(
        'Unexpected test request: ${request.method} ${request.url}',
      );
  }
});

http.Response handleViewings(http.Request request) {
  final idFilter = request.url.queryParameters['id'];
  final renterFilter = request.url.queryParameters['renter_id'];
  final statusFilter = request.url.queryParameters['status'];
  final rows = [
    for (final row in demoViewings)
      if ((idFilter == null || 'eq.${row['id']}' == idFilter) &&
          (renterFilter == null || 'eq.${row['renter_id']}' == renterFilter) &&
          (statusFilter == null || 'eq.${row['status']}' == statusFilter))
        row,
  ];
  switch (request.method) {
    case 'GET':
      return jsonResponse(rows);
    case 'POST':
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final property = samplePropertyMaps.firstWhere(
        (property) => property['id'] == body['property_id'],
      );
      final viewing = {
        'id': nextDemoViewingId++,
        ...body,
        'created_at': '2026-11-18T10:00:00',
        'properties': property,
      };
      demoViewings.insert(0, viewing);
      return jsonResponse([viewing], 201);
    case 'PATCH':
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      for (final row in rows) {
        row.addAll(body);
      }
      return jsonResponse(rows);
    case 'DELETE':
      demoViewings.removeWhere(
        (row) => rows.any((deleted) => identical(row, deleted)),
      );
      return jsonResponse(rows);
    default:
      throw StateError('Unexpected viewing method: ${request.method}');
  }
}

http.Response handleFavorites(http.Request request) {
  switch (request.method) {
    case 'GET':
      return jsonResponse(favoriteRows);
    case 'POST':
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final property = samplePropertyMaps.firstWhere(
        (property) => property['id'] == body['property_id'],
      );
      favoriteRows.add({
        'id': body['property_id'],
        ...body,
        'properties': property,
      });
      return jsonResponse([favoriteRows.last], 201);
    case 'DELETE':
      final filter = request.url.queryParameters['property_id'];
      favoriteRows.removeWhere((row) => 'eq.${row['property_id']}' == filter);
      return http.Response('', 204);
    default:
      throw StateError('Unexpected favorite method: ${request.method}');
  }
}
