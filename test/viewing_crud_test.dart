import 'dart:convert';
import 'support/test_backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/demo_viewings.dart';
import 'package:roomstay_mobile/data/viewing_helpers.dart';
import 'package:roomstay_mobile/screens/main_screen.dart';
import 'package:roomstay_mobile/screens/update_viewing_screen.dart';
import 'package:roomstay_mobile/theme/app_theme.dart';

Future<void> pumpMyViewings(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.lightTheme, home: const MainScreen()),
  );
  await tester.pumpAndSettle();

  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('My Viewings'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    resetTestBackend();
  });

  testWithApi('My Viewings loads viewing records with actions', (
    WidgetTester tester,
  ) async {
    await pumpMyViewings(tester);

    expect(find.text('Viewing requests'), findsOneWidget);
    expect(find.text('Cozy Studio near RSU'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Edit'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
  });

  testWithApi('Edit Viewing loads current values and saves changes', (
    WidgetTester tester,
  ) async {
    await pumpMyViewings(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Edit').first);
    await tester.pumpAndSettle();

    expect(find.byType(UpdateViewingScreen), findsOneWidget);
    expect(find.text('Update viewing'), findsOneWidget);
    expect(find.text('20/11/2030'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(2),
      'Updated viewing message',
    );

    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Update Viewing'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Update Viewing'));
    await tester.pump();

    expect(find.text('Viewing updated successfully.'), findsWidgets);
    expect(demoViewings.first['message'], 'Updated viewing message');

    await tester.pumpAndSettle();
  });

  testWithApi('Cancel asks for confirmation and then removes a viewing', (
    WidgetTester tester,
  ) async {
    await pumpMyViewings(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel').first);
    await tester.pumpAndSettle();

    expect(find.text('Cancel viewing?'), findsOneWidget);
    expect(
      find.text('Are you sure you want to cancel this viewing?'),
      findsOneWidget,
    );
    expect(demoViewings.length, 3);

    await tester.tap(find.widgetWithText(TextButton, 'Yes, Cancel'));
    await tester.pump();

    expect(find.text('Viewing cancelled successfully.'), findsOneWidget);
    expect(find.text('Cozy Studio near RSU'), findsNothing);
    expect(demoViewings.length, 2);

    await tester.pumpAndSettle();
  });

  testWithApi('Cancel confirmation can be dismissed with No', (
    WidgetTester tester,
  ) async {
    await pumpMyViewings(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel').first);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'No'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel viewing?'), findsNothing);
    expect(find.text('Cozy Studio near RSU'), findsOneWidget);
    expect(demoViewings.length, 3);
  });

  testWithApi('My Viewings shows the empty state when there are no records', (
    WidgetTester tester,
  ) async {
    demoViewings.clear();

    await pumpMyViewings(tester);

    expect(find.text('No viewing requests yet.'), findsOneWidget);
    expect(find.text('Choose a room and request a viewing.'), findsOneWidget);
  });

  testWithApi('Request Viewing creates a record shown in My Viewings', (
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
    await tester.tap(find.text('Sunlit Apartment near Ari BTS'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Request Viewing'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextFormField).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextFormField).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(2),
      'Looking forward to the viewing.',
    );

    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Submit Request'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Request'));
    await tester.pump();

    expect(find.text('Viewing request submitted successfully.'), findsWidgets);
    final request = apiRequests.firstWhere(
      (request) =>
          request.method == 'POST' && request.url.path == '/rest/v1/viewings',
    );
    final body = jsonDecode(request.body);
    expect(body['renter_id'], 'test-user-id');
    expect(body['property_id'], 4);
    expect(body['viewing_date'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    expect(body['viewing_time'], matches(RegExp(r'^\d{2}:\d{2}:00$')));
    expect(request.headers['Authorization'], 'Bearer test-access-token');

    expect(
      demoViewings.any(
        (viewing) =>
            viewingPropertyName(viewing) == 'Sunlit Apartment near Ari BTS',
      ),
      isTrue,
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('My Viewings'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sunlit Apartment near Ari BTS'), findsOneWidget);
  });
}
