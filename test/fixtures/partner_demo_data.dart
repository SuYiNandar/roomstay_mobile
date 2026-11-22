final List<Map<String, dynamic>> partnerProperties = createPartnerProperties();
final List<Map<String, dynamic>> partnerViewingRequests =
    createPartnerViewingRequests();

int nextPartnerPropertyId = 5;

List<Map<String, dynamic>> createPartnerProperties() {
  return [
    {
      'id': 1,
      'name': 'Cozy Studio near RSU',
      'location': 'Rangsit, Pathum Thani',
      'type': 'Apartment',
      'monthlyRent': 6500,
      'bedrooms': 0,
      'description':
          'A bright studio apartment close to Rangsit University with a private balcony.',
      'available': true,
    },
    {
      'id': 2,
      'name': 'Modern Condo near BTS',
      'location': 'Sukhumvit, Bangkok',
      'type': 'Condo',
      'monthlyRent': 9500,
      'bedrooms': 1,
      'description':
          'A modern one-bedroom condo within walking distance of the BTS.',
      'available': true,
    },
    {
      'id': 3,
      'name': 'Family House in Bang Khen',
      'location': 'Bang Khen, Bangkok',
      'type': 'House',
      'monthlyRent': 18000,
      'bedrooms': 3,
      'description':
          'A comfortable family house with three bedrooms and a private garden.',
      'available': false,
    },
    {
      'id': 4,
      'name': 'Budget Dormitory near BTS',
      'location': 'Thon Buri, Bangkok',
      'type': 'Dormitory',
      'monthlyRent': 4800,
      'bedrooms': 1,
      'description':
          'An affordable dormitory room with the essentials included.',
      'available': false,
    },
  ];
}

List<Map<String, dynamic>> createPartnerViewingRequests() {
  return [
    {
      'id': 1,
      'renterName': 'Su Yi Nandar',
      'propertyName': 'Cozy Studio near RSU',
      'viewingDate': '20/11/2026',
      'viewingTime': '10:00 AM',
      'message': 'I would like to see the room.',
      'status': 'Pending',
    },
    {
      'id': 2,
      'renterName': 'Aung Aung',
      'propertyName': 'Modern Condo near BTS',
      'viewingDate': '22/11/2026',
      'viewingTime': '2:30 PM',
      'message': 'Is the condo available this weekend?',
      'status': 'Pending',
    },
    {
      'id': 3,
      'renterName': 'Mya Mya',
      'propertyName': 'Family House in Bang Khen',
      'viewingDate': '25/11/2026',
      'viewingTime': '4:00 PM',
      'message': 'I would like to bring my family.',
      'status': 'Pending',
    },
    {
      'id': 4,
      'renterName': 'Ko Ko',
      'propertyName': 'Budget Dormitory near BTS',
      'viewingDate': '18/11/2026',
      'viewingTime': '9:00 AM',
      'message': '',
      'status': 'Approved',
    },
    {
      'id': 5,
      'renterName': 'Hla Hla',
      'propertyName': 'Cozy Studio near RSU',
      'viewingDate': '15/11/2026',
      'viewingTime': '1:00 PM',
      'message': 'Please confirm the available time.',
      'status': 'Rejected',
    },
    {
      'id': 6,
      'renterName': 'Zin Zin',
      'propertyName': 'Modern Condo near BTS',
      'viewingDate': '28/11/2026',
      'viewingTime': '11:00 AM',
      'message': '',
      'status': 'Approved',
    },
    {
      'id': 7,
      'renterName': 'Thu Thu',
      'propertyName': 'Family House in Bang Khen',
      'viewingDate': '29/11/2026',
      'viewingTime': '3:30 PM',
      'message': 'I am available in the afternoon.',
      'status': 'Rejected',
    },
    {
      'id': 8,
      'renterName': 'Nandar',
      'propertyName': 'Budget Dormitory near BTS',
      'viewingDate': '30/11/2026',
      'viewingTime': '5:00 PM',
      'message': '',
      'status': 'Approved',
    },
  ];
}

void resetPartnerDemoData() {
  partnerProperties
    ..clear()
    ..addAll(createPartnerProperties());

  partnerViewingRequests
    ..clear()
    ..addAll(createPartnerViewingRequests());

  nextPartnerPropertyId = 5;
}
