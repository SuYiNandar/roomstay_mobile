import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomstay_mobile/data/user_session.dart';
import 'package:roomstay_mobile/models/property.dart';
import 'package:roomstay_mobile/screens/home_screen.dart';
import 'package:roomstay_mobile/screens/main_screen.dart';
import 'package:roomstay_mobile/screens/search_screen.dart';
import 'package:roomstay_mobile/theme/app_theme.dart';
import 'package:roomstay_mobile/widgets/property_card.dart';

import 'fixtures/sample_properties.dart';
import 'support/test_backend.dart';

Future<void> pumpHome(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.lightTheme, home: const MainScreen()),
  );
  await tester.pumpAndSettle();
}

Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Future<void> openCategory(WidgetTester tester, String label) async {
  final category = find.text(label).last;
  await tester.ensureVisible(category);
  await tester.pumpAndSettle();
  await tester.tap(category);
  await tester.pumpAndSettle();
}

List<Property> visibleProperties(WidgetTester tester) => tester
    .widgetList<PropertyCard>(find.byType(PropertyCard))
    .map((card) => card.property)
    .toList();

void expectResults(WidgetTester tester, Iterable<Property> expected) {
  final ids = expected.map((p) => p.id).toList();
  expect(visibleProperties(tester).map((p) => p.id), unorderedEquals(ids));
  expect(
    find.text(ids.length == 1 ? '1 room found' : '${ids.length} rooms found'),
    findsOneWidget,
  );
}

Future<void> toggleChip(WidgetTester tester, String label) async {
  final chip = find.widgetWithText(FilterChip, label);
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

void main() {
  setUp(resetTestBackend);
  tearDown(UserSession.clear);
  final categories = <String, (String, bool Function(Property))>{
    'Apartments': ('Apartment', (p) => p.type == 'Apartment'),
    'Condos': ('Condo', (p) => p.type == 'Condo'),
    'Houses': ('House', (p) => p.type == 'House'),
    'Dormitories': ('Dormitory', (p) => p.type == 'Dormitory'),
    'Pet friendly': ('Pet friendly', (p) => p.petFriendly),
    'Near University': ('Near University', (p) => p.nearUniversity),
    'Near Transit': ('Near Transit', (p) => p.nearTransit),
  };
  for (final category in categories.entries) {
    testWithApi(
      'Home ${category.key} selects a visible Search chip and correct results',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await pumpHome(tester);
        await openCategory(tester, category.key);
        expect(find.byType(SearchScreen), findsOneWidget);
        expect(find.byType(MainScreen), findsOneWidget);
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          1,
        );
        final chip = find.widgetWithText(FilterChip, category.value.$1);
        expect(tester.widget<FilterChip>(chip).selected, isTrue);
        expect(chip.hitTestable(), findsOneWidget);
        expectResults(tester, sampleProperties.where(category.value.$2));
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final label in ['Pet friendly', 'Near Transit']) {
    testWithApi('Popular search $label uses the same boolean filter', (
      tester,
    ) async {
      await pumpHome(tester);
      final shortcut = find.widgetWithText(ActionChip, label);
      await tester.ensureVisible(shortcut);
      await tester.tap(shortcut);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, label))
            .selected,
        isTrue,
      );
      expectResults(tester, sampleProperties.where(categories[label]!.$2));
    });
  }

  testWithApi(
    'Reset clears Home category and does not reapply on rebuild or tab revisit',
    (tester) async {
      await pumpHome(tester);
      await openCategory(tester, 'Apartments');
      final reset = find.widgetWithText(TextButton, 'Reset');
      await tester.ensureVisible(reset);
      await tester.tap(reset);
      await tester.pumpAndSettle();
      expectResults(tester, sampleProperties);
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'Apartment'))
            .selected,
        isFalse,
      );
      // Favorite completion rebuilds MainScreen; it must not reseed Search.
      final favorite = find.byTooltip('Save to favorites').first;
      await tester.ensureVisible(favorite);
      await tester.tap(favorite);
      await tester.pumpAndSettle();
      expectResults(tester, sampleProperties);
      await tapTab(tester, 'Home');
      await tapTab(tester, 'Search');
      expectResults(tester, sampleProperties);
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'Apartment'))
            .selected,
        isFalse,
      );
    },
  );

  testWithApi(
    'Search tab without a shortcut retains normal manual filtering and text search',
    (tester) async {
      await pumpHome(tester);
      await tapTab(tester, 'Search');
      expectResults(tester, sampleProperties);
      expect(
        tester
            .widgetList<FilterChip>(find.byType(FilterChip))
            .every((c) => !c.selected),
        isTrue,
      );
      await toggleChip(tester, 'Apartment');
      expectResults(
        tester,
        sampleProperties.where((p) => p.type == 'Apartment'),
      );
      await tester.enterText(find.byType(TextField), 'Ari');
      await tester.pumpAndSettle();
      expectResults(
        tester,
        sampleProperties.where(
          (p) => p.type == 'Apartment' && p.location.contains('Ari'),
        ),
      );
    },
  );

  testWithApi(
    'Home Apartment combines with Pet friendly, numeric sorting and deselection',
    (tester) async {
      await pumpHome(tester);
      await openCategory(tester, 'Apartments');
      await toggleChip(tester, 'Pet friendly');
      expectResults(
        tester,
        sampleProperties.where((p) => p.type == 'Apartment' && p.petFriendly),
      );
      await toggleChip(tester, 'Pet friendly');
      final sort = find.byType(DropdownButton<String>);
      await tester.ensureVisible(sort);
      await tester.tap(sort);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Price: High to Low').last);
      await tester.pumpAndSettle();
      final expected =
          sampleProperties.where((p) => p.type == 'Apartment').toList()
            ..sort((a, b) => b.monthlyRent.compareTo(a.monthlyRent));
      expect(
        visibleProperties(tester).map((p) => p.id),
        expected.map((p) => p.id),
      );
      await toggleChip(tester, 'Apartment');
      expectResults(tester, sampleProperties);
    },
  );

  testWithApi(
    'Home category combines with advanced rent, bedrooms, facilities and availability',
    (tester) async {
      await pumpHome(tester);
      await openCategory(tester, 'Apartments');
      final more = find.widgetWithText(OutlinedButton, 'More Filters');
      await tester.ensureVisible(more);
      await tester.tap(more);
      await tester.pumpAndSettle();
      // A maximum and Studio identify the real apartment fixture without changing API calls.
      for (final label in [
        'No minimum',
        formatBaht(10000),
        'Studio',
        'Wi-Fi',
      ]) {
        final choice = find.widgetWithText(ChoiceChip, label).last;
        await tester.ensureVisible(choice);
        await tester.pumpAndSettle();
        await tester.tap(choice);
        await tester.pumpAndSettle();
      }
      await toggleChip(tester, 'Available now');
      await tester.tap(find.text('Show Results'));
      await tester.pumpAndSettle();
      expectResults(
        tester,
        sampleProperties.where(
          (p) =>
              p.type == 'Apartment' &&
              p.monthlyRent <= 10000 &&
              p.bedrooms == 0 &&
              p.available &&
              p.facilities.contains('Wi-Fi'),
        ),
      );
    },
  );

  testWithApi(
    'Category with no matches finishes loading and Reset Filters restores rows',
    (tester) async {
      apiResponse = (request) => request.url.path == '/rest/v1/properties'
          ? jsonResponse(
              samplePropertyMaps
                  .where((p) => p['type'] != 'Apartment')
                  .toList(),
            )
          : null;
      await pumpHome(tester);
      await openCategory(tester, 'Apartments');
      expect(find.text('0 rooms found'), findsOneWidget);
      expect(find.text('No rooms found'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final reset = find.widgetWithText(OutlinedButton, 'Reset Filters');
      await tester.ensureVisible(reset);
      await tester.tap(reset);
      await tester.pumpAndSettle();
      expectResults(
        tester,
        sampleProperties.where((p) => p.type != 'Apartment'),
      );
    },
  );

  testWithApi(
    'System Back from a Home category returns Home without duplicate routes',
    (tester) async {
      await pumpHome(tester);
      await openCategory(tester, 'Apartments');
      final more = find.widgetWithText(OutlinedButton, 'More Filters');
      await tester.ensureVisible(more);
      await tester.tap(more);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(SearchScreen), findsOneWidget);
      expectResults(
        tester,
        sampleProperties.where((p) => p.type == 'Apartment'),
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SearchScreen), findsNothing);
      expect(find.byType(MainScreen), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      await openCategory(tester, 'Condos');
      expectResults(tester, sampleProperties.where((p) => p.type == 'Condo'));
    },
  );

  testWithApi(
    'Home initial type tolerates case and whitespace in existing data',
    (tester) async {
      apiResponse = (request) => request.url.path == '/rest/v1/properties'
          ? jsonResponse([
              for (final p in samplePropertyMaps)
                {...p, if (p['type'] == 'Apartment') 'type': ' apartment '},
            ])
          : null;
      await pumpHome(tester);
      await openCategory(tester, 'Apartments');
      expectResults(
        tester,
        sampleProperties.where((p) => p.type == 'Apartment'),
      );
    },
  );

  testWithApi(
    'Initial category at narrow short height with 2x text has no overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 480);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpHome(tester);
      await openCategory(tester, 'Near Transit');
      expectResults(tester, sampleProperties.where((p) => p.nearTransit));
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -900),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
