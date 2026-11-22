import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:roomstay_mobile/config/supabase_config.dart';
import 'package:roomstay_mobile/data/user_session.dart';
import 'package:roomstay_mobile/screens/login_screen.dart';
import 'package:roomstay_mobile/screens/main_screen.dart';
import 'package:roomstay_mobile/screens/manager_viewings_screen.dart';
import 'package:roomstay_mobile/screens/my_viewings_screen.dart';
import 'package:roomstay_mobile/screens/property_form_screen.dart';
import 'package:roomstay_mobile/screens/property_manager_main_screen.dart';
import 'package:roomstay_mobile/theme/app_colors.dart';
import 'package:roomstay_mobile/theme/app_theme.dart';

import 'support/manager_backend.dart';
import 'support/test_backend.dart';

Future<void> pumpManager(
  WidgetTester tester, [
  Widget screen = const PropertyManagerMainScreen(),
]) async {
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

Finder field(String label) => find.widgetWithText(TextFormField, label);

Future<void> selectBedrooms(WidgetTester tester, String label) async {
  final dropdown = find.byType(DropdownButtonFormField<int>);
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  final option = find.text(label).last;
  await tester.ensureVisible(option);
  await tester.tap(option);
  await tester.pumpAndSettle();
}

Future<void> fillProperty(WidgetTester tester) async {
  await tester.enterText(field('Property Name'), 'New manager room');
  await tester.enterText(field('Location'), 'Ari, Bangkok');
  final type = find.byType(DropdownButtonFormField<String>);
  await tester.ensureVisible(type);
  await tester.tap(type);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Condo').last);
  await tester.pumpAndSettle();
  await tester.enterText(field('Monthly Rent'), '9500');
  await selectBedrooms(tester, 'Studio (0 Bedroom)');
  for (final facility in ['Wi-Fi', 'Parking']) {
    final chip = find.widgetWithText(FilterChip, facility);
    await tester.ensureVisible(chip);
    if (!tester.widget<FilterChip>(chip).selected) await tester.tap(chip);
    await tester.pumpAndSettle();
  }
}

Future<void> tapButton(WidgetTester tester, String label) async {
  final button = find.widgetWithText(ElevatedButton, label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> deleteFirst(WidgetTester tester) async {
  final button = find.widgetWithText(TextButton, 'Delete').first;
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void expectAuth(http.Request request) {
  expect(request.headers['apikey'], supabasePublishableKey);
  expect(request.headers['Authorization'], 'Bearer test-access-token');
}

void main() {
  setUp(resetManagerBackend);
  tearDown(UserSession.clear);

  for (final role in ['renter', 'partner', 'property_manager', 'unknown']) {
    testWithApi('Login routes the stored $role role safely', (tester) async {
      managerRole = role;
      await pumpManager(tester, const LoginScreen());
      expect(find.text('Partner'), findsNothing);
      await tester.enterText(
        find.byType(TextFormField).first,
        'manager@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'Password1');
      await tapButton(tester, 'Login');
      if (role == 'renter') {
        expect(find.byType(MainScreen), findsOneWidget);
        expect(find.byType(NavigationDestination), findsNWidgets(5));
      } else if (role == 'unknown') {
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(
          find.text('This account role is not supported.'),
          findsOneWidget,
        );
        expect(UserSession.accessToken, isNull);
      } else {
        expect(find.byType(PropertyManagerMainScreen), findsOneWidget);
        expect(find.byType(NavigationDestination), findsNWidgets(3));
        expect(UserSession.role, role);
      }
    });
  }

  testWithApi('Properties requests only the logged-in manager ownership', (
    tester,
  ) async {
    await pumpManager(tester);
    final request = apiRequests.single;
    expect(request.url.queryParameters, {
      'partner_id': 'eq.test-user-id',
      'select': '*',
      'order': 'id.desc',
    });
    expectAuth(request);
    expect(find.text('Manager property 101'), findsOneWidget);
    expect(find.text('Unrelated property'), findsNothing);
  });

  testWithApi('Manager property empty state has no sample properties', (
    tester,
  ) async {
    managerProperties.clear();
    await pumpManager(tester);
    expect(find.text('No properties yet'), findsOneWidget);
    expect(
      find.text('Add your first property to start receiving viewing requests.'),
      findsOneWidget,
    );
    expect(find.byType(Card), findsNothing);
  });

  testWithApi('Manager property error can retry', (tester) async {
    apiResponse = (_) => jsonResponse({}, 503);
    await pumpManager(tester);
    expect(find.text('Unable to load properties.'), findsOneWidget);
    apiResponse = managerResponse;
    await tapButton(tester, 'Retry');
    expect(find.text('Manager property 101'), findsOneWidget);
  });

  testWithApi('Property form validates required fields and numeric limits', (
    tester,
  ) async {
    await pumpManager(tester, const PropertyFormScreen());
    await tapButton(tester, 'Add Property');
    for (final error in [
      'Property name is required',
      'Location is required',
      'Property type is required',
      'Monthly rent must be a positive whole number',
      'Please select bedrooms',
    ]) {
      expect(find.text(error), findsOneWidget);
    }
    await fillProperty(tester);
    await tester.enterText(field('Monthly Rent'), '0');
    await tapButton(tester, 'Add Property');
    expect(
      find.text('Monthly rent must be a positive whole number'),
      findsOneWidget,
    );
    expect(find.text('Please select bedrooms'), findsNothing);
    expect(apiRequests, isEmpty);
  });

  testWithApi(
    'Bedrooms dropdown starts empty and supports only Studio through 5',
    (tester) async {
      await pumpManager(tester);
      await tapButton(tester, 'Add Property');
      final dropdown = find.byType(DropdownButtonFormField<int>);
      expect(dropdown, findsOneWidget);
      expect(find.text('Select bedrooms'), findsOneWidget);
      expect(tester.state<FormFieldState<int>>(dropdown).value, isNull);
      await fillProperty(tester);
      const labels = [
        'Studio (0 Bedroom)',
        '1 Bedroom',
        '2 Bedrooms',
        '3 Bedrooms',
        '4 Bedrooms',
        '5 Bedrooms',
      ];
      expect(
        tester
            .widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
            .items!
            .map((item) => (item.child as Text).data),
        labels,
      );
      for (var index = 0; index < labels.length; index++) {
        await selectBedrooms(tester, labels[index]);
        expect(tester.state<FormFieldState<int>>(dropdown).value, index);
      }
      await tapButton(tester, 'Add Property');
      final request = apiRequests.firstWhere((r) => r.method == 'POST');
      expect(jsonDecode(request.body)['bedrooms'], 5);
      expect(jsonDecode(request.body)['bedrooms'], isA<int>());
    },
  );

  for (final bedrooms in [0, 3, 5]) {
    testWithApi('Edit preselects and preserves $bedrooms bedrooms', (
      tester,
    ) async {
      managerProperties.first['bedrooms'] = bedrooms;
      await pumpManager(tester, const PropertyFormScreen(propertyId: 101));
      final dropdown = find.byType(DropdownButtonFormField<int>);
      expect(tester.state<FormFieldState<int>>(dropdown).value, bedrooms);
      await tapButton(tester, 'Update Property');
      final request = apiRequests.firstWhere((r) => r.method == 'PATCH');
      expect(jsonDecode(request.body)['bedrooms'], bedrooms);
      expect(jsonDecode(request.body)['bedrooms'], isA<int>());
    });
  }

  testWithApi(
    'Add sends the known schema with session ownership and refreshes list',
    (tester) async {
      await pumpManager(tester);
      await tapButton(tester, 'Add Property');
      await fillProperty(tester);
      await tapButton(tester, 'Add Property');
      final request = apiRequests.firstWhere((r) => r.method == 'POST');
      expectAuth(request);
      expect(request.url.path, '/rest/v1/properties');
      expect(request.headers['Prefer'], 'return=representation');
      expect(jsonDecode(request.body), {
        'partner_id': 'test-user-id',
        'name': 'New manager room',
        'location': 'Ari, Bangkok',
        'type': 'Condo',
        'monthly_rent': 9500,
        'bedrooms': 0,
        'description': '',
        'facilities': ['Wi-Fi', 'Parking'],
        'image_url': null,
        'available': true,
        'pet_friendly': false,
        'near_university': false,
        'near_transit': false,
      });
      expect(find.byType(PropertyFormScreen), findsNothing);
      expect(find.text('New manager room'), findsOneWidget);
      expect(find.text('Property added successfully.'), findsOneWidget);
      // The same row is visible to the renter's normal properties GET.
      final renterRead = managerResponse(
        http.Request(
          'GET',
          Uri.parse('$supabaseUrl/rest/v1/properties?select=*'),
        ),
      )!;
      expect(
        (jsonDecode(renterRead.body) as List).any(
          (row) => row['name'] == 'New manager room',
        ),
        isTrue,
      );
    },
  );

  testWithApi(
    'Edit loads existing fields and patches only editable values with owner filter',
    (tester) async {
      await pumpManager(tester, const PropertyFormScreen(propertyId: 101));
      expect(find.text('Manager property 101'), findsOneWidget);
      expect(find.text('Wi-Fi'), findsOneWidget);
      expect(
        tester
            .state<FormFieldState<int>>(
              find.byType(DropdownButtonFormField<int>),
            )
            .value,
        1,
      );
      await selectBedrooms(tester, '2 Bedrooms');
      await tester.enterText(field('Property Name'), 'Updated manager room');
      final available = find.widgetWithText(SwitchListTile, 'Available');
      await tester.ensureVisible(available);
      await tester.tap(available);
      await tapButton(tester, 'Update Property');
      final request = apiRequests.firstWhere((r) => r.method == 'PATCH');
      expect(request.url.queryParameters, {
        'id': 'eq.101',
        'partner_id': 'eq.test-user-id',
      });
      expectAuth(request);
      final body = jsonDecode(request.body);
      expect(body['name'], 'Updated manager room');
      expect(body['bedrooms'], 2);
      expect(body['bedrooms'], isA<int>());
      expect(body['available'], isFalse);
      expect(body.containsKey('partner_id'), isFalse);
      expect(body.containsKey('id'), isFalse);
      expect(managerProperties.first['available'], isFalse);
    },
  );

  testWithApi('Editing an unrelated property never exposes its form', (
    tester,
  ) async {
    await pumpManager(tester, const PropertyFormScreen(propertyId: 999));
    expect(
      find.text('Property not found or you do not have access.'),
      findsOneWidget,
    );
    expect(find.byType(Form), findsNothing);
    expect(
      apiRequests.single.url.queryParameters['partner_id'],
      'eq.test-user-id',
    );
  });

  testWithApi('Zero-row edit does not claim success', (tester) async {
    apiResponse = (request) =>
        request.method == 'PATCH' ? jsonResponse([]) : managerResponse(request);
    await pumpManager(tester, const PropertyFormScreen(propertyId: 101));
    await tapButton(tester, 'Update Property');
    expect(find.text('Unable to update property.'), findsOneWidget);
    expect(find.byType(PropertyFormScreen), findsOneWidget);
    expect(find.text('Property updated successfully.'), findsNothing);
  });

  testWithApi('Delete confirmation can be cancelled without an API mutation', (
    tester,
  ) async {
    await pumpManager(tester);
    await deleteFirst(tester);
    expect(find.text('Delete Property?'), findsOneWidget);
    expect(
      find.text('Are you sure you want to delete this property?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(apiRequests.where((r) => r.method == 'DELETE'), isEmpty);
    expect(find.text('Manager property 101'), findsOneWidget);
  });

  for (final failure in ['foreign key', 'network', 'empty']) {
    testWithApi('Delete $failure failure keeps the property visible', (
      tester,
    ) async {
      apiResponse = (request) {
        if (request.method == 'DELETE') {
          if (failure == 'network') throw http.ClientException('Offline');
          return failure == 'empty'
              ? jsonResponse([])
              : jsonResponse({'code': '23503'}, 409);
        }
        return managerResponse(request);
      };
      await pumpManager(tester);
      await deleteFirst(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Delete'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Manager property 101'), findsOneWidget);
      expect(
        find.text(
          failure == 'foreign key'
              ? 'Unable to delete this property because it has related records.'
              : 'Unable to delete property.',
        ),
        findsOneWidget,
      );
      expect(apiRequests.where((r) => r.method == 'DELETE').length, 1);
    });
  }

  testWithApi(
    'Delete waits for confirmed API success before removing the property',
    (tester) async {
      final deleted = Completer<http.Response>();
      apiResponse = (request) => request.method == 'DELETE'
          ? deleted.future
          : managerResponse(request);
      await pumpManager(tester);
      await deleteFirst(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Delete'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Manager property 101'), findsOneWidget);
      final request = apiRequests.last;
      expectAuth(request);
      expect(request.url.queryParameters, {
        'id': 'eq.101',
        'partner_id': 'eq.test-user-id',
      });
      deleted.complete(jsonResponse([managerProperties.first]));
      await tester.pumpAndSettle();
      expect(find.text('Manager property 101'), findsNothing);
      expect(find.text('Property deleted successfully.'), findsOneWidget);
    },
  );

  testWithApi(
    'Viewing requests and renter profiles are scoped to owned properties',
    (tester) async {
      await pumpManager(tester, const ManagerViewingsScreen());
      expect(find.text('Manager property 101'), findsOneWidget);
      expect(find.text('Student Renter'), findsWidgets);
      expect(find.text('Unrelated property'), findsNothing);
      final requests = apiRequests
          .where((r) => r.url.path == '/rest/v1/viewings')
          .toList();
      expect(
        requests.single.url.queryParameters['property_id'],
        'in.(101,102)',
      );
      final profiles = apiRequests.last;
      expect(profiles.url.path, '/rest/v1/profiles');
      expect(profiles.url.queryParameters['id'], 'in.(renter-one)');
      for (final request in apiRequests) {
        expectAuth(request);
      }
    },
  );

  testWithApi('No owned properties means no viewing or renter lookup', (
    tester,
  ) async {
    managerProperties.clear();
    await pumpManager(tester, const ManagerViewingsScreen());
    expect(find.text('No viewing requests yet'), findsOneWidget);
    expect(apiRequests.length, 1);
  });

  testWithApi('Profile RLS denial does not hide owned viewing requests', (
    tester,
  ) async {
    apiResponse = (request) => request.url.path == '/rest/v1/profiles'
        ? jsonResponse({}, 403)
        : managerResponse(request);
    await pumpManager(tester, const ManagerViewingsScreen());
    expect(find.text('Renter information unavailable'), findsWidgets);
    expect(find.text('Manager property 101'), findsOneWidget);
    expect(find.text('Approve'), findsWidgets);
  });

  testWithApi('Viewing API failure shows an error and can retry', (
    tester,
  ) async {
    apiResponse = (request) => request.url.path == '/rest/v1/viewings'
        ? jsonResponse({}, 500)
        : managerResponse(request);
    await pumpManager(tester, const ManagerViewingsScreen());
    expect(find.text('Unable to load viewing requests.'), findsOneWidget);
    expect(find.text('Approve'), findsNothing);
    apiResponse = managerResponse;
    await tapButton(tester, 'Retry');
    expect(find.text('Manager property 101'), findsOneWidget);
  });

  testWithApi('Decided and cancelled requests have no decision buttons', (
    tester,
  ) async {
    managerViewings[0]['status'] = 'Approved';
    managerViewings[1]['status'] = 'Rejected';
    await pumpManager(tester, const ManagerViewingsScreen());
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Approve'), findsNothing);
    expect(find.text('Reject'), findsNothing);
    managerViewings[0]['status'] = 'Cancelled';
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Approve'), findsNothing);
  });

  testWithApi(
    'Viewing decision waits for success and prevents duplicate PATCH',
    (tester) async {
      final response = Completer<http.Response>();
      apiResponse = (request) => request.method == 'PATCH'
          ? response.future
          : managerResponse(request);
      await pumpManager(tester, const ManagerViewingsScreen());
      final approve = find.widgetWithText(ElevatedButton, 'Approve').first;
      await tester.tap(approve);
      await tester.pumpAndSettle();
      expect(find.text('Approved'), findsNothing);
      expect(tester.widget<ElevatedButton>(approve).onPressed, isNull);
      await tester.tap(approve);
      expect(apiRequests.where((r) => r.method == 'PATCH').length, 1);
      response.complete(
        jsonResponse([
          {...managerViewings.first, 'status': 'Approved'},
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Approved'), findsOneWidget);
    },
  );

  for (final status in ['Approved', 'Rejected']) {
    testWithApi(
      '$status checks ownership, PATCHes status, and is visible to renter',
      (tester) async {
        await pumpManager(tester, const ManagerViewingsScreen());
        final button = find
            .widgetWithText(
              status == 'Approved' ? ElevatedButton : OutlinedButton,
              status == 'Approved' ? 'Approve' : 'Reject',
            )
            .first;
        await tester.tap(button);
        await tester.pumpAndSettle();
        final patch = apiRequests.firstWhere((r) => r.method == 'PATCH');
        expectAuth(patch);
        expect(patch.url.queryParameters, {
          'id': 'eq.101',
          'property_id': 'eq.101',
          'status': 'eq.Pending',
        });
        expect(jsonDecode(patch.body), {'status': status});
        final ownership = apiRequests[apiRequests.indexOf(patch) - 1];
        expect(ownership.url.path, '/rest/v1/properties');
        expect(ownership.url.queryParameters['partner_id'], 'eq.test-user-id');
        expect(find.text(status), findsOneWidget);
        UserSession.role = 'renter';
        UserSession.userId = 'renter-one';
        await pumpManager(tester, const MyViewingsScreen());
        expect(find.text(status), findsOneWidget);
        final statusText = tester.widget<Text>(find.text(status));
        expect(
          statusText.style!.color,
          status == 'Approved' ? AppColors.success : AppColors.error,
        );
      },
    );
  }

  testWithApi(
    'Ownership loss blocks PATCH even when the old card is still shown',
    (tester) async {
      await pumpManager(tester, const ManagerViewingsScreen());
      managerProperties.first['partner_id'] = 'other-manager';
      await tester.tap(find.widgetWithText(ElevatedButton, 'Approve').first);
      await tester.pumpAndSettle();
      expect(apiRequests.where((r) => r.method == 'PATCH'), isEmpty);
      expect(
        find.text(
          'Unable to update this viewing request. You may no longer own the property.',
        ),
        findsOneWidget,
      );
    },
  );

  testWithApi(
    'Unexpected unrelated viewing rows are not displayed or actionable',
    (tester) async {
      apiResponse = (request) => request.url.path == '/rest/v1/viewings'
          ? jsonResponse(managerViewings)
          : managerResponse(request);
      await pumpManager(tester, const ManagerViewingsScreen());
      expect(find.text('Unrelated property'), findsNothing);
      expect(find.text('Approve'), findsNWidgets(2));
      expect(apiRequests.last.url.queryParameters['id'], 'in.(renter-one)');
    },
  );

  for (final code in [200, 403]) {
    testWithApi('Viewing PATCH $code without rows preserves Pending state', (
      tester,
    ) async {
      apiResponse = (request) => request.method == 'PATCH'
          ? jsonResponse([], code)
          : managerResponse(request);
      await pumpManager(tester, const ManagerViewingsScreen());
      await tester.tap(find.widgetWithText(ElevatedButton, 'Approve').first);
      await tester.pumpAndSettle();
      expect(find.text('Approved'), findsNothing);
      expect(find.text('Pending'), findsWidgets);
      expect(
        find.text(
          'Unable to update viewing request. Check your access or refresh the list.',
        ),
        findsOneWidget,
      );
    });
  }

  testWithApi(
    'Manager profile displays real identity and logout clears session',
    (tester) async {
      UserSession.fullName = 'My Manager';
      UserSession.email = 'my.manager@example.com';
      await pumpManager(tester);
      await tapTab(tester, 'Profile');
      expect(find.text('My Manager'), findsOneWidget);
      expect(find.text('my.manager@example.com'), findsOneWidget);
      expect(find.text('Property Manager'), findsOneWidget);
      expect(find.text('Partner'), findsNothing);
      expect(find.text('My Favorites'), findsNothing);
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(UserSession.accessToken, isNull);
      expect(UserSession.userId, isNull);
      expect(UserSession.role, isNull);
    },
  );

  testWithApi('Manager screens and form fit a narrow mobile screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpManager(tester);
    expect(tester.takeException(), isNull);
    for (final tab in ['Viewing Requests', 'Profile', 'Properties']) {
      await tapTab(tester, tab);
      expect(tester.takeException(), isNull);
    }
    await tapButton(tester, 'Add Property');
    await fillProperty(tester);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -1400),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await pumpManager(tester, const LoginScreen());
    expect(tester.takeException(), isNull);
  });

  testWithApi('Property form rejects fractional rent before any request', (
    tester,
  ) async {
    await pumpManager(tester, const PropertyFormScreen());
    await fillProperty(tester);
    await tester.enterText(field('Monthly Rent'), '9500.50');
    await tapButton(tester, 'Add Property');

    expect(
      find.text('Monthly rent must be a positive whole number'),
      findsOneWidget,
    );
    expect(apiRequests.where((request) => request.method == 'POST'), isEmpty);
  });

  testWithApi('Manager screens and form fit 2x text', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpManager(tester);
    expect(tester.takeException(), isNull);
    for (final tab in ['Viewing Requests', 'Profile', 'Properties']) {
      await tapTab(tester, tab);
      expect(tester.takeException(), isNull);
    }

    await tapButton(tester, 'Add Property');
    await fillProperty(tester);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -1600),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
