import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:roomstay_mobile/data/user_session.dart';

import 'test_backend.dart';

final managerProperties = <Map<String, dynamic>>[];
final managerViewings = <Map<String, dynamic>>[];
String managerRole = 'partner';

void resetManagerBackend() {
  resetTestBackend();
  managerRole = 'partner';
  UserSession.role = managerRole;
  managerProperties.clear();
  for (final id in [101, 102, 999]) {
    managerProperties.add({
      'id': id,
      'partner_id': id == 999 ? 'other-manager' : 'test-user-id',
      'name': id == 999 ? 'Unrelated property' : 'Manager property $id',
      'location': 'Bangkok',
      'type': 'Apartment',
      'monthly_rent': 8000,
      'bedrooms': 1,
      'available': true,
      'pet_friendly': false,
      'near_university': true,
      'near_transit': false,
      'facilities': ['Wi-Fi'],
      'description': 'A comfortable room.',
      'image_url': null,
    });
  }
  managerViewings.clear();
  for (final id in [101, 102, 999]) {
    managerViewings.add({
      'id': id,
      'property_id': id,
      'renter_id': id == 999 ? 'unrelated-renter' : 'renter-one',
      'viewing_date': '2026-12-01',
      'viewing_time': '10:30:00',
      'message': 'Please confirm the time.',
      'status': 'Pending',
      'created_at': '2026-11-19T10:00:00',
      'properties': {
        'name': id == 999 ? 'Unrelated property' : 'Manager property $id',
      },
    });
  }
  apiResponse = managerResponse;
}

bool matchesFilter(Object? value, String? filter) {
  if (filter == null) return true;
  if (filter.startsWith('eq.')) return value.toString() == filter.substring(3);
  if (filter.startsWith('in.(')) {
    return filter
        .substring(4, filter.length - 1)
        .split(',')
        .contains(value.toString());
  }
  throw StateError('Unexpected test filter: $filter');
}

http.Response? managerResponse(http.Request request) {
  final query = request.url.queryParameters;
  if (request.url.path == '/rest/v1/profiles') {
    final profiles = [
      {
        'id': 'test-user-id',
        'full_name': 'RoomStay Manager',
        'email': 'manager@example.com',
        'role': managerRole,
      },
      {
        'id': 'renter-one',
        'full_name': 'Student Renter',
        'email': 'renter@example.com',
        'role': 'renter',
      },
      {
        'id': 'unrelated-renter',
        'full_name': 'Private renter',
        'email': 'private@example.com',
        'role': 'renter',
      },
    ];
    return jsonResponse([
      for (final profile in profiles)
        if (matchesFilter(profile['id'], query['id'])) profile,
    ]);
  }
  if (request.url.path == '/rest/v1/properties') {
    final rows = [
      for (final row in managerProperties)
        if (matchesFilter(row['id'], query['id']) &&
            matchesFilter(row['partner_id'], query['partner_id']))
          row,
    ];
    if (request.method == 'GET') return jsonResponse(rows);
    if (request.method == 'POST') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final row = {'id': 1000 + managerProperties.length, ...body};
      managerProperties.insert(0, row);
      return jsonResponse([row], 201);
    }
    if (request.method == 'PATCH') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      for (final row in rows) {
        row.addAll(body);
      }
      return jsonResponse(rows);
    }
    if (request.method == 'DELETE') {
      managerProperties.removeWhere(rows.contains);
      return jsonResponse(rows);
    }
  }
  if (request.url.path == '/rest/v1/viewings') {
    final rows = [
      for (final row in managerViewings)
        if (matchesFilter(row['id'], query['id']) &&
            matchesFilter(row['property_id'], query['property_id']) &&
            matchesFilter(row['status'], query['status']) &&
            matchesFilter(row['renter_id'], query['renter_id']))
          row,
    ];
    if (request.method == 'GET') return jsonResponse(rows);
    if (request.method == 'PATCH') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      for (final row in rows) {
        row.addAll(body);
      }
      return jsonResponse(rows);
    }
  }
  return null;
}
