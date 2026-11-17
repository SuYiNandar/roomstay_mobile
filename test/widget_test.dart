import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roomstay_mobile/data/demo_viewings.dart';
import 'package:roomstay_mobile/main.dart';
import 'package:roomstay_mobile/screens/login_screen.dart';
import 'package:roomstay_mobile/screens/main_screen.dart';
import 'package:roomstay_mobile/theme/app_theme.dart';
import 'package:roomstay_mobile/widgets/property_card.dart';

void main() {
  setUp(resetDemoViewings);

  testWidgets('RoomStayApp starts at splash and opens the login screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RoomStayApp());

    expect(find.text('RoomStay'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('Login shows validation errors when fields are empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const LoginScreen()),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('Login form validates and opens the main screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const LoginScreen()),
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'renter@roomstay.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
  });

  testWidgets('Register validates and returns to login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const LoginScreen()),
    );

    await tester.ensureVisible(find.text('Create an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsWidgets);

    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Create Account'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
    await tester.pump();

    expect(find.text('Full name is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.text('Please confirm your password'), findsOneWidget);

    await tester.ensureVisible(find.text('Login'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('Main screen has five MVP destinations that open', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const MainScreen()),
    );

    expect(find.byType(NavigationDestination), findsNWidgets(5));
    for (final label in [
      'Home',
      'Search',
      'Favorites',
      'My Viewings',
      'Profile',
    ]) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
    expect(find.text("A PLACE FOR WHAT'S NEXT"), findsOneWidget);

    for (final label in ['Search', 'Favorites', 'My Viewings', 'Profile']) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text(label)),
        findsOneWidget,
      );
    }

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Home'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("A PLACE FOR WHAT'S NEXT"), findsOneWidget);
  });

  testWidgets('Home search entry points switch to the search tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const MainScreen()),
    );

    await tester.tap(find.text('Search by location, university, or keyword'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Search')),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Home'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Apartments'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apartments'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Search')),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Home'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('View all listings →'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View all listings →'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Search')),
      findsOneWidget,
    );
  });

  testWidgets('Favorites show a saved room and support the empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const MainScreen()),
    );

    expect(find.byType(PropertyCard), findsNWidgets(3));

    final firstCard = find.byType(PropertyCard).first;
    final favoriteButton = find.descendant(
      of: firstCard,
      matching: find.byIcon(Icons.favorite_border),
    );

    await tester.ensureVisible(favoriteButton);
    await tester.pumpAndSettle();
    await tester.tap(favoriteButton);
    await tester.pump();

    expect(
      find.descendant(of: firstCard, matching: find.byIcon(Icons.favorite)),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Favorites'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cozy Studio near RSU'), findsOneWidget);
    expect(find.text('No saved rooms yet'), findsNothing);

    final savedHeart = find.descendant(
      of: find.byType(PropertyCard),
      matching: find.byIcon(Icons.favorite),
    );
    await tester.tap(savedHeart.first);
    await tester.pumpAndSettle();

    expect(find.text('No saved rooms yet'), findsOneWidget);
    expect(
      find.text('Tap the heart on a room to save it here.'),
      findsOneWidget,
    );
  });

  testWidgets('My Viewings shows sample requests with statuses', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const MainScreen()),
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('My Viewings'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Cozy Studio near RSU'), findsOneWidget);
  });

  testWidgets('Profile shows the demo user and logout returns to login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const MainScreen()),
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Profile'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Su Yi Nandar'), findsOneWidget);
    expect(find.text('Renter'), findsOneWidget);
    expect(find.text('suyinandar@example.com'), findsOneWidget);
    expect(find.text('My Favorites'), findsOneWidget);
    expect(find.text('My Viewings'), findsWidgets);
    expect(find.text('Logout'), findsOneWidget);

    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('Home renders without overflow on a mobile screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const MainScreen()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -1600),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('How RoomStay Works'), findsOneWidget);
  });
}
