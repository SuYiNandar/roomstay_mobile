import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roomstay_mobile/data/partner_demo_data.dart';
import 'package:roomstay_mobile/screens/login_screen.dart';
import 'package:roomstay_mobile/screens/partner/add_property_screen.dart';
import 'package:roomstay_mobile/screens/partner/partner_main_screen.dart';
import 'package:roomstay_mobile/screens/partner/update_property_screen.dart';
import 'package:roomstay_mobile/theme/app_theme.dart';

Future<void> pumpLogin(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.lightTheme, home: const LoginScreen()),
  );
  await tester.pumpAndSettle();
}

Future<void> loginAsPartner(WidgetTester tester) async {
  await pumpLogin(tester);

  await tester.tap(find.widgetWithText(ElevatedButton, 'Partner'));
  await tester.pump();

  await tester.enterText(
    find.byType(TextFormField).at(0),
    'partner@example.com',
  );
  await tester.enterText(find.byType(TextFormField).at(1), 'password123');

  await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
  await tester.pumpAndSettle();
}

Future<void> pumpPartnerMain(
  WidgetTester tester, {
  double height = 1600,
}) async {
  tester.view.physicalSize = Size(800, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.lightTheme, home: const PartnerMainScreen()),
  );
  await tester.pumpAndSettle();
}

Future<void> tapPartnerTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Future<void> openAddPropertyFromList(WidgetTester tester) async {
  await tapPartnerTab(tester, 'My Properties');

  await tester.tap(find.widgetWithText(ElevatedButton, '+ Add Property'));
  await tester.pumpAndSettle();
}

Future<void> fillPropertyForm(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'Sunny Studio');
  await tester.enterText(find.byType(TextFormField).at(1), 'Ari, Bangkok');
  await tester.enterText(find.byType(TextFormField).at(2), 'Condo');
  await tester.enterText(find.byType(TextFormField).at(3), '7200');
  await tester.enterText(find.byType(TextFormField).at(4), '1');
  await tester.enterText(
    find.byType(TextFormField).at(5),
    'A sunny studio close to the BTS.',
  );
}

void main() {
  setUp(resetPartnerDemoData);

  testWidgets('Login shows only Renter and Partner and defaults to Renter', (
    WidgetTester tester,
  ) async {
    await pumpLogin(tester);

    expect(find.text('Renter'), findsOneWidget);
    expect(find.text('Partner'), findsOneWidget);
    expect(find.text('Admin'), findsNothing);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'renter@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationDestination), findsNWidgets(5));
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('My Viewings'),
      ),
      findsOneWidget,
    );
    expect(find.text('Partner Dashboard'), findsNothing);
  });

  testWidgets('Partner login opens PartnerMainScreen with four tabs', (
    WidgetTester tester,
  ) async {
    await loginAsPartner(tester);

    expect(find.byType(PartnerMainScreen), findsOneWidget);
    expect(find.text('Partner Dashboard'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));

    for (final label in ['Dashboard', 'My Properties', 'Viewings', 'Profile']) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('Partner dashboard shows summary cards and quick actions', (
    WidgetTester tester,
  ) async {
    await pumpPartnerMain(tester);

    expect(find.text('Welcome back, Partner'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Recent Properties'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('Pending Viewings'), findsOneWidget);
    expect(find.text('Total Viewing Requests'), findsOneWidget);
    expect(find.text('Cozy Studio near RSU'), findsOneWidget);
    expect(find.text('Modern Condo near BTS'), findsOneWidget);
    expect(find.text('Family House in Bang Khen'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Add Property'), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'View Requests'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Property'));
    await tester.pumpAndSettle();
    expect(find.byType(AddPropertyScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'View Requests'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Viewing Requests'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('My Properties lists local property records and actions', (
    WidgetTester tester,
  ) async {
    await pumpPartnerMain(tester);
    await tapPartnerTab(tester, 'My Properties');

    expect(find.text('+ Add Property'), findsOneWidget);
    expect(find.text('Cozy Studio near RSU'), findsOneWidget);
    expect(find.text('Modern Condo near BTS'), findsOneWidget);
    expect(find.text('Family House in Bang Khen'), findsOneWidget);
    expect(find.text('Budget Dormitory near BTS'), findsOneWidget);
    expect(find.text('Available'), findsNWidgets(2));
    expect(find.text('Unavailable'), findsNWidgets(2));
    expect(find.widgetWithText(TextButton, 'Edit'), findsNWidgets(4));
    expect(find.widgetWithText(TextButton, 'Delete'), findsNWidgets(4));
  });

  testWidgets('Add Property validates required fields and numbers', (
    WidgetTester tester,
  ) async {
    await pumpPartnerMain(tester);
    await openAddPropertyFromList(tester);

    expect(find.byType(AddPropertyScreen), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Property'));
    await tester.pump();

    expect(find.text('Property name is required'), findsOneWidget);
    expect(find.text('Location is required'), findsOneWidget);
    expect(find.text('Property type is required'), findsOneWidget);
    expect(find.text('Monthly rent is required'), findsOneWidget);
    expect(find.text('Bedrooms are required'), findsOneWidget);
    expect(find.text('Description is required'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Sunny Studio');
    await tester.enterText(find.byType(TextFormField).at(1), 'Ari, Bangkok');
    await tester.enterText(find.byType(TextFormField).at(2), 'Condo');
    await tester.enterText(find.byType(TextFormField).at(3), 'abc');
    await tester.enterText(find.byType(TextFormField).at(4), 'abc');
    await tester.enterText(
      find.byType(TextFormField).at(5),
      'A sunny studio close to the BTS.',
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Property'));
    await tester.pump();

    expect(find.text('Monthly rent must be a number'), findsOneWidget);
    expect(find.text('Bedrooms must be a number'), findsOneWidget);
    expect(partnerProperties.length, 4);
  });

  testWidgets('Add Property creates a local record and returns to the list', (
    WidgetTester tester,
  ) async {
    await pumpPartnerMain(tester);
    await openAddPropertyFromList(tester);
    await fillPropertyForm(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Property'));
    await tester.pump();

    expect(find.text('Property added successfully.'), findsWidgets);
    expect(partnerProperties.length, 5);

    await tester.pumpAndSettle();

    expect(find.byType(AddPropertyScreen), findsNothing);
    expect(find.text('Sunny Studio'), findsOneWidget);

    final addedProperty = partnerProperties.last;
    expect(addedProperty['location'], 'Ari, Bangkok');
    expect(addedProperty['type'], 'Condo');
    expect(addedProperty['monthlyRent'], 7200);
    expect(addedProperty['bedrooms'], 1);
    expect(addedProperty['available'], isTrue);
  });

  testWidgets('Edit Property loads values and saves local changes', (
    WidgetTester tester,
  ) async {
    await pumpPartnerMain(tester);
    await tapPartnerTab(tester, 'My Properties');

    await tester.tap(find.widgetWithText(TextButton, 'Edit').first);
    await tester.pumpAndSettle();

    expect(find.byType(UpdatePropertyScreen), findsOneWidget);
    expect(find.text('Cozy Studio near RSU'), findsOneWidget);
    expect(find.text('Rangsit, Pathum Thani'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Updated Studio');
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Update Property'));
    await tester.pump();

    expect(find.text('Property updated successfully.'), findsWidgets);
    expect(partnerProperties.first['name'], 'Updated Studio');
    expect(partnerProperties.first['available'], isFalse);

    await tester.pumpAndSettle();

    expect(find.byType(UpdatePropertyScreen), findsNothing);
    expect(find.text('Updated Studio'), findsOneWidget);
    expect(find.text('Cozy Studio near RSU'), findsNothing);
  });

  testWidgets('Delete Property removes the record from My Properties', (
    WidgetTester tester,
  ) async {
    await pumpPartnerMain(tester);
    await tapPartnerTab(tester, 'My Properties');

    await tester.tap(find.widgetWithText(TextButton, 'Delete').first);
    await tester.pump();

    expect(find.text('Property deleted successfully.'), findsOneWidget);
    expect(partnerProperties.length, 3);
    expect(find.text('Cozy Studio near RSU'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Delete'), findsNWidgets(3));

    await tester.pumpAndSettle();
  });

  testWidgets('Partner Viewings shows request details and statuses', (
    WidgetTester tester,
  ) async {
    await pumpPartnerMain(tester, height: 3000);
    await tapPartnerTab(tester, 'Viewings');

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Viewing Requests'),
      ),
      findsOneWidget,
    );
    expect(find.text('Su Yi Nandar'), findsOneWidget);
    expect(find.text('Cozy Studio near RSU'), findsNWidgets(2));
    expect(find.text('20/11/2026 at 10:00 AM'), findsOneWidget);
    expect(find.text('I would like to see the room.'), findsOneWidget);
    expect(find.text('Pending'), findsNWidgets(3));
    expect(find.text('Approved'), findsNWidgets(3));
    expect(find.text('Rejected'), findsNWidgets(2));
    expect(find.widgetWithText(ElevatedButton, 'Approve'), findsNWidgets(3));
    expect(find.widgetWithText(ElevatedButton, 'Reject'), findsNWidgets(3));
  });

  testWidgets('Partner approves a pending viewing request', (
    WidgetTester tester,
  ) async {
    await pumpPartnerMain(tester);
    await tapPartnerTab(tester, 'Viewings');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Approve').first);
    await tester.pump();

    expect(find.text('Viewing request approved.'), findsOneWidget);
    expect(partnerViewingRequests.first['status'], 'Approved');
    expect(find.widgetWithText(ElevatedButton, 'Approve'), findsNWidgets(2));

    await tester.pumpAndSettle();
  });

  testWidgets('Partner rejects a pending viewing request', (
    WidgetTester tester,
  ) async {
    await pumpPartnerMain(tester);
    await tapPartnerTab(tester, 'Viewings');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Reject').first);
    await tester.pump();

    expect(find.text('Viewing request rejected.'), findsOneWidget);
    expect(partnerViewingRequests.first['status'], 'Rejected');
    expect(find.widgetWithText(ElevatedButton, 'Reject'), findsNWidgets(2));

    await tester.pumpAndSettle();
  });

  testWidgets('Partner Profile shows demo info, menu actions, and logout', (
    WidgetTester tester,
  ) async {
    await pumpPartnerMain(tester);
    await tapPartnerTab(tester, 'Profile');

    expect(find.text('RoomStay Partner'), findsOneWidget);
    expect(find.text('Role: Partner'), findsOneWidget);
    expect(find.text('partner@example.com'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'My Properties'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Viewing Requests'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Logout'), findsOneWidget);

    await tester.tap(find.widgetWithText(ListTile, 'My Properties'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('My Properties'),
      ),
      findsOneWidget,
    );

    await tapPartnerTab(tester, 'Profile');
    await tester.tap(find.widgetWithText(ListTile, 'Viewing Requests'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Viewing Requests'),
      ),
      findsOneWidget,
    );

    await tapPartnerTab(tester, 'Profile');
    await tester.tap(find.widgetWithText(ListTile, 'Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Renter'), findsOneWidget);
    expect(find.text('Partner'), findsOneWidget);
    expect(find.text('Admin'), findsNothing);
  });

  testWidgets('Partner screens render without overflow on a mobile screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const PartnerMainScreen()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    for (final label in ['My Properties', 'Viewings', 'Profile', 'Dashboard']) {
      await tapPartnerTab(tester, label);
      expect(tester.takeException(), isNull);
    }

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -1200),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
