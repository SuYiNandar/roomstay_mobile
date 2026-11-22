# RoomStay final source checklist

Inventory checked on 22 November 2026 using `git status`, `git ls-files` and `git ls-files --others --exclude-standard`. **PASS for inventory/secret screening; commit and final submission remain pending.** No automatic staging, commit, push or deletion was performed.

The Git index contains 164 tracked paths, including paths now deleted in the working tree. There is one historical commit. Many current implementation files are untracked. `git archive HEAD` would therefore omit tested functionality; use a deliberate reviewed commit or complete source export.

## Files that must be committed

- [ ] Current `lib/`, including config, session/helpers, manager screens and shared form.
- [ ] `assets/`, `test/` (including fixtures/support/legacy tests), and `docs/`.
- [ ] `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `.metadata`, `.gitignore` and existing platform/project build configuration.
- [ ] `android/` and `ios/` source/configuration, including main INTERNET permission and iOS photo usage description. Retain project-owned generated plugin registrants that are already tracked; do not confuse these with caches.
- [ ] README.md and FINAL_PROJECT_AUDIT.md; review CLEANUP_REPORT.md as historical context, not current acceptance evidence.
- [ ] Intentional deletions of old runtime demo data and Partner prototype screens. Their test-only equivalents are under `test/`; do not resurrect production demo branches from HEAD.
- [ ] Existing Linux/macOS/Windows tracked project/plugin files if submitting the full Flutter project, even though only Android is validated.

Review `git diff --stat`, `git diff` and all untracked files before staging intentionally. Do not blindly stage secrets or caches. The publishable client key is public configuration; a private backend credential is never a substitute.

## Files that must NOT be committed

- `build/`, `.dart_tool/`, `.gradle/`, Pods/ephemeral build output, temporary audit logs or screenshots generated for diagnosis.
- `.env` / `.env.*` with real credentials. Root .gitignore now excludes them; `.env.example` may contain placeholders only.
- `android/local.properties`, `android/key.properties`, signing `.jks`/`.keystore`, private keys, account passwords, access/refresh tokens, service-role/secret keys and database connection passwords.
- Local IDE caches such as `.idea/`, OS junk and machine-specific SDK paths. Android's existing ignore rules cover local/signing configuration.

No tracked build/, .dart_tool/, .env, .idea/.gradle cache, local.properties, key.properties or signing keystore path was found by the tracked-file check. Ignore rules do not remove a file already tracked; review again immediately before committing.

## Untracked important files

These were present and ready for deliberate review/inclusion at the inventory check. Paths remain untracked until you stage/commit them.

- [ ] `CLEANUP_REPORT.md`
- [ ] `FINAL_PROJECT_AUDIT.md`
- [ ] `docs/FINAL_DEMO_CHECKLIST.md`
- [ ] `docs/FINAL_SOURCE_CHECKLIST.md`
- [ ] `docs/SECURITY_LIVE_TEST_CHECKLIST.md`
- [ ] `docs/property_images_storage_setup.sql`
- [ ] `docs/property_manager_supabase.md`
- [ ] `lib/config/supabase_config.dart`
- [ ] `lib/data/favorite_helpers.dart`
- [ ] `lib/data/user_session.dart`
- [ ] `lib/data/viewing_helpers.dart`
- [ ] `lib/screens/manager_properties_screen.dart`
- [ ] `lib/screens/manager_viewings_screen.dart`
- [ ] `lib/screens/property_form_screen.dart`
- [ ] `lib/screens/property_manager_main_screen.dart`
- [ ] `test/contact_manager_sheet_test.dart`
- [ ] `test/favorites_runtime_test.dart`
- [ ] `test/favorites_test.dart`
- [ ] `test/final_submission_test.dart`
- [ ] `test/home_search_categories_test.dart`
- [ ] `test/fixtures/demo_viewings.dart`
- [ ] `test/fixtures/partner_demo_data.dart`
- [ ] `test/fixtures/sample_properties.dart`
- [ ] `test/manager_authorization_test.dart`
- [ ] `test/project_audit_test.dart`
- [ ] `test/property_form_media_test.dart`
- [ ] `test/property_manager_test.dart`
- [ ] `test/property_mapping_test.dart`
- [ ] `test/submission_fixes_test.dart`
- [ ] `test/support/legacy_partner/add_property_screen.dart`
- [ ] `test/support/legacy_partner/my_properties_screen.dart`
- [ ] `test/support/legacy_partner/partner_dashboard_screen.dart`
- [ ] `test/support/legacy_partner/partner_main_screen.dart`
- [ ] `test/support/legacy_partner/partner_profile_screen.dart`
- [ ] `test/support/legacy_partner/partner_viewings_screen.dart`
- [ ] `test/support/legacy_partner/update_property_screen.dart`
- [ ] `test/support/manager_backend.dart`
- [ ] `test/support/test_backend.dart`
- [ ] `test/viewing_helpers_test.dart`

## Potential secret-risk files

| File | Type of secret | Severity | Recommended action |
|---|---|---|---|
| `lib/config/supabase_config.dart` | No privileged secret found; URL/publishable key are intentional public configuration | Informational | Commit only public client config; never substitute a service key |
| `README.md`, `CLEANUP_REPORT.md`, this checklist | Documentation mentions of secret categories; no credential finding | Informational | Keep examples/placeholders free of real credentials |
| Local `.env`, `key.properties`, signing keystores (if created later) | Potential environment/signing credentials; none found tracked | Preventive | Keep ignored/private; rotate any accidentally exposed real secret |
| Current scanned source/config/docs/tests | No high-confidence service-role JWT, secret key, credential URI, private key, or secret assignment found | No confirmed finding | Repeat review before publication; pattern scans are not proof of absence |

Sensitive values are deliberately omitted. Security keyword matches in documentation are not treated as leaked credentials. The scan includes ignored local text files while excluding Git internals, build/cache/vendor output and binary files. No live credentials or policies were altered.

## Clean source verification

- [ ] Create a reviewed commit or source archive containing current tracked AND required untracked files, respecting intentional deletions.
- [ ] Extract/clone into an empty directory; do not copy .dart_tool or build output.
- [ ] Run `flutter pub get`, `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, `flutter test` and `flutter build apk --debug` there.
- [ ] Build release and verify the submitted APK matches that source.
- [ ] Rehearse live flows on that exact APK and record source identifier/APK checksum privately.

**Historical clean source export verification (before the final audit): PASS.** A temporary directory was populated from current tracked files plus nonignored untracked files, excluding deleted paths and project build/.dart_tool caches (190 source files at export time). `flutter pub get --offline`, `flutter analyze`, `flutter test` (173 passed) and `flutter build apk --debug` all succeeded there. This proved that exported source was buildable; it does not make HEAD current or verify a remote clone. The installed SDK and shared dependency/Gradle caches were available. That earlier export does not certify the newer Home category and pre-submission fixes. Re-export the current working tree for the final package; the latest audit records current local test/build results.

Before actual submission, still create and verify the deliberate final commit/archive and retain its matching APK. No staging, commit or push was performed.
