final List<Map<String, dynamic>> demoViewings = createDemoViewings();

int nextDemoViewingId = 4;

List<Map<String, dynamic>> createDemoViewings() {
  return [
    {
      'id': 1,
      'property_id': 1,
      'renter_id': 'test-user-id',
      'viewing_date': '2030-11-20',
      'viewing_time': '10:00:00',
      'message': 'I would like to see the room.',
      'status': 'Pending',
      'created_at': '2026-11-18T09:00:00',
      'properties': {
        'name': 'Cozy Studio near RSU',
        'location': 'Rangsit',
        'image_url': '',
      },
    },
    {
      'id': 2,
      'property_id': 2,
      'renter_id': 'test-user-id',
      'viewing_date': '2026-11-22',
      'viewing_time': '14:30:00',
      'message': '',
      'status': 'Approved',
      'created_at': '2026-11-18T08:30:00',
      'properties': {
        'name': 'Modern Condo near BTS',
        'location': 'Bangkok',
        'image_url': '',
      },
    },
    {
      'id': 3,
      'property_id': 3,
      'renter_id': 'test-user-id',
      'viewing_date': '2026-11-10',
      'viewing_time': '09:00:00',
      'message': '',
      'status': 'Cancelled',
      'created_at': '2026-11-17T15:00:00',
      'properties': {
        'name': 'Student Room near University',
        'location': 'Bang Khen',
        'image_url': '',
      },
    },
  ];
}

void resetDemoViewings() {
  demoViewings
    ..clear()
    ..addAll(createDemoViewings());
  nextDemoViewingId = 4;
}
