import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomstay_mobile/data/user_session.dart';
import 'package:roomstay_mobile/data/viewing_helpers.dart';
import 'package:roomstay_mobile/models/property.dart';
import 'package:roomstay_mobile/screens/home_screen.dart';
import 'package:roomstay_mobile/screens/main_screen.dart';
import 'package:roomstay_mobile/screens/my_viewings_screen.dart';
import 'package:roomstay_mobile/screens/request_viewing_screen.dart';
import 'package:roomstay_mobile/screens/search_screen.dart';
import 'package:roomstay_mobile/screens/update_viewing_screen.dart';
import 'package:roomstay_mobile/theme/app_theme.dart';
import 'package:roomstay_mobile/widgets/property_card.dart';

import 'fixtures/sample_properties.dart';
import 'support/test_backend.dart';

Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.lightTheme, home: screen),
  );
  await tester.pumpAndSettle();
}

Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

List<int> visibleRents(WidgetTester tester) {
  return tester
      .widgetList<PropertyCard>(find.byType(PropertyCard))
      .map((card) => card.property.monthlyRent)
      .toList();
}

void main() {
  setUp(resetTestBackend);
  tearDown(UserSession.clear);

  testWithApi('Advanced Pet friendly filter uses the boolean field', (
    tester,
  ) async {
    final maps = [
      {
        'id': 11,
        'name': 'Pet Condo Low',
        'location': 'Ari',
        'type': 'Condo',
        'monthly_rent': 5800,
        'bedrooms': 1,
        'available': true,
        'pet_friendly': true,
        'near_university': false,
        'near_transit': true,
        'facilities': <String>[],
      },
      {
        'id': 12,
        'name': 'Pet Condo High',
        'location': 'Ari',
        'type': 'Condo',
        'monthly_rent': 12000,
        'bedrooms': 2,
        'available': true,
        'pet_friendly': true,
        'near_university': false,
        'near_transit': true,
        'facilities': <String>[],
      },
      {
        'id': 13,
        'name': 'Facility Text Only',
        'location': 'Ari',
        'type': 'Condo',
        'monthly_rent': 9500,
        'bedrooms': 1,
        'available': true,
        'pet_friendly': false,
        'near_university': false,
        'near_transit': true,
        'facilities': ['Pet friendly'],
      },
      {
        'id': 14,
        'name': 'Pet House',
        'location': 'Ari',
        'type': 'House',
        'monthly_rent': 18000,
        'bedrooms': 3,
        'available': true,
        'pet_friendly': true,
        'near_university': false,
        'near_transit': true,
        'facilities': <String>[],
      },
    ];
    apiResponse = (request) =>
        request.url.path == '/rest/v1/properties' ? jsonResponse(maps) : null;

    await pumpScreen(
      tester,
      SearchScreen(
        favoriteIds: const {},
        onFavoriteToggle: (_) {},
        onPropertySelected: (_) {},
      ),
    );

    expect(find.text('4 rooms found'), findsOneWidget);

    await tester.tap(find.text('More Filters'));
    await tester.pumpAndSettle();
    final petFilter = find.widgetWithText(ChoiceChip, 'Pet friendly');
    await tester.ensureVisible(petFilter);
    await tester.pumpAndSettle();
    await tester.tap(petFilter);
    final condoFilter = find.widgetWithText(ChoiceChip, 'Condo');
    await tester.ensureVisible(condoFilter);
    await tester.pumpAndSettle();
    await tester.tap(condoFilter);
    await tester.tap(find.text('Show Results'));
    await tester.pumpAndSettle();

    expect(find.text('2 rooms found'), findsOneWidget);
    expect(find.text('Pet Condo Low'), findsOneWidget);
    expect(find.text('Pet Condo High'), findsOneWidget);
    expect(find.text('Facility Text Only'), findsNothing);
    expect(find.text('Pet House'), findsNothing);

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Price: Low to High').last);
    await tester.pumpAndSettle();

    expect(visibleRents(tester), [5800, 12000]);

    await tester.tap(find.widgetWithText(TextButton, 'Reset'));
    await tester.pump();

    expect(find.text('4 rooms found'), findsOneWidget);
  });

  testWithApi('Rent sorting is numeric in both directions', (tester) async {
    await pumpScreen(
      tester,
      SearchScreen(
        favoriteIds: const {},
        onFavoriteToggle: (_) {},
        onPropertySelected: (_) {},
      ),
    );

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Price: Low to High').last);
    await tester.pumpAndSettle();

    expect(visibleRents(tester), [
      4800,
      5800,
      6500,
      9500,
      12000,
      15000,
      18000,
      20000,
    ]);

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Price: High to Low').last);
    await tester.pumpAndSettle();

    expect(visibleRents(tester), [
      20000,
      18000,
      15000,
      12000,
      9500,
      6500,
      5800,
      4800,
    ]);
  });

  testWithApi('Home requests recently added properties newest first', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      HomeScreen(
        onSearchRequested: () {},
        favoriteIds: const {},
        onFavoriteToggle: (_) {},
        onPropertySelected: (_) {},
      ),
    );

    final request = apiRequests.firstWhere(
      (request) => request.url.path == '/rest/v1/properties',
    );

    expect(request.url.queryParameters['order'], 'id.desc');
  });

  testWithApi('Pending viewing is the only row with edit and cancel actions', (
    tester,
  ) async {
    await pumpScreen(tester, const MyViewingsScreen());

    final approvedCard = find.ancestor(
      of: find.text('Modern Condo near BTS'),
      matching: find.byType(Card),
    );
    final cancelledCard = find.ancestor(
      of: find.text('Student Room near University'),
      matching: find.byType(Card),
    );

    for (final card in [approvedCard, cancelledCard]) {
      expect(
        find.descendant(of: card, matching: find.text('Edit')),
        findsNothing,
      );
      expect(
        find.descendant(of: card, matching: find.text('Cancel')),
        findsNothing,
      );
    }
  });

  testWithApi('Approved viewing cannot be opened for editing', (tester) async {
    await pumpScreen(tester, const UpdateViewingScreen(id: 2));

    expect(find.text(pendingViewingModificationMessage), findsOneWidget);
    expect(find.byType(Form), findsNothing);
    expect(apiRequests.where((request) => request.method == 'PATCH'), isEmpty);
  });

  testWithApi('Editing a viewing into the past is rejected before PATCH', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      UpdateViewingScreen(id: 1, now: () => DateTime(2031, 1, 1, 9)),
    );

    final update = find.widgetWithText(ElevatedButton, 'Update Viewing');
    await tester.ensureVisible(update);
    await tester.tap(update);
    await tester.pump();

    expect(find.text(futureViewingTimeMessage), findsOneWidget);
    expect(apiRequests.where((request) => request.method == 'PATCH'), isEmpty);
  });

  testWithApi('Requesting a viewing at the current time is rejected', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      RequestViewingScreen(
        property: sampleProperties.first,
        now: () => DateTime(2030, 5, 15, 15, 30),
      ),
    );

    await tester.tap(find.byType(TextFormField).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextFormField).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final submit = find.widgetWithText(ElevatedButton, 'Submit Request');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(find.text(futureViewingTimeMessage), findsOneWidget);
    expect(apiRequests.where((request) => request.method == 'POST'), isEmpty);
  });

  testWithApi('Favorite control has a 48px target and no fake rating', (
    tester,
  ) async {
    final property = Property.fromSupabase({
      ...samplePropertyMaps.first,
      'rating': 0,
    });

    await pumpScreen(
      tester,
      Scaffold(
        body: PropertyCard(
          property: property,
          isFavorite: false,
          onFavoritePressed: () {},
        ),
      ),
    );

    expect(find.byTooltip('Save to favorites'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('favorite-property-button'))),
      const Size(48, 48),
    );
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('0.0'), findsNothing);
  });

  testWithApi('Renter screens avoid overflow at 2x text', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const MainScreen()),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -1800),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tapTab(tester, 'Search');
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tapTab(tester, 'My Viewings');
    expect(tester.takeException(), isNull);

    await tapTab(tester, 'Profile');
    expect(tester.takeException(), isNull);

    await pumpScreen(
      tester,
      RequestViewingScreen(
        property: sampleProperties.first,
        now: () => DateTime(2030, 5, 15, 15, 30),
      ),
    );
    expect(tester.takeException(), isNull);

    await pumpScreen(tester, const UpdateViewingScreen(id: 1));
    expect(tester.takeException(), isNull);
  });

  test('Viewing helpers enforce status and future local times', () {
    const now = TimeOfDay(hour: 10, minute: 30);

    expect(isPendingViewingStatus('Pending'), isTrue);
    expect(isPendingViewingStatus('Approved'), isFalse);
    expect(isPendingViewingStatus(null), isFalse);
    expect(
      isFutureViewingDateTime(
        DateTime(2026, 11, 21),
        now,
        now: DateTime(2026, 11, 21, 10, 30),
      ),
      isFalse,
    );
    expect(
      isFutureViewingDateTime(
        DateTime(2026, 11, 21),
        const TimeOfDay(hour: 10, minute: 31),
        now: DateTime(2026, 11, 21, 10, 30),
      ),
      isTrue,
    );
    expect(
      isFutureViewingDateTime(
        DateTime(2026, 11, 20),
        const TimeOfDay(hour: 23, minute: 59),
        now: DateTime(2026, 11, 21, 10, 30),
      ),
      isFalse,
    );
    expect(
      isFutureViewingDateTime(
        DateTime(2026, 11, 22),
        const TimeOfDay(hour: 0, minute: 1),
        now: DateTime(2026, 11, 21, 10, 30),
      ),
      isTrue,
    );
  });
}
