import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:roomstay_mobile/data/user_session.dart';
import 'package:roomstay_mobile/screens/manager_properties_screen.dart';
import 'package:roomstay_mobile/screens/manager_viewings_screen.dart';
import 'package:roomstay_mobile/screens/my_viewings_screen.dart';
import 'package:roomstay_mobile/screens/property_form_screen.dart';

import 'property_form_media_test.dart'
    show FakeGallery, photoBytes, tapPhoto, isUpload;
import 'property_manager_test.dart'
    show pumpManager, fillProperty, tapButton, deleteFirst, expectAuth, field;
import 'support/manager_backend.dart';
import 'support/test_backend.dart';

void main() {
  setUp(resetManagerBackend);
  tearDown(UserSession.clear);

  for (final role in ['partner', 'property_manager']) {
    testWithApi('$role Manager A edits own property with ID and owner filter', (
      tester,
    ) async {
      UserSession.role = role;
      await pumpManager(tester, const PropertyFormScreen(propertyId: 101));
      await tester.enterText(field('Monthly Rent'), '9000');
      await tapButton(tester, 'Update Property');
      final request = apiRequests.singleWhere((r) => r.method == 'PATCH');
      expectAuth(request);
      expect(request.url.queryParameters['id'], 'eq.101');
      expect(request.url.queryParameters['partner_id'], 'eq.test-user-id');
      expect(jsonDecode(request.body).containsKey('partner_id'), isFalse);
      expect(managerProperties.first['monthly_rent'], 9000);
      expect(managerProperties.last['monthly_rent'], 8000);
    });

    testWithApi(
      '$role Manager A cannot edit Manager B property by direct route',
      (tester) async {
        UserSession.role = role;
        await pumpManager(tester, const PropertyFormScreen(propertyId: 999));
        expect(find.byType(Form), findsNothing);
        expect(
          find.text('Property not found or you do not have access.'),
          findsOneWidget,
        );
        expect(
          apiRequests.single.url.queryParameters['partner_id'],
          'eq.test-user-id',
        );
        expect(apiRequests.where((r) => r.method == 'PATCH'), isEmpty);
        expect(managerProperties.last['partner_id'], 'other-manager');
      },
    );

    testWithApi(
      '$role Manager A deletes own property with ID and owner filter',
      (tester) async {
        UserSession.role = role;
        await pumpManager(tester, const ManagerPropertiesScreen());
        await deleteFirst(tester);
        await tester.tap(find.widgetWithText(TextButton, 'Delete').last);
        await tester.pumpAndSettle();
        final request = apiRequests.singleWhere((r) => r.method == 'DELETE');
        expectAuth(request);
        expect(request.url.queryParameters['id'], 'eq.101');
        expect(request.url.queryParameters['partner_id'], 'eq.test-user-id');
        expect(managerProperties.any((p) => p['id'] == 101), isFalse);
        expect(managerProperties.any((p) => p['id'] == 999), isTrue);
      },
    );

    testWithApi('$role stale Delete cannot delete a property now owned by B', (
      tester,
    ) async {
      UserSession.role = role;
      await pumpManager(tester, const ManagerPropertiesScreen());
      managerProperties.first['partner_id'] = 'other-manager';
      await deleteFirst(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Delete').last);
      await tester.pumpAndSettle();
      final request = apiRequests.singleWhere((r) => r.method == 'DELETE');
      expect(request.url.queryParameters['partner_id'], 'eq.test-user-id');
      expect(managerProperties.any((p) => p['id'] == 101), isTrue);
      expect(find.text('Unable to delete property.'), findsOneWidget);
    });

    for (final status in ['Approved', 'Rejected']) {
      final label = status == 'Approved' ? 'Approve' : 'Reject';
      final buttonType = status == 'Approved' ? ElevatedButton : OutlinedButton;
      testWithApi('$role Manager A can $label own property viewing', (
        tester,
      ) async {
        UserSession.role = role;
        await pumpManager(tester, const ManagerViewingsScreen());
        await tester.tap(find.widgetWithText(buttonType, label).first);
        await tester.pumpAndSettle();
        final patch = apiRequests.singleWhere((r) => r.method == 'PATCH');
        expectAuth(patch);
        expect(patch.url.queryParameters, {
          'id': 'eq.101',
          'property_id': 'eq.101',
          'status': 'eq.Pending',
        });
        expect(jsonDecode(patch.body), {'status': status});
        expect(managerViewings.first['status'], status);
        expect(managerViewings.last['status'], 'Pending');
      });

      testWithApi(
        '$role Manager A cannot $label a viewing whose property belongs to B',
        (tester) async {
          UserSession.role = role;
          await pumpManager(tester, const ManagerViewingsScreen());
          managerProperties.first['partner_id'] = 'other-manager';
          await tester.tap(find.widgetWithText(buttonType, label).first);
          await tester.pumpAndSettle();
          final check = apiRequests.last;
          expect(check.url.queryParameters['id'], 'eq.101');
          expect(check.url.queryParameters['partner_id'], 'eq.test-user-id');
          expect(apiRequests.where((r) => r.method == 'PATCH'), isEmpty);
          expect(managerViewings.first['status'], 'Pending');
        },
      );
    }
  }

  for (final screen in <String, Widget>{
    'Add property': const PropertyFormScreen(),
    'Edit property': const PropertyFormScreen(propertyId: 101),
    'Properties': const ManagerPropertiesScreen(),
    'Viewing decisions': const ManagerViewingsScreen(),
  }.entries) {
    testWithApi('Renter cannot mutate through manager ${screen.key} flow', (
      tester,
    ) async {
      UserSession.role = 'renter';
      await pumpManager(tester, screen.value);
      if (screen.key == 'Add property') {
        await fillProperty(tester);
        await tapButton(tester, 'Add Property');
      }
      expect(find.text('Please log in as a property manager.'), findsOneWidget);
      expect(apiRequests, isEmpty);
    });
  }

  testWithApi(
    'Changing account while Delete dialog is open sends no mutation',
    (tester) async {
      await pumpManager(tester, const ManagerPropertiesScreen());
      await deleteFirst(tester);
      UserSession.userId = 'other-manager';
      await tester.tap(find.widgetWithText(TextButton, 'Delete').last);
      await tester.pumpAndSettle();
      expect(apiRequests.where((r) => r.method == 'DELETE'), isEmpty);
      expect(managerProperties.length, 3);
    },
  );

  for (final label in ['Approve', 'Reject']) {
    testWithApi('Renter role during $label ownership check blocks PATCH', (
      tester,
    ) async {
      await pumpManager(tester, const ManagerViewingsScreen());
      final pending = Completer<http.Response>();
      apiResponse = (request) => request.url.path == '/rest/v1/properties'
          ? pending.future
          : managerResponse(request);
      await tester.tap(
        find
            .widgetWithText(
              label == 'Approve' ? ElevatedButton : OutlinedButton,
              label,
            )
            .first,
      );
      await tester.pump();
      UserSession.role = 'renter';
      pending.complete(jsonResponse([managerProperties.first]));
      await tester.pumpAndSettle();
      expect(apiRequests.where((r) => r.method == 'PATCH'), isEmpty);
      expect(managerViewings.first['status'], 'Pending');
    });
  }

  for (final change in ['role', 'account']) {
    testWithApi(
      'Changing $change during photo upload blocks property mutation',
      (tester) async {
        final original = ImagePickerPlatform.instance;
        ImagePickerPlatform.instance = FakeGallery()
          ..photo = XFile.fromData(photoBytes, name: 'photo.png');
        addTearDown(() => ImagePickerPlatform.instance = original);
        final upload = Completer<http.Response>();
        apiResponse = (request) =>
            isUpload(request) ? upload.future : managerResponse(request);
        await pumpManager(tester, const PropertyFormScreen());
        await fillProperty(tester);
        await tapPhoto(tester);
        final save = find.widgetWithText(ElevatedButton, 'Add Property');
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pump();
        final request = apiRequests.singleWhere(isUpload);
        expectAuth(request);
        expect(
          request.url.path,
          startsWith('/storage/v1/object/property-images/test-user-id/'),
        );
        if (change == 'role') {
          UserSession.role = 'renter';
        } else {
          UserSession.userId = 'other-manager';
        }
        upload.complete(jsonResponse({'Key': request.url.path}));
        await tester.pumpAndSettle();
        expect(
          apiRequests.where(
            (r) => r.url.path == '/rest/v1/properties' && r.method != 'GET',
          ),
          isEmpty,
        );
        expect(
          find.text('Please log in as a property manager.'),
          findsOneWidget,
        );
      },
    );
  }

  for (final status in ['Approved', 'Rejected']) {
    testWithApi('$status renter viewing has neither Edit nor Cancel', (
      tester,
    ) async {
      managerViewings.first['status'] = status;
      UserSession.userId = 'renter-one';
      UserSession.role = 'renter';
      await pumpManager(tester, const MyViewingsScreen());
      final card = find.ancestor(
        of: find.text('Manager property 101'),
        matching: find.byType(Card),
      );
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text(status)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('Edit')),
        findsNothing,
      );
      expect(
        find.descendant(of: card, matching: find.text('Cancel')),
        findsNothing,
      );
    });
  }
}
