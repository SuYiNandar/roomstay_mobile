import 'support/test_backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roomstay_mobile/data/user_session.dart';
import 'package:roomstay_mobile/main.dart';
import 'package:roomstay_mobile/screens/login_screen.dart';
import 'package:roomstay_mobile/screens/main_screen.dart';
import 'package:roomstay_mobile/theme/app_theme.dart';
import 'package:roomstay_mobile/widgets/property_card.dart';

void main() {
  setUp(() {
    UserSession.clear();
    resetTestBackend();
  });

  testWithApi('RoomStayApp starts at splash and opens the login screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RoomStayApp());

    expect(find.text('RoomStay'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWithApi('Login shows validation errors when fields are empty', (
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

  testWithApi('Login form validates and opens the main screen', (
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

  testWithApi('Register validates and returns to login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const LoginScreen()),
    );

    await tester.ensureVisible(find.text('Create an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(
      find.text(
        'Sign up to find your next home and manage your rental journey.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('I agree to the Terms of Service and Privacy Policy.'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Sign Up'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
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

  testWithApi(
    'Register enforces every password rule and matching confirmation',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const LoginScreen()),
      );
      await tester.ensureVisible(find.text('Create an account'));
      await tester.tap(find.text('Create an account'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Minimum 8 characters\n'
          'At least 1 uppercase letter\n'
          'At least 1 lowercase letter\n'
          'At least 1 number',
        ),
        findsOneWidget,
      );
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Student Renter');
      await tester.enterText(fields.at(1), 'student@example.com');
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));

      final invalidPasswords = {
        'Abcdef1': 'Password must be at least 8 characters',
        'abcdefg1': 'Password must include an uppercase letter',
        'ABCDEFG1': 'Password must include a lowercase letter',
        'Abcdefgh': 'Password must include a number',
      };
      for (final entry in invalidPasswords.entries) {
        await tester.enterText(fields.at(2), entry.key);
        await tester.enterText(fields.at(3), entry.key);
        await tester.ensureVisible(
          find.widgetWithText(ElevatedButton, 'Sign Up'),
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
        await tester.pumpAndSettle();
        expect(find.text(entry.value), findsOneWidget);
        expect(apiRequests, isEmpty);
      }

      await tester.enterText(fields.at(2), 'Test1234');
      await tester.enterText(fields.at(3), 'Test1235');
      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Sign Up'),
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(apiRequests, isEmpty);
    },
  );

  testWithApi('Main screen has five MVP destinations that open', (
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

  testWithApi('Home search entry points switch to the search tab', (
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

  testWithApi('Favorites show a saved room and support the empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const MainScreen()),
    );
    await tester.pumpAndSettle();

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

  testWithApi('My Viewings shows sample requests with statuses', (
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

  testWithApi('Profile shows the signed-in user and logout returns to login', (
    WidgetTester tester,
  ) async {
    UserSession.accessToken = 'test-access-token';
    UserSession.refreshToken = 'test-refresh-token';
    UserSession.userId = 'test-user-id';
    UserSession.email = 'suyinandar@example.com';
    UserSession.fullName = 'Su Yi Nandar';
    UserSession.role = 'renter';

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
    expect(UserSession.accessToken, isNull);
    expect(UserSession.refreshToken, isNull);
    expect(UserSession.userId, isNull);
    expect(UserSession.email, isNull);
    expect(UserSession.fullName, isNull);
    expect(UserSession.role, isNull);
  });

  testWithApi('Home renders without overflow on a mobile screen', (
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
