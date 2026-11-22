import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomstay_mobile/data/user_session.dart';
import 'package:roomstay_mobile/screens/room_detail_screen.dart';
import 'package:roomstay_mobile/theme/app_theme.dart';

import 'support/manager_backend.dart';
import 'support/test_backend.dart';

void main() {
  setUp(resetManagerBackend);
  tearDown(UserSession.clear);

  final cases =
      <String, ({Size size, double scale, String name, String email})>{
        'long manager name': (
          size: const Size(360, 640),
          scale: 1,
          name: 'Very Long Property Manager Name ' * 8,
          email: 'manager@example.com',
        ),
        'long manager email': (
          size: const Size(360, 640),
          scale: 1,
          name: 'Property Manager',
          email: '${'long' * 35}@example.com',
        ),
        'short screen': (
          size: const Size(360, 320),
          scale: 1,
          name: 'Property Manager',
          email: 'manager@example.com',
        ),
        'narrow screen': (
          size: const Size(280, 640),
          scale: 1,
          name: 'Property Manager',
          email: 'manager@example.com',
        ),
        '2x text': (
          size: const Size(360, 640),
          scale: 2,
          name: 'Property Manager',
          email: 'manager@example.com',
        ),
        'long contact narrow short screen 2x text': (
          size: const Size(280, 400),
          scale: 2,
          name: 'Very Long Property Manager Name ' * 8,
          email: '${'long' * 35}@example.com',
        ),
      };
  for (final entry in cases.entries) {
    testWithApi('Contact sheet: ${entry.key}, Copy Email remains usable', (
      tester,
    ) async {
      final data = entry.value;
      tester.view.physicalSize = data.size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = data.scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      String? copiedEmail;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedEmail = (call.arguments as Map)['text'] as String;
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
      apiResponse = (request) => request.url.path == '/rest/v1/profiles'
          ? jsonResponse([
              {'full_name': data.name, 'email': data.email, 'role': 'partner'},
            ])
          : managerResponse(request);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: RoomDetailScreen(
            id: 101,
            isFavorite: false,
            onFavoriteToggle: () async => true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Contact Property Manager'),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final sheet = find.byType(BottomSheet);
      expect(
        find.descendant(of: sheet, matching: find.text(data.name)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.text(data.email)),
        findsOneWidget,
      );
      final copy = find.widgetWithText(ElevatedButton, 'Copy Email');
      await tester.ensureVisible(copy);
      await tester.pumpAndSettle();
      expect(copy.hitTestable(), findsOneWidget);
      await tester.tap(copy);
      await tester.pumpAndSettle();
      expect(copiedEmail, data.email);
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
