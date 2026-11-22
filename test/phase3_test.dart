import 'support/test_backend.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/sample_properties.dart';
import 'package:roomstay_mobile/screens/main_screen.dart';
import 'package:roomstay_mobile/screens/room_detail_screen.dart';
import 'package:roomstay_mobile/theme/app_theme.dart';
import 'package:roomstay_mobile/widgets/property_card.dart';

Future<void> pumpSearchScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.lightTheme, home: const MainScreen()),
  );

  await tester.pumpAndSettle();

  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Search'),
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> pumpRoomDetail(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: RoomDetailScreen(
        id: sampleProperties.first.id,
        isFavorite: false,
        onFavoriteToggle: () async => true,
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    resetTestBackend();
  });

  testWithApi('Search filters by keyword and shows an empty state', (
    WidgetTester tester,
  ) async {
    await pumpSearchScreen(tester);

    expect(find.text('8 rooms found'), findsOneWidget);

    expect(find.byType(PropertyCard), findsNWidgets(8));

    await tester.enterText(find.byType(TextField), 'RSU');

    await tester.pump();

    expect(find.text('1 room found'), findsOneWidget);

    expect(find.text('Cozy Studio near RSU'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzzz');

    await tester.pump();

    expect(find.text('No rooms found'), findsOneWidget);

    expect(find.text('Try changing your search or filters.'), findsOneWidget);

    await tester.ensureVisible(find.text('Reset Filters'));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Reset Filters'));

    await tester.pump();

    expect(find.text('8 rooms found'), findsOneWidget);
  });

  testWithApi('Quick filters and sorting update the results', (
    WidgetTester tester,
  ) async {
    await pumpSearchScreen(tester);

    await tester.tap(find.widgetWithText(FilterChip, 'Pet friendly'));

    await tester.pump();

    expect(find.text('3 rooms found'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Pet friendly'));

    await tester.pump();

    await tester.tap(find.byType(DropdownButton<String>));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Price: Low to High').last);

    await tester.pumpAndSettle();

    final lowToHigh = tester
        .widgetList<PropertyCard>(find.byType(PropertyCard))
        .toList();

    expect(lowToHigh.first.property.monthlyRent, 4800);

    await tester.tap(find.byType(DropdownButton<String>));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Price: High to Low').last);

    await tester.pumpAndSettle();

    final highToLow = tester
        .widgetList<PropertyCard>(find.byType(PropertyCard))
        .toList();

    expect(highToLow.first.property.monthlyRent, 20000);
  });

  testWithApi('More filters apply and reset from the bottom sheet', (
    WidgetTester tester,
  ) async {
    await pumpSearchScreen(tester);

    await tester.tap(find.text('More Filters'));

    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Dormitory'));

    await tester.pump();

    await tester.tap(find.text('Show Results'));

    await tester.pumpAndSettle();

    expect(find.text('2 rooms found'), findsOneWidget);

    await tester.tap(find.text('More Filters'));

    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Reset'));

    await tester.pump();

    await tester.tap(find.text('Show Results'));

    await tester.pumpAndSettle();

    expect(find.text('8 rooms found'), findsOneWidget);
  });

  testWithApi('Search result opens the room detail screen', (
    WidgetTester tester,
  ) async {
    await pumpSearchScreen(tester);

    await tester.tap(find.text('Cozy Studio near RSU'));

    await tester.pumpAndSettle();

    expect(find.byType(RoomDetailScreen), findsOneWidget);

    expect(find.text('Description'), findsOneWidget);

    expect(find.text('Facilities'), findsOneWidget);

    expect(find.text('Property Manager'), findsOneWidget);
  });

  testWithApi('Home property card opens the room detail screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const MainScreen()),
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Cozy Studio near RSU'));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Cozy Studio near RSU'));

    await tester.pumpAndSettle();

    expect(find.byType(RoomDetailScreen), findsOneWidget);

    expect(find.text('Description'), findsOneWidget);

    expect(find.text('Property Manager'), findsOneWidget);
  });

  testWithApi('Room detail toggles favorite and shows core sections', (
    WidgetTester tester,
  ) async {
    await pumpRoomDetail(tester);

    expect(find.text('Cozy Studio near RSU'), findsOneWidget);

    expect(find.text('฿6,500 / month'), findsOneWidget);

    expect(find.text('Available'), findsOneWidget);

    expect(find.text('Description'), findsOneWidget);

    expect(find.text('Facilities'), findsOneWidget);

    expect(find.text('Property Manager'), findsOneWidget);

    expect(find.text('House Rules'), findsNothing);

    expect(find.text('Property Partner'), findsNothing);

    expect(find.text('Reviews'), findsNothing);

    expect(find.byIcon(Icons.favorite_border), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.favorite_border).first);

    await tester.pump();

    expect(find.byIcon(Icons.favorite), findsNWidgets(2));
  });

  testWithApi('Unavailable property disables viewing', (
    WidgetTester tester,
  ) async {
    final unavailable = sampleProperties.firstWhere(
      (property) => !property.available,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: RoomDetailScreen(
          id: unavailable.id,
          isFavorite: false,
          onFavoriteToggle: () async => true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Currently unavailable'), findsOneWidget);

    final viewingButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Request Viewing'),
    );

    expect(viewingButton.onPressed, isNull);

    expect(
      find.widgetWithText(ElevatedButton, 'Request Booking'),
      findsNothing,
    );

    expect(find.widgetWithText(OutlinedButton, 'Message'), findsNothing);
  });

  testWithApi('Viewing form validates and submits successfully', (
    WidgetTester tester,
  ) async {
    await pumpRoomDetail(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Request Viewing'));

    await tester.pumpAndSettle();

    expect(find.text('Schedule a viewing'), findsOneWidget);

    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Submit Request'),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Request'));

    await tester.pump();

    expect(find.text('Please select a date'), findsOneWidget);

    expect(find.text('Please select a time'), findsOneWidget);

    await tester.tap(find.byType(TextFormField).at(0));

    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));

    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextFormField).at(1));

    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));

    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Submit Request'),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Request'));

    await tester.pump();

    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Viewing request submitted successfully.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 5));

    await tester.pumpAndSettle();
  });

  testWithApi('Search and room detail render on a mobile viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);

    tester.view.devicePixelRatio = 1.0;

    addTearDown(tester.view.resetPhysicalSize);

    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpSearchScreen(tester);

    expect(tester.takeException(), isNull);

    await tester.tap(find.text('More Filters'));

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Show Results'));

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Cozy Studio near RSU'));

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -1600),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    expect(find.text('Property Manager'), findsOneWidget);

    expect(find.text('Reviews'), findsNothing);
  });
}
