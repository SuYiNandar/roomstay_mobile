import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:roomstay_mobile/config/supabase_config.dart';
import 'package:roomstay_mobile/data/user_session.dart';
import 'package:roomstay_mobile/data/viewing_helpers.dart';
import 'package:roomstay_mobile/screens/home_screen.dart';
import 'package:roomstay_mobile/screens/login_screen.dart';
import 'package:roomstay_mobile/screens/main_screen.dart';
import 'package:roomstay_mobile/screens/my_viewings_screen.dart';
import 'package:roomstay_mobile/screens/register_screen.dart';
import 'package:roomstay_mobile/screens/room_detail_screen.dart';
import 'package:roomstay_mobile/screens/search_screen.dart';
import 'package:roomstay_mobile/screens/splash_screen.dart';
import 'package:roomstay_mobile/screens/update_viewing_screen.dart';
import 'package:roomstay_mobile/theme/app_theme.dart';
import 'package:roomstay_mobile/widgets/property_card.dart';

import 'fixtures/demo_viewings.dart';
import 'support/test_backend.dart';

Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.lightTheme, home: screen),
  );

  await tester.pumpAndSettle();
}

Future<void> login(WidgetTester tester) async {
  await pumpScreen(tester, const LoginScreen());

  await tester.enterText(
    find.byType(TextFormField).first,
    'renter@example.com',
  );

  await tester.enterText(find.byType(TextFormField).last, 'test-password');

  await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));

  await tester.pumpAndSettle();
}

Future<void> confirmCancel(WidgetTester tester, String name) async {
  final card = find.ancestor(of: find.text(name), matching: find.byType(Card));

  final button = find.descendant(of: card, matching: find.text('Cancel'));

  await tester.ensureVisible(button);

  await tester.tap(button);

  await tester.pumpAndSettle();

  await tester.tap(find.text('Yes, Cancel'));

  await tester.pumpAndSettle();
}

void expectAuthenticated(http.Request request) {
  expect(request.headers['apikey'], supabasePublishableKey);

  expect(request.headers['Authorization'], 'Bearer test-access-token');
}

void main() {
  setUp(resetTestBackend);

  tearDown(UserSession.clear);

  for (final failure in ['credentials', 'missing user', 'profile']) {
    testWithApi('Login $failure failure clears the previous session', (
      tester,
    ) async {
      UserSession.fullName = 'Previous user';

      UserSession.role = 'renter';

      apiResponse = (request) {
        if (failure == 'credentials' && request.url.path == '/auth/v1/token') {
          return jsonResponse({'msg': 'Invalid credentials'}, 400);
        }

        if (failure == 'missing user' && request.url.path == '/auth/v1/token') {
          return jsonResponse({'access_token': 'test-access-token'});
        }

        if (failure == 'profile' && request.url.path == '/rest/v1/profiles') {
          return jsonResponse([], 500);
        }

        return null;
      };

      await login(tester);

      expect(find.byType(MainScreen), findsNothing);

      expect(UserSession.accessToken, isNull);

      expect(UserSession.userId, isNull);

      expect(UserSession.fullName, isNull);

      expect(UserSession.role, isNull);

      expect(tester.takeException(), isNull);
    });
  }

  testWithApi('Login reads the real auth response then authenticated profile', (
    tester,
  ) async {
    await login(tester);

    expect(find.byType(MainScreen), findsOneWidget);

    final auth = apiRequests.firstWhere(
      (request) => request.url.path == '/auth/v1/token',
    );

    expect(auth.method, 'POST');

    expect(auth.url.queryParameters['grant_type'], 'password');

    expect(jsonDecode(auth.body), {
      'email': 'renter@example.com',
      'password': 'test-password',
    });

    final profile = apiRequests.firstWhere(
      (request) => request.url.path == '/rest/v1/profiles',
    );

    expect(profile.url.queryParameters['id'], 'eq.test-user-id');

    expectAuthenticated(profile);
  });

  testWithApi(
    'Registration posts signup data and explains email confirmation',
    (tester) async {
      await pumpScreen(tester, const LoginScreen());

      await tester.ensureVisible(find.text('Create an account'));

      await tester.tap(find.text('Create an account'));

      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);

      await tester.enterText(fields.at(0), 'Student Renter');

      await tester.enterText(fields.at(1), 'student@example.com');

      await tester.enterText(fields.at(2), 'Test1234');

      await tester.enterText(fields.at(3), 'Test1234');

      await tester.ensureVisible(find.byType(Checkbox));

      await tester.tap(find.byType(Checkbox));

      final submit = find.widgetWithText(ElevatedButton, 'Sign Up');

      await tester.ensureVisible(submit);

      await tester.tap(submit);

      await tester.pumpAndSettle();

      final request = apiRequests.single;

      expect(request.url.path, '/auth/v1/signup');

      expect(jsonDecode(request.body), {
        'email': 'student@example.com',
        'password': 'Test1234',
        'data': {'full_name': 'Student Renter'},
      });

      expect(find.byType(RegisterScreen), findsNothing);

      expect(
        find.text(
          'Account created. Please check your email to confirm your account.',
        ),
        findsOneWidget,
      );
    },
  );

  for (final failure in [false, true]) {
    testWithApi(
      'Properties ${failure ? 'failure' : 'empty response'} never displays sample rooms',
      (tester) async {
        apiResponse = (request) {
          if (request.url.path == '/rest/v1/properties') {
            return jsonResponse([], failure ? 503 : 200);
          }

          return null;
        };

        await pumpScreen(
          tester,
          HomeScreen(
            onSearchRequested: () {},
            favoriteIds: {},
            onFavoriteToggle: (_) {},
            onPropertySelected: (_) {},
          ),
        );

        expect(find.byType(PropertyCard), findsNothing);

        expect(
          find.text(
            failure
                ? 'Unable to load properties.'
                : 'No properties are available yet.',
          ),
          findsWidgets,
        );

        await pumpScreen(
          tester,
          SearchScreen(
            favoriteIds: {},
            onFavoriteToggle: (_) {},
            onPropertySelected: (_) {},
          ),
        );

        expect(find.byType(PropertyCard), findsNothing);

        expect(
          find.text(failure ? 'Unable to load properties.' : 'No rooms found'),
          findsWidgets,
        );

        await pumpScreen(
          tester,
          RoomDetailScreen(
            id: 99,
            isFavorite: false,
            onFavoriteToggle: () async => false,
          ),
        );

        expect(
          find.text(
            failure ? 'Unable to load property.' : 'Property not found.',
          ),
          findsWidgets,
        );

        expect(apiRequests.last.url.queryParameters['id'], 'eq.99');
      },
    );
  }

  testWithApi(
    'Viewing read and update are renter scoped and load the property name',
    (tester) async {
      await pumpScreen(tester, const MyViewingsScreen());

      final listRequest = apiRequests.last;

      expectAuthenticated(listRequest);

      expect(listRequest.url.queryParameters['renter_id'], 'eq.test-user-id');

      await tester.tap(find.text('Edit').first);

      await tester.pumpAndSettle();

      expect(find.text('Cozy Studio near RSU'), findsOneWidget);

      final read = apiRequests.last;

      expect(read.url.queryParameters['select'], contains('properties('));

      expect(read.url.queryParameters['renter_id'], 'eq.test-user-id');

      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Updated through API',
      );

      final button = find.widgetWithText(ElevatedButton, 'Update Viewing');

      await tester.ensureVisible(button);

      await tester.tap(button);

      await tester.pumpAndSettle();

      final patch = apiRequests.firstWhere(
        (request) => request.method == 'PATCH',
      );

      expectAuthenticated(patch);

      expect(patch.url.queryParameters['id'], 'eq.1');

      expect(patch.url.queryParameters['renter_id'], 'eq.test-user-id');

      expect(patch.url.queryParameters['status'], 'eq.Pending');

      expect(jsonDecode(patch.body), {
        'viewing_date': '2030-11-20',
        'viewing_time': '10:00:00',
        'message': 'Updated through API',
      });

      expect(find.text('Updated through API'), findsOneWidget);
    },
  );

  testWithApi('Overlapping cancellations remove the correct pending rows', (
    tester,
  ) async {
    demoViewings[1]['status'] = 'Pending';

    final first = Completer<http.Response>();

    final second = Completer<http.Response>();

    apiResponse = (request) {
      if (request.method != 'DELETE') {
        return null;
      }

      expectAuthenticated(request);

      expect(request.url.queryParameters['renter_id'], 'eq.test-user-id');

      expect(request.url.queryParameters['status'], 'eq.Pending');

      return request.url.queryParameters['id'] == 'eq.1'
          ? first.future
          : second.future;
    };

    await pumpScreen(tester, const MyViewingsScreen());

    await confirmCancel(tester, 'Cozy Studio near RSU');

    await confirmCancel(tester, 'Modern Condo near BTS');

    first.complete(jsonResponse([demoViewings[0]]));

    await tester.pumpAndSettle();

    second.complete(jsonResponse([demoViewings[1]]));

    await tester.pumpAndSettle();

    expect(find.text('Cozy Studio near RSU'), findsNothing);

    expect(find.text('Modern Condo near BTS'), findsNothing);

    expect(find.text('Student Room near University'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWithApi('Failed viewing deletion keeps the saved row', (tester) async {
    apiResponse = (request) =>
        request.method == 'DELETE' ? jsonResponse({}, 500) : null;

    await pumpScreen(tester, const MyViewingsScreen());

    await confirmCancel(tester, 'Cozy Studio near RSU');

    expect(find.text('Cozy Studio near RSU'), findsOneWidget);

    expect(find.text('Viewing cancelled successfully.'), findsNothing);

    expect(find.text('Unable to cancel viewing.'), findsOneWidget);
  });

  testWithApi('A viewing update blocked by status is not reported as saved', (
    tester,
  ) async {
    apiResponse = (request) =>
        request.method == 'PATCH' ? jsonResponse([]) : null;

    await pumpScreen(tester, const UpdateViewingScreen(id: 1));

    final button = find.widgetWithText(ElevatedButton, 'Update Viewing');

    await tester.ensureVisible(button);

    await tester.tap(button);

    await tester.pumpAndSettle();

    expect(find.byType(UpdateViewingScreen), findsOneWidget);

    expect(find.text(pendingViewingModificationMessage), findsOneWidget);

    expect(find.text('Viewing updated successfully.'), findsNothing);
  });

  testWithApi('A viewing delete blocked by status keeps the local record', (
    tester,
  ) async {
    apiResponse = (request) =>
        request.method == 'DELETE' ? jsonResponse([]) : null;

    await pumpScreen(tester, const MyViewingsScreen());

    await confirmCancel(tester, 'Cozy Studio near RSU');

    expect(find.text('Cozy Studio near RSU'), findsOneWidget);

    expect(find.text(pendingViewingModificationMessage), findsOneWidget);
  });

  for (final date in ['2000-01-01', '2100-01-01']) {
    testWithApi(
      'Edit date picker accepts a stored date outside its range: $date',
      (tester) async {
        demoViewings.first['viewing_date'] = date;

        await pumpScreen(tester, const UpdateViewingScreen(id: 1));

        await tester.tap(find.byType(TextFormField).first);

        await tester.pumpAndSettle();

        expect(find.byType(DatePickerDialog), findsOneWidget);

        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Cancel'));

        await tester.pumpAndSettle();
      },
    );
  }

  test(
    'Invalid viewing date/time values are rejected without normalizing them',
    () {
      expect(parseViewingDate('2026-02-30'), isNull);

      expect(parseViewingDate('2026-13-01'), isNull);

      expect(parseViewingTime('25:00:00'), isNull);

      expect(parseViewingTime('12:65:00'), isNull);

      expect(parseViewingTime('12'), isNull);
    },
  );

  testWithApi('Disposing a pending screen safely ignores its response', (
    tester,
  ) async {
    final response = Completer<http.Response>();

    apiResponse = (_) => response.future;

    await tester.pumpWidget(const MaterialApp(home: MyViewingsScreen()));

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));

    response.complete(jsonResponse([]));

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Disposing splash cancels its pending timer', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));

    expect(tester.takeException(), isNull);
  });

  testWithApi(
    'Unavailable Room Detail fits a narrow screen without invented reviews',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);

      tester.view.devicePixelRatio = 1;

      addTearDown(tester.view.resetPhysicalSize);

      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpScreen(
        tester,
        RoomDetailScreen(
          id: 8,
          isFavorite: false,
          onFavoriteToggle: () async => false,
        ),
      );

      expect(tester.takeException(), isNull);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -2000),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      expect(find.text('“Clean room and convenient location.”'), findsNothing);

      expect(find.text('No written reviews are available.'), findsNothing);

      expect(find.text('Reviews'), findsNothing);

      expect(find.text('House Rules'), findsNothing);

      expect(find.text('Property Partner'), findsNothing);

      expect(find.text('Property Manager'), findsOneWidget);
    },
  );
}
