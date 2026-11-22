Map<String, dynamic>? favoritePropertyMap(dynamic row) {
  if (row is! Map) return null;

  final property = row['properties'];

  if (property is Map) {
    return Map<String, dynamic>.from(property);
  }

  if (property is List && property.isNotEmpty && property.first is Map) {
    return Map<String, dynamic>.from(property.first as Map);
  }

  return null;
}

Set<int> parseFavoritePropertyIds(dynamic rows) {
  final ids = <int>{};

  if (rows is! List) return ids;

  for (final row in rows) {
    if (row is! Map) continue;

    final value = row['property_id'];
    final id = value is int ? value : int.tryParse(value?.toString() ?? '');

    if (id != null) {
      ids.add(id);
    }
  }

  return ids;
}
