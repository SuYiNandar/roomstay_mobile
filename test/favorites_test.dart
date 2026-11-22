import 'support/test_backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roomstay_mobile/data/favorite_helpers.dart';
import 'package:roomstay_mobile/screens/main_screen.dart';
import 'package:roomstay_mobile/screens/room_detail_screen.dart';
import 'package:roomstay_mobile/theme/app_theme.dart';
import 'package:roomstay_mobile/widgets/property_card.dart';

void main() {
  setUp(() {
    resetTestBackend();
  });

  test('Favorite property is read from the nested Supabase relation', () {
    final property = favoritePropertyMap({
      'id': 1,
      'property_id': 7,
      'properties': {
        'id': 7,
        'name': 'Sunlit Apartment near Ari BTS',
        'location': 'Ari',
      },
    });

    expect(property, isNotNull);
    expect(property!['name'], 'Sunlit Apartment near Ari BTS');

    final listProperty = favoritePropertyMap({
      'property_id': 8,
      'properties': [
        {'id': 8, 'name': 'Student Room near University'},
      ],
    });

    expect(listProperty!['name'], 'Student Room near University');
    expect(favoritePropertyMap({'property_id': 9}), isNull);
  });

  test('Favorite property IDs are read from Supabase rows', () {
    final ids = parseFavoritePropertyIds([
      {'property_id': 1},
      {'property_id': '2'},
      {'property_id': null},
      'invalid row',
    ]);

    expect(ids, {1, 2});
  });

  testWithApi('Saving from Search updates Favorites and Room Detail', (
    WidgetTester tester,
  ) async {
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

    await tester.enterText(find.byType(TextField).first, 'Sunlit');
    await tester.pump();

    final resultCard = find.ancestor(
      of: find.text('Sunlit Apartment near Ari BTS'),
      matching: find.byType(PropertyCard),
    );
    final emptyHeart = find.descendant(
      of: resultCard,
      matching: find.byIcon(Icons.favorite_border),
    );

    await tester.ensureVisible(emptyHeart);
    await tester.pumpAndSettle();
    await tester.tap(emptyHeart);
    await tester.pump();

    expect(
      find.descendant(of: resultCard, matching: find.byIcon(Icons.favorite)),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Favorites'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sunlit Apartment near Ari BTS'), findsOneWidget);

    await tester.tap(find.text('Sunlit Apartment near Ari BTS'));
    await tester.pumpAndSettle();

    expect(find.byType(RoomDetailScreen), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.favorite).first);
    await tester.pump();

    expect(find.byIcon(Icons.favorite_border), findsNWidgets(2));

    // Re-saving from detail must refresh the Favorites screen behind it.
    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Sunlit Apartment near Ari BTS'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(PropertyCard),
        matching: find.byIcon(Icons.favorite),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No saved rooms yet'), findsOneWidget);
  });
}
