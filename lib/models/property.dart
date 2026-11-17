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
  });

  final int id;
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

  String get priceLabel => '${formatBaht(monthlyRent)} / month';

  String get bedroomLabel => bedrooms == 0 ? 'Studio' : '$bedrooms';
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
