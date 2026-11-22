import 'package:flutter_test/flutter_test.dart';

import 'package:roomstay_mobile/models/property.dart';

void main() {
  test('Property.fromSupabase maps database field names', () {
    final property = Property.fromSupabase({
      'id': 42,
      'partner_id': '2d89bf13-15f4-413e-8fe5-ec512ee5ef4a',
      'name': 'Sunlit Apartment near Ari BTS',
      'location': 'Ari, Bangkok',
      'type': 'Apartment',
      'monthly_rent': 12000,
      'bedrooms': 2,
      'available': true,
      'pet_friendly': true,
      'near_university': false,
      'near_transit': true,
      'facilities': ['Wi-Fi', 'Parking'],
      'description': 'A sunny apartment near the BTS.',
      'image_url': 'https://example.com/property.jpg',
    });

    expect(property.id, 42);

    expect(property.partnerId, '2d89bf13-15f4-413e-8fe5-ec512ee5ef4a');

    expect(property.name, 'Sunlit Apartment near Ari BTS');

    expect(property.location, 'Ari, Bangkok');

    expect(property.type, 'Apartment');

    expect(property.monthlyRent, 12000);

    expect(property.bedrooms, 2);

    expect(property.available, isTrue);

    expect(property.petFriendly, isTrue);

    expect(property.nearUniversity, isFalse);

    expect(property.nearTransit, isTrue);

    expect(property.facilities, ['Wi-Fi', 'Parking']);

    expect(property.description, 'A sunny apartment near the BTS.');

    expect(property.image, 'https://example.com/property.jpg');
  });

  test('Property.fromSupabase handles null image and empty facilities', () {
    final property = Property.fromSupabase({
      'id': 8,
      'partner_id': null,
      'name': 'Basic Room',
      'location': 'Bangkok',
      'type': 'Dormitory',
      'monthly_rent': 4800,
      'bedrooms': 1,
      'available': false,
      'facilities': null,
      'description': null,
      'image_url': null,
    });

    expect(property.partnerId, '');

    expect(property.available, isFalse);

    expect(property.facilities, isEmpty);

    expect(property.description, '');

    expect(property.image, '');
  });
}
