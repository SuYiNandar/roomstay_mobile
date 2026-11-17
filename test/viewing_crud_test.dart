import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roomstay_mobile/data/demo_viewings.dart';
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
  setUp(resetDemoViewings);

  testWidgets('My Viewings loads viewing records with actions', (
    WidgetTester tester,
  ) async {
    await pumpMyViewings(tester);

    expect(find.text('Viewing requests'), findsOneWidget);
    expect(find.text('Cozy Studio near RSU'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Edit'), findsNWidgets(3));
    expect(find.widgetWithText(TextButton, 'Cancel'), findsNWidgets(3));
  });

  testWidgets('Edit Viewing loads current values and saves changes', (
    WidgetTester tester,
  ) async {
    await pumpMyViewings(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Edit').first);
    await tester.pumpAndSettle();

    expect(find.byType(UpdateViewingScreen), findsOneWidget);
    expect(find.text('Update viewing'), findsOneWidget);
    expect(find.text('20/11/2026'), findsOneWidget);

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

  testWidgets('Cancel removes a viewing from My Viewings', (
    WidgetTester tester,
  ) async {
    await pumpMyViewings(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel').first);
    await tester.pump();

    expect(find.text('Viewing cancelled successfully.'), findsOneWidget);
    expect(find.text('Cozy Studio near RSU'), findsNothing);
    expect(demoViewings.length, 2);

    await tester.pumpAndSettle();
  });

  testWidgets('Request Viewing creates a record shown in My Viewings', (
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
    expect(
      demoViewings.any(
        (viewing) => viewing['propertyName'] == 'Sunlit Apartment near Ari BTS',
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

    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pumpAndSettle();

    expect(find.text('Sunlit Apartment near Ari BTS'), findsOneWidget);
  });
}
