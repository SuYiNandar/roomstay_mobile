import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roomstay_mobile/data/viewing_helpers.dart';

void main() {
  test('Viewing date and time are converted to database-safe values', () {
    expect(supabaseDate(DateTime(2026, 11, 25)), '2026-11-25');
    expect(supabaseTime(const TimeOfDay(hour: 14, minute: 30)), '14:30:00');
  });

  test('Database date and time are parsed and displayed for the UI', () {
    expect(parseViewingDate('2026-11-25'), DateTime(2026, 11, 25));
    expect(parseViewingTime('14:30:00'), const TimeOfDay(hour: 14, minute: 30));

    expect(displayViewingDate('2026-11-25'), '25/11/2026');
    expect(displayViewingDate('2026-11-25T10:00:00'), '25/11/2026');
    expect(displayViewingTime('14:30:00'), '2:30 PM');
    expect(displayViewingTime('09:05:00'), '9:05 AM');
    expect(displayViewingTime('00:15:00'), '12:15 AM');
  });

  test('Property name is read from a nested relationship object', () {
    final viewing = {
      'id': 1,
      'property_id': 7,
      'properties': {
        'name': 'Sunlit Apartment near Ari BTS',
        'location': 'Ari',
        'image_url': 'https://example.com/room.jpg',
      },
    };

    expect(viewingPropertyName(viewing), 'Sunlit Apartment near Ari BTS');
    expect(viewingPropertyImage(viewing), 'https://example.com/room.jpg');
  });

  test('Property name handles a list relationship and a missing relation', () {
    final nestedList = {
      'property_id': 8,
      'properties': [
        {'name': 'Student Room near University'},
      ],
    };

    expect(viewingPropertyName(nestedList), 'Student Room near University');

    expect(viewingPropertyName({'property_id': 9}), 'Property #9');
    expect(viewingPropertyImage({'property_id': 9}), '');
  });
}
