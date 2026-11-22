import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:roomstay_mobile/data/user_session.dart';
import 'package:roomstay_mobile/screens/home_screen.dart';
import 'package:roomstay_mobile/screens/manager_properties_screen.dart';
import 'package:roomstay_mobile/screens/manager_viewings_screen.dart';
import 'package:roomstay_mobile/theme/app_theme.dart';

import 'support/manager_backend.dart';
import 'support/test_backend.dart';

void main() {
  setUp(resetManagerBackend);
  tearDown(UserSession.clear);

  group('Manager Properties empty state', () {
    testWithApi('shows icon, title, and guidance text when list is empty', (
      tester,
    ) async {
      managerProperties.clear();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ManagerPropertiesScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.apartment_outlined), findsOneWidget);
      expect(find.text('No properties yet'), findsOneWidget);
      expect(
        find.text(
          'Add your first property to start receiving viewing requests.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWithApi('does not show empty state while loading', (tester) async {
      managerProperties.clear();
      final loading = Completer<http.Response>();
      apiResponse = (_) => loading.future;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ManagerPropertiesScreen(),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No properties yet'), findsNothing);
      loading.complete(jsonResponse([]));
      await tester.pumpAndSettle();
      expect(find.text('No properties yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWithApi('does not show empty state when API error is displayed', (
      tester,
    ) async {
      managerProperties.clear();
      apiResponse = (_) => jsonResponse({}, 503);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ManagerPropertiesScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unable to load properties.'), findsOneWidget);
      expect(find.text('No properties yet'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWithApi('renders without overflow on narrow width', (tester) async {
      managerProperties.clear();
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ManagerPropertiesScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No properties yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWithApi('renders without overflow at 2x text scale', (tester) async {
      managerProperties.clear();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ManagerPropertiesScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No properties yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Manager Viewing Requests empty state', () {
    testWithApi('shows icon, title, and guidance text when list is empty', (
      tester,
    ) async {
      managerProperties.clear();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ManagerViewingsScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.event_busy_outlined), findsOneWidget);
      expect(find.text('No viewing requests yet'), findsOneWidget);
      expect(
        find.text('New requests from renters will appear here.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWithApi('does not show empty state while loading', (tester) async {
      managerProperties.clear();
      final loading = Completer<http.Response>();
      apiResponse = (_) => loading.future;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ManagerViewingsScreen(),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No viewing requests yet'), findsNothing);
      loading.complete(jsonResponse([]));
      await tester.pumpAndSettle();
      expect(find.text('No viewing requests yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWithApi('does not show empty state when API error is displayed', (
      tester,
    ) async {
      managerProperties.clear();
      apiResponse = (_) => jsonResponse({}, 503);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ManagerViewingsScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unable to load viewing requests.'), findsOneWidget);
      expect(find.text('No viewing requests yet'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWithApi('renders without overflow on narrow width', (tester) async {
      managerProperties.clear();
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ManagerViewingsScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No viewing requests yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWithApi('renders without overflow at 2x text scale', (tester) async {
      managerProperties.clear();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ManagerViewingsScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No viewing requests yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  for (final isProperties in [true, false]) {
    testWithApi(
      '${isProperties ? 'Properties' : 'Viewings'} empty state scrolls on a narrow short screen at 2x text',
      (tester) async {
        managerProperties.clear();
        tester.view.physicalSize = const Size(320, 320);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: isProperties
                ? const ManagerPropertiesScreen()
                : const ManagerViewingsScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.text(
            isProperties ? 'No properties yet' : 'No viewing requests yet',
          ),
          findsOneWidget,
        );
        final guidance = find.text(
          isProperties
              ? 'Add your first property to start receiving viewing requests.'
              : 'New requests from renters will appear here.',
        );
        final scrollable = find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Scrollable),
        );
        expect(
          tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
          greaterThan(0),
        );
        await tester.ensureVisible(guidance);
        await tester.pumpAndSettle();
        expect(guidance.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  group('Initial load error presentation', () {
    testWithApi('Home screen shows inline error without duplicate SnackBar', (
      tester,
    ) async {
      apiResponse = (_) => jsonResponse({}, 503);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: HomeScreen(
            onSearchRequested: () {},
            favoriteIds: {},
            onFavoriteToggle: (_) {},
            onPropertySelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unable to load properties.'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
