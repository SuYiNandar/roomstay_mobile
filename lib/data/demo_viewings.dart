final List<Map<String, dynamic>> demoViewings = createDemoViewings();

int nextDemoViewingId = 4;

List<Map<String, dynamic>> createDemoViewings() {
  return [
    {
      'id': 1,
      'propertyId': 1,
      'propertyName': 'Cozy Studio near RSU',
      'userId': 1,
      'viewingDate': '20/11/2026',
      'viewingTime': '10:00 AM',
      'message': 'I would like to see the room.',
      'status': 'Pending',
    },
    {
      'id': 2,
      'propertyId': 2,
      'propertyName': 'Modern Condo near BTS',
      'userId': 1,
      'viewingDate': '22/11/2026',
      'viewingTime': '2:30 PM',
      'message': '',
      'status': 'Approved',
    },
    {
      'id': 3,
      'propertyId': 3,
      'propertyName': 'Student Room near University',
      'userId': 1,
      'viewingDate': '10/11/2026',
      'viewingTime': '9:00 AM',
      'message': '',
      'status': 'Cancelled',
    },
  ];
}

void resetDemoViewings() {
  demoViewings
    ..clear()
    ..addAll(createDemoViewings());
  nextDemoViewingId = 4;
}
