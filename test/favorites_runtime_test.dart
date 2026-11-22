import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:roomstay_mobile/config/supabase_config.dart';
import 'package:roomstay_mobile/data/user_session.dart';
import 'package:roomstay_mobile/screens/favorites_screen.dart';
import 'package:roomstay_mobile/screens/home_screen.dart';
import 'package:roomstay_mobile/screens/main_screen.dart';
import 'package:roomstay_mobile/widgets/property_card.dart';

import 'support/test_backend.dart';

const realRow = {
  'id': 123,
  'property_id': 901,
  'properties': {'id': 901, 'name': 'Supabase saved room'},
};

Future<void> pumpFavorites(WidgetTester tester, {Set<int>? ids}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: FavoritesScreen(
        favoriteIds: ids ?? {},
        onFavoriteToggle: (_) {},
        onPropertySelected: (_) {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> selectFavorites(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Favorites'),
    ),
  );
  await tester.pumpAndSettle();
}

void expectNoDemoRooms() {
  expect(find.text('Sunlit Apartment near Ari BTS'), findsNothing);
  expect(find.text('Family House in Bang Khen'), findsNothing);
}

void main() {
  setUp(() {
    resetTestBackend();
  });

  tearDown(() {
    UserSession.clear();
  });

  testWithApi('200 [] ignores stale local IDs and shows exact empty state', (
    tester,
  ) async {
    await pumpFavorites(tester, ids: {4, 5});
    expect(find.text('No saved rooms yet'), findsOneWidget);
    expect(
      find.text('Tap the heart on a room to save it here.'),
      findsOneWidget,
    );
    expect(find.byType(PropertyCard), findsNothing);
    expectNoDemoRooms();
    final request = favoriteRequests.single;
    expect(request.method, 'GET');
    expect(request.url.path, '/rest/v1/favorites');
    expect(request.url.queryParameters, {
      'user_id': 'eq.test-user-id',
      'select': 'id,property_id,properties(*)',
    });
    expect(request.headers['apikey'], supabasePublishableKey);
    expect(request.headers['Authorization'], 'Bearer test-access-token');
  });

  testWithApi('200 rows displays only nested Supabase properties', (
    tester,
  ) async {
    favoriteRows.add(realRow);
    await pumpFavorites(tester);
    expect(find.text('Supabase saved room'), findsOneWidget);
    expect(find.byType(PropertyCard), findsOneWidget);
    expect(find.text('No saved rooms yet'), findsNothing);
    expectNoDemoRooms();
  });

  for (final failure in ['HTTP', 'network', 'malformed']) {
    testWithApi(
      '$failure failure shows an error, never demo or empty success',
      (tester) async {
        favoritesResponse = (_) {
          if (failure == 'network') throw http.ClientException('Offline');
          return http.Response(
            failure == 'malformed' ? '{}' : 'Unavailable',
            failure == 'HTTP' ? 503 : 200,
          );
        };
        await pumpFavorites(tester, ids: {4, 5});
        expect(find.text('Unable to load favorites.'), findsOneWidget);
        expect(find.text('No saved rooms yet'), findsNothing);
        expect(find.byType(PropertyCard), findsNothing);
        expectNoDemoRooms();
        favoritesResponse = (_) => http.Response('[]', 200);
        await tester.tap(find.text('Try Again'));
        await tester.pumpAndSettle();
        expect(find.text('No saved rooms yet'), findsOneWidget);
        expect(find.text('Unable to load favorites.'), findsNothing);
      },
    );
  }

  testWithApi('Missing session shows login error without a request', (
    tester,
  ) async {
    UserSession.clear();
    await pumpFavorites(tester);
    expect(find.text('Please log in again.'), findsOneWidget);
    expect(favoriteRequests, isEmpty);
    expectNoDemoRooms();
  });

  testWithApi(
    'Fresh empty response clears previously loaded MainScreen favorites',
    (tester) async {
      favoriteRows.add(realRow);
      await tester.pumpWidget(const MaterialApp(home: MainScreen()));
      await tester.pumpAndSettle();
      expect(tester.widget<HomeScreen>(find.byType(HomeScreen)).favoriteIds, {
        901,
      });
      favoriteRows.clear();
      await selectFavorites(tester);
      expect(find.text('No saved rooms yet'), findsOneWidget);
      expect(
        tester
            .widget<FavoritesScreen>(find.byType(FavoritesScreen))
            .favoriteIds,
        isEmpty,
      );
      expectNoDemoRooms();
    },
  );

  testWithApi('An older empty GET cannot overwrite a newly saved favorite', (
    tester,
  ) async {
    final save = Completer<http.Response>();
    final oldFetch = Completer<http.Response>();
    var reads = 0;
    favoritesResponse = (request) {
      if (request.method == 'POST') return save.future;
      reads++;
      if (reads == 1) return jsonResponse([]);
      if (reads == 2) return oldFetch.future;
      return jsonResponse([
        {
          'id': 10,
          'property_id': 1,
          'properties': {'id': 1, 'name': 'Newly saved room'},
        },
      ]);
    };
    await tester.pumpWidget(const MaterialApp(home: MainScreen()));
    await tester.pumpAndSettle();
    final heart = find.descendant(
      of: find.byType(PropertyCard).first,
      matching: find.byIcon(Icons.favorite_border),
    );
    await tester.ensureVisible(heart);
    await tester.tap(heart);
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Favorites'),
      ),
    );
    await tester.pump();
    save.complete(
      jsonResponse([
        {'id': 10, 'property_id': 1},
      ], 201),
    );
    await tester.pumpAndSettle();
    expect(find.text('Newly saved room'), findsOneWidget);
    oldFetch.complete(jsonResponse([]));
    await tester.pumpAndSettle();
    expect(find.text('Newly saved room'), findsOneWidget);
    expect(find.text('No saved rooms yet'), findsNothing);
  });

  for (final succeeds in [true, false]) {
    testWithApi(
      'POST and DELETE ${succeeds ? 'success' : 'failure'} only update hearts after success',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: MainScreen()));
        await tester.pumpAndSettle();
        final card = find.byType(PropertyCard).first;
        final id = tester.widget<PropertyCard>(card).property.id;
        final save = Completer<http.Response>();
        favoritesResponse = (_) => save.future;
        final heart = find.descendant(
          of: card,
          matching: find.byIcon(Icons.favorite_border),
        );
        await tester.ensureVisible(heart);
        await tester.pumpAndSettle();
        await tester.tap(heart);
        await tester.pump();
        await tester.tap(heart);
        await tester.pump();
        expect(tester.widget<PropertyCard>(card).isFavorite, isFalse);
        expect(favoriteRequests.where((r) => r.method == 'POST').length, 1);
        final post = favoriteRequests.last;
        expect(jsonDecode(post.body), {
          'user_id': 'test-user-id',
          'property_id': id,
        });
        expect(post.headers['Authorization'], 'Bearer test-access-token');
        save.complete(http.Response('[]', succeeds ? 201 : 500));
        await tester.pumpAndSettle();
        expect(tester.widget<PropertyCard>(card).isFavorite, succeeds);
        if (!succeeds) {
          expect(find.text('Unable to save favorite.'), findsOneWidget);
          ScaffoldMessenger.of(tester.element(card)).clearSnackBars();
          await tester.pumpAndSettle();
          // Save successfully before exercising a failed DELETE.
          favoritesResponse = (_) => http.Response('[]', 201);
          await tester.tap(heart);
          await tester.pumpAndSettle();
        }
        final remove = Completer<http.Response>();
        favoritesResponse = (_) => remove.future;
        await tester.tap(
          find.descendant(of: card, matching: find.byIcon(Icons.favorite)),
        );
        await tester.pump();
        expect(tester.widget<PropertyCard>(card).isFavorite, isTrue);
        final delete = favoriteRequests.last;
        expect(delete.method, 'DELETE');
        expect(delete.url.queryParameters, {
          'user_id': 'eq.test-user-id',
          'property_id': 'eq.$id',
        });
        expect(delete.headers['apikey'], supabasePublishableKey);
        expect(delete.headers['Authorization'], 'Bearer test-access-token');
        remove.complete(http.Response('', succeeds ? 204 : 500));
        await tester.pumpAndSettle();
        expect(tester.widget<PropertyCard>(card).isFavorite, !succeeds);
        if (!succeeds) {
          expect(find.text('Unable to remove favorite.'), findsOneWidget);
        }
      },
    );
  }
}
