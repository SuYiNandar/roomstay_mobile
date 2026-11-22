import 'package:flutter/material.dart';

const String pendingViewingModificationMessage =
    'Only pending viewing requests can be modified.';
const String futureViewingTimeMessage = 'Please select a future date and time.';

bool isPendingViewingStatus(dynamic status) => status?.toString() == 'Pending';

DateTime? combineViewingDateTime(DateTime? date, TimeOfDay? time) {
  if (date == null || time == null) return null;

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

bool isFutureViewingDateTime(DateTime date, TimeOfDay time, {DateTime? now}) {
  final viewingDateTime = combineViewingDateTime(date, time);
  if (viewingDateTime == null) return false;

  return viewingDateTime.isAfter(now ?? DateTime.now());
}

String supabaseDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String supabaseTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute:00';
}

DateTime? parseViewingDate(dynamic value) {
  if (value == null) return null;

  final text = value.toString().split('T').first;
  final parts = text.split('-');

  if (parts.length != 3) return null;

  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);

  if (year == null || month == null || day == null) return null;

  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;
  return date;
}

TimeOfDay? parseViewingTime(dynamic value) {
  if (value == null) return null;

  final parts = value.toString().split(':');

  if (parts.length < 2) return null;

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);

  if (hour == null ||
      minute == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59) {
    return null;
  }

  return TimeOfDay(hour: hour, minute: minute);
}

String displayViewingDate(dynamic value) {
  final date = parseViewingDate(value);

  if (date == null) return value?.toString() ?? '';

  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String displayViewingTime(dynamic value) {
  final time = parseViewingTime(value);

  if (time == null) return value?.toString() ?? '';

  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

String viewingPropertyName(Map<String, dynamic> viewing) {
  final property = viewing['properties'];

  if (property is Map && property['name'] != null) {
    return property['name'].toString();
  }

  if (property is List && property.isNotEmpty && property.first is Map) {
    final first = property.first as Map;
    if (first['name'] != null) {
      return first['name'].toString();
    }
  }

  final propertyId = viewing['property_id'];
  return propertyId == null ? 'Property' : 'Property #$propertyId';
}

String viewingPropertyImage(Map<String, dynamic> viewing) {
  final property = viewing['properties'];

  if (property is Map) {
    return property['image_url']?.toString() ?? '';
  }

  if (property is List && property.isNotEmpty && property.first is Map) {
    return (property.first as Map)['image_url']?.toString() ?? '';
  }

  return '';
}
