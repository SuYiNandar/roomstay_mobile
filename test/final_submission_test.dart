import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomstay_mobile/data/user_session.dart';
import 'package:roomstay_mobile/models/property.dart';
import 'package:roomstay_mobile/screens/favorites_screen.dart';
import 'package:roomstay_mobile/screens/room_detail_screen.dart';
import 'package:roomstay_mobile/screens/search_screen.dart';
import 'package:roomstay_mobile/theme/app_theme.dart';
import 'package:roomstay_mobile/widgets/property_card.dart';
import 'support/manager_backend.dart';
import 'support/test_backend.dart';

Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.lightTheme, home: screen),
  );
  await tester.pumpAndSettle();
}

Future<void> choose(
  WidgetTester tester,
  String label, {
  bool last = false,
}) async {
  final matches = find.widgetWithText(ChoiceChip, label);
  final chip = last ? matches.last : matches.first;
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

Future<void> invalidRange(WidgetTester tester) async {
  await pumpScreen(
    tester,
    SearchScreen(
      favoriteIds: {},
      onFavoriteToggle: (_) {},
      onPropertySelected: (_) {},
    ),
  );
  await tester.tap(find.text('More Filters'));
  await tester.pumpAndSettle();
  await choose(tester, formatBaht(15000));
  await choose(tester, formatBaht(10000), last: true);
}

void main() {
  setUp(resetTestBackend);
  tearDown(UserSession.clear);
  const rangeError = 'Minimum rent cannot be greater than maximum rent.';
  testWithApi(
    'Invalid rent range stays in sheet; correcting to equal bounds applies inclusive filter',
    (tester) async {
      await invalidRange(tester);
      expect(find.text(rangeError), findsOneWidget);
      final apply = find.widgetWithText(ElevatedButton, 'Show Results');
      expect(tester.widget<ElevatedButton>(apply).onPressed, isNull);
      expect(find.byType(BottomSheet), findsOneWidget);
      await choose(tester, formatBaht(15000), last: true);
      expect(find.text(rangeError), findsNothing);
      await tester.tap(apply);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('1 room found'), findsOneWidget);
      expect(
        tester
            .widget<PropertyCard>(find.byType(PropertyCard))
            .property
            .monthlyRent,
        15000,
      );
    },
  );
  testWithApi(
    'Reset removes invalid range and restores unbounded Search results',
    (tester) async {
      await invalidRange(tester);
      final reset = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.widgetWithText(OutlinedButton, 'Reset'),
      );
      await tester.tap(reset);
      await tester.pumpAndSettle();
      expect(find.text(rangeError), findsNothing);
      await tester.tap(find.text('Show Results'));
      await tester.pumpAndSettle();
      expect(find.text('8 rooms found'), findsOneWidget);
    },
  );
  for (final state in ['empty', 'error']) {
    testWithApi(
      'Favorites $state remains scrollable and usable on short screen at 2x text',
      (tester) async {
        tester.view.physicalSize = const Size(360, 320);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        if (state == 'error') {
          favoritesResponse = (_) => jsonResponse({'message': 'failure'}, 500);
        }
        await pumpScreen(
          tester,
          FavoritesScreen(
            favoriteIds: {},
            onFavoriteToggle: (_) {},
            onPropertySelected: (_) {},
          ),
        );
        expect(tester.takeException(), isNull);
        if (state == 'error') {
          final retry = find.widgetWithText(ElevatedButton, 'Try Again');
          await tester.ensureVisible(retry);
          await tester.pumpAndSettle();
          expect(retry.hitTestable(), findsOneWidget);
          favoritesResponse = (_) => jsonResponse([]);
          await tester.tap(retry);
          await tester.pumpAndSettle();
        }
        expect(find.text('No saved rooms yet'), findsOneWidget);
        final guidance = find.text('Tap the heart on a room to save it here.');
        await tester.ensureVisible(guidance);
        await tester.pumpAndSettle();
        expect(guidance.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWithApi(
    'Clipboard failure reports an error and allows a successful retry',
    (tester) async {
      resetManagerBackend();
      var fail = true;
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            if (fail) throw PlatformException(code: 'clipboard_unavailable');
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpScreen(
        tester,
        RoomDetailScreen(
          id: 101,
          isFavorite: false,
          onFavoriteToggle: () async => true,
        ),
      );
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Contact Property Manager'),
      );
      await tester.pumpAndSettle();
      final copy = find.widgetWithText(ElevatedButton, 'Copy Email');
      await tester.ensureVisible(copy);
      await tester.tap(copy);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(BottomSheet), findsNothing);
      expect(
        find.text('Unable to copy email. Please try again.').hitTestable(),
        findsOneWidget,
      );
      expect(find.text('Email copied to clipboard.'), findsNothing);
      fail = false;
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Contact Property Manager'),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(copy);
      await tester.tap(copy);
      await tester.pumpAndSettle();
      expect(copied, 'manager@example.com');
      expect(find.byType(BottomSheet), findsNothing);
    },
  );
}
