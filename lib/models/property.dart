class Property {
  const Property({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.monthlyRent,
    required this.bedrooms,
    required this.bathrooms,
    required this.sizeSqm,
    required this.available,
    required this.petFriendly,
    required this.nearUniversity,
    required this.nearTransit,
    required this.facilities,
    required this.description,
    required this.image,
    required this.rating,
    this.partnerId = '',
  });

  final int id;
  final String partnerId;
  final String name;
  final String location;
  final String type;
  final int monthlyRent;
  final int bedrooms;
  final int bathrooms;
  final int sizeSqm;
  final bool available;
  final bool petFriendly;
  final bool nearUniversity;
  final bool nearTransit;
  final List<String> facilities;
  final String description;
  final String image;
  final double rating;

  factory Property.fromSupabase(Map<String, dynamic> data) {
    return Property(
      id: _readInt(data['id']),
      partnerId: data['partner_id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      type: data['type']?.toString() ?? '',
      monthlyRent: _readInt(data['monthly_rent']),
      bedrooms: _readInt(data['bedrooms']),
      bathrooms: _readInt(data['bathrooms']),
      sizeSqm: _readInt(data['size_sqm']),
      available: data['available'] == true,
      petFriendly: data['pet_friendly'] == true,
      nearUniversity: data['near_university'] == true,
      nearTransit: data['near_transit'] == true,
      facilities: _readFacilities(data['facilities']),
      description: data['description']?.toString() ?? '',
      image: data['image_url']?.toString() ?? '',
      rating: _readDouble(data['rating']),
    );
  }

  String get priceLabel => '${formatBaht(monthlyRent)} / month';

  String get bedroomLabel {
    if (bedrooms == 0) {
      return 'Studio';
    }

    return '$bedrooms';
  }
}

int _readInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _readDouble(dynamic value) {
  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}

List<String> _readFacilities(dynamic value) {
  if (value is List) {
    final List<String> facilities = [];

    for (final item in value) {
      facilities.add(item.toString());
    }

    return facilities;
  }

  return [];
}

String formatBaht(int amount) {
  final digits = amount.toString();
  final formatted = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      formatted.write(',');
    }

    formatted.write(digits[index]);
  }

  return '฿$formatted';
}
