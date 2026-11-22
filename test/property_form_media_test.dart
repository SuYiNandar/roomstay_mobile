import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:roomstay_mobile/data/user_session.dart';
import 'package:roomstay_mobile/screens/property_form_screen.dart';

import 'property_manager_test.dart' show pumpManager, fillProperty, tapButton;
import 'support/manager_backend.dart';
import 'support/test_backend.dart';

final photoBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9yoAAAAASUVORK5CYII=',
);

class FakeGallery extends ImagePickerPlatform {
  XFile? photo;
  PlatformException? error;
  ImageSource? source;
  ImagePickerOptions? options;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    this.source = source;
    this.options = options;
    if (error != null) throw error!;
    return photo;
  }
}

Future<void> tapPhoto(WidgetTester tester, [String label = 'Add Photo']) async {
  final button = find.widgetWithText(OutlinedButton, label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> tapChip(WidgetTester tester, String label) async {
  final chip = find.widgetWithText(FilterChip, label);
  await tester.ensureVisible(chip);
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

bool isUpload(http.Request request) =>
    request.url.path.startsWith('/storage/v1/object/property-images/');

void main() {
  late ImagePickerPlatform originalPicker;
  late FakeGallery gallery;

  setUp(() {
    resetManagerBackend();
    originalPicker = ImagePickerPlatform.instance;
    gallery = FakeGallery();
    ImagePickerPlatform.instance = gallery;
    apiResponse = (request) => isUpload(request)
        ? jsonResponse({'Key': request.url.path}, 200)
        : managerResponse(request);
  });
  tearDown(() {
    ImagePickerPlatform.instance = originalPicker;
    UserSession.clear();
  });

  testWithApi(
    'Form shows facility chips and photo UI without manual text inputs',
    (tester) async {
      await pumpManager(tester, const PropertyFormScreen());
      expect(
        find.widgetWithText(TextFormField, 'Facilities (optional)'),
        findsNothing,
      );
      expect(
        find.widgetWithText(TextFormField, 'Image URL (optional)'),
        findsNothing,
      );
      expect(find.byType(FilterChip), findsNWidgets(10));
      expect(find.widgetWithText(FilterChip, 'Pet friendly'), findsNothing);
      for (final chip in tester.widgetList<FilterChip>(
        find.byType(FilterChip),
      )) {
        expect(chip.selected, isFalse);
      }
      expect(find.text('Property Photo'), findsOneWidget);
      expect(find.text('Add Photo'), findsOneWidget);
      expect(find.text('Choose from gallery'), findsOneWidget);
      expect(find.text('Remove'), findsNothing);
    },
  );

  testWithApi('Facility selection and deselection send an array', (
    tester,
  ) async {
    await pumpManager(tester);
    await tapButton(tester, 'Add Property');
    await fillProperty(tester);
    await tapChip(tester, 'Parking');
    await tapChip(tester, 'Air Conditioner');
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'Parking'))
          .selected,
      isFalse,
    );
    await tapButton(tester, 'Add Property');
    final post = apiRequests.firstWhere((r) => r.method == 'POST');
    expect(jsonDecode(post.body)['facilities'], ['Wi-Fi', 'Air Conditioner']);
    expect(jsonDecode(post.body)['image_url'], isNull);
    expect(apiRequests.where(isUpload), isEmpty);
  });

  testWithApi(
    'Edit preselects and preserves existing facility labels exactly',
    (tester) async {
      managerProperties.first['facilities'] = [
        'Wi-Fi',
        'Roof garden',
        'Air conditioning',
      ];
      await pumpManager(tester, const PropertyFormScreen(propertyId: 101));
      for (final label in ['Wi-Fi', 'Roof garden', 'Air conditioning']) {
        expect(
          tester
              .widget<FilterChip>(find.widgetWithText(FilterChip, label))
              .selected,
          isTrue,
        );
      }
      await tapButton(tester, 'Update Property');
      final patch = apiRequests.firstWhere((r) => r.method == 'PATCH');
      expect(jsonDecode(patch.body)['facilities'], [
        'Wi-Fi',
        'Roof garden',
        'Air conditioning',
      ]);
    },
  );

  testWithApi(
    'Cancelled gallery and empty facilities still allow an optional-photo save',
    (tester) async {
      await pumpManager(tester);
      await tapButton(tester, 'Add Property');
      await fillProperty(tester);
      await tapChip(tester, 'Wi-Fi');
      await tapChip(tester, 'Parking');
      await tapPhoto(tester);
      expect(find.text('Add Photo'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      await tapButton(tester, 'Add Property');
      final save = apiRequests.firstWhere((r) => r.method == 'POST');
      expect(jsonDecode(save.body)['facilities'], isEmpty);
      expect(jsonDecode(save.body)['image_url'], isNull);
      expect(apiRequests.where(isUpload), isEmpty);
    },
  );

  testWithApi('Invalid form does not upload a selected photo', (tester) async {
    gallery.photo = XFile.fromData(photoBytes, name: 'photo.png');
    await pumpManager(tester, const PropertyFormScreen());
    await tapPhoto(tester);
    await tapButton(tester, 'Add Property');
    expect(find.text('Property name is required'), findsOneWidget);
    expect(apiRequests, isEmpty);
    expect(find.text('Change Photo'), findsOneWidget);
  });

  testWithApi(
    'Legacy bedrooms above 5 require selection without crashing or silently changing the row',
    (tester) async {
      managerProperties.first['bedrooms'] = 10;
      await pumpManager(tester, const PropertyFormScreen(propertyId: 101));
      expect(tester.takeException(), isNull);
      expect(find.text('10 Bedrooms'), findsNothing);
      await tapButton(tester, 'Update Property');
      expect(find.text('Please select bedrooms'), findsOneWidget);
      expect(apiRequests.where((r) => r.method == 'PATCH'), isEmpty);
    },
  );

  testWithApi('Edit keeps its existing photo when no replacement is selected', (
    tester,
  ) async {
    const url = 'https://example.com/existing.png';
    managerProperties.first['image_url'] = url;
    await pumpManager(tester, const PropertyFormScreen(propertyId: 101));
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as NetworkImage).url, url);
    expect(find.text('Change Photo'), findsOneWidget);
    await tapButton(tester, 'Update Property');
    final patch = apiRequests.firstWhere((r) => r.method == 'PATCH');
    expect(jsonDecode(patch.body)['image_url'], url);
    expect(apiRequests.where(isUpload), isEmpty);
  });

  testWithApi(
    'Remove clears existing image_url without deleting Storage objects',
    (tester) async {
      managerProperties.first['image_url'] = 'https://example.com/existing.png';
      await pumpManager(tester, const PropertyFormScreen(propertyId: 101));
      final remove = find.widgetWithText(TextButton, 'Remove');
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(find.text('Add Photo'), findsOneWidget);
      await tapButton(tester, 'Update Property');
      final patch = apiRequests.firstWhere((r) => r.method == 'PATCH');
      expect(jsonDecode(patch.body)['image_url'], isNull);
      expect(
        apiRequests.where((r) => r.method == 'DELETE' || isUpload(r)),
        isEmpty,
      );
    },
  );

  for (final editing in [false, true]) {
    testWithApi(
      '${editing ? 'Edit' : 'Add'} uploads selected photo before saving its public URL',
      (tester) async {
        gallery.photo = XFile.fromData(
          photoBytes,
          name: '../../someone-else/photo.png',
        );
        if (editing) {
          managerProperties.first['image_url'] = 'https://example.com/old.png';
          await pumpManager(tester, const PropertyFormScreen(propertyId: 101));
        } else {
          await pumpManager(tester);
          await tapButton(tester, 'Add Property');
          await fillProperty(tester);
        }
        await tapPhoto(tester, editing ? 'Change Photo' : 'Add Photo');
        expect(gallery.source, ImageSource.gallery);
        expect(gallery.options!.requestFullMetadata, isFalse);
        expect(find.text('Change Photo'), findsOneWidget);
        expect(
          tester.widget<Image>(find.byType(Image).last).image,
          isA<MemoryImage>(),
        );
        await tapButton(tester, editing ? 'Update Property' : 'Add Property');
        final upload = apiRequests.singleWhere(isUpload);
        expect(upload.method, 'POST');
        expect(
          upload.url.path,
          matches(
            r'^/storage/v1/object/property-images/test-user-id/\d+\.png$',
          ),
        );
        expect(upload.headers['Authorization'], 'Bearer test-access-token');
        expect(upload.headers['apikey'], isNotEmpty);
        expect(upload.headers['Content-Type'], 'image/png');
        expect(upload.headers['x-upsert'], 'false');
        expect(upload.bodyBytes, photoBytes);
        final save = apiRequests.firstWhere(
          (r) =>
              r.url.path == '/rest/v1/properties' &&
              r.method == (editing ? 'PATCH' : 'POST'),
        );
        expect(
          apiRequests.indexOf(upload),
          lessThan(apiRequests.indexOf(save)),
        );
        expect(
          jsonDecode(save.body)['image_url'],
          upload.url.toString().replaceFirst('/object/', '/object/public/'),
        );
      },
    );
  }

  testWithApi('Cancelling Change Photo preserves the existing image', (
    tester,
  ) async {
    managerProperties.first['image_url'] = 'https://example.com/existing.png';
    await pumpManager(tester, const PropertyFormScreen(propertyId: 101));
    await tapPhoto(tester, 'Change Photo');
    expect(find.text('Change Photo'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    await tapButton(tester, 'Update Property');
    expect(
      jsonDecode(
        apiRequests.firstWhere((r) => r.method == 'PATCH').body,
      )['image_url'],
      'https://example.com/existing.png',
    );
  });

  testWithApi('Picker permission failure shows an error without uploading', (
    tester,
  ) async {
    gallery.error = PlatformException(code: 'photo_access_denied');
    await pumpManager(tester, const PropertyFormScreen());
    await tapPhoto(tester);
    expect(
      find.text(
        'Unable to choose photo. Check your gallery permission and try again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Add Photo'), findsOneWidget);
    expect(apiRequests, isEmpty);
  });

  for (final networkError in [false, true]) {
    testWithApi(
      'Upload ${networkError ? 'network' : 'API'} failure prevents property save',
      (tester) async {
        gallery.photo = XFile.fromData(photoBytes, name: 'photo.png');
        apiResponse = (request) {
          if (isUpload(request)) {
            if (networkError) throw http.ClientException('Offline');
            return jsonResponse({'message': 'Denied'}, 403);
          }
          return managerResponse(request);
        };
        await pumpManager(tester, const PropertyFormScreen());
        await fillProperty(tester);
        await tapPhoto(tester);
        await tapButton(tester, 'Add Property');
        expect(find.text('Unable to upload property photo.'), findsOneWidget);
        expect(find.text('Property added successfully.'), findsNothing);
        expect(
          apiRequests.where(
            (r) => r.url.path == '/rest/v1/properties' && r.method == 'POST',
          ),
          isEmpty,
        );
        expect(find.text('Change Photo'), findsOneWidget);
      },
    );
  }

  testWithApi(
    'Failed property save retains uploaded URL for retry without a second upload',
    (tester) async {
      gallery.photo = XFile.fromData(photoBytes, name: 'photo.png');
      var failSave = true;
      apiResponse = (request) {
        if (isUpload(request)) return jsonResponse({'Key': request.url.path});
        if (failSave && request.method == 'POST') return jsonResponse({}, 500);
        return managerResponse(request);
      };
      await pumpManager(tester);
      await tapButton(tester, 'Add Property');
      await fillProperty(tester);
      await tapPhoto(tester);
      await tapButton(tester, 'Add Property');
      expect(find.text('Unable to add property.'), findsOneWidget);
      expect(find.text('Property added successfully.'), findsNothing);
      failSave = false;
      await tapButton(tester, 'Add Property');
      expect(apiRequests.where(isUpload).length, 1);
      final saves = apiRequests
          .where(
            (r) => r.url.path == '/rest/v1/properties' && r.method == 'POST',
          )
          .toList();
      expect(
        jsonDecode(saves[0].body)['image_url'],
        jsonDecode(saves[1].body)['image_url'],
      );
      expect(find.text('Property added successfully.'), findsOneWidget);
    },
  );

  testWithApi('Upload prevents duplicate submission until confirmed', (
    tester,
  ) async {
    gallery.photo = XFile.fromData(photoBytes, name: 'photo.png');
    final result = Completer<http.Response>();
    apiResponse = (request) =>
        isUpload(request) ? result.future : managerResponse(request);
    await pumpManager(tester);
    await tapButton(tester, 'Add Property');
    await fillProperty(tester);
    await tapPhoto(tester);
    final save = find.widgetWithText(ElevatedButton, 'Add Property');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton).last).onPressed,
      isNull,
    );
    expect(apiRequests.where(isUpload).length, 1);
    expect(
      apiRequests.where(
        (r) => r.url.path == '/rest/v1/properties' && r.method == 'POST',
      ),
      isEmpty,
    );
    result.complete(jsonResponse({'Key': 'uploaded'}));
    await tester.pumpAndSettle();
    expect(find.text('Property added successfully.'), findsOneWidget);
  });

  testWithApi('Photo preview and selected chips fit a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    gallery.photo = XFile.fromData(photoBytes, name: 'photo.png');
    await pumpManager(tester, const PropertyFormScreen());
    await fillProperty(tester);
    await tapPhoto(tester);
    expect(tester.takeException(), isNull);
    final remove = find.widgetWithText(TextButton, 'Remove');
    await tester.ensureVisible(remove);
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(find.text('Add Photo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
