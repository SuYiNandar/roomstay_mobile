# RoomStay — Final Pre-Submission Audit

**CSC452 · 22 November 2026 · Asia/Bangkok**

Scope: the actual current working tree, including untracked source, tests, assets, documentation and Android/iOS configuration. Direct HTTP, setState/controllers, Forms and Navigator are intentional university-project choices and are not penalized for lacking enterprise architecture.

Evidence labels:

- **Inspected/tested:** code, local mocked regressions, render probes and builds examined in this audit.
- **User-reported live:** successful Supabase checks supplied in the final audit request; accepted as evidence with attribution, not independently repeated here.
- **Not verified:** claims that need an actual deployed configuration/device/data inspection. No live database, RLS, account, Storage or schema was changed.

## A. FINAL VERDICT

**ALMOST READY — 95% complete — estimated overall score 8.3/10.**

No submission-blocking code defect or privileged secret was demonstrated. The baseline was independently confirmed at **190 passing tests**, clean analysis and successful debug/release builds. The recent Home category fix works and is covered by 17 integration-style widget tests. The supplied live property/viewing/Storage denial results materially improve security confidence and close several previously unverified claims.

The remaining submission gate is to freeze/package the complete current source and match it to the final APK, then complete the short final-device presentation rehearsal. A Git-only submission of HEAD currently omits much of the working app. The app is suitable for a controlled Android classroom demonstration; this is not a claim of production readiness or iOS certification.

### Low-risk fixes made in this audit

1. Search now rejects minimum rent above maximum rent. Inline, announced guidance explains the error; Show Results is disabled until corrected/reset. Equal bounds and unbounded ranges remain valid.
2. Favorites empty/error content is scrollable. A reproduced 60px bottom overflow at 360×320 and 2× text is resolved; Retry and guidance remain reachable.
3. Clipboard exceptions are handled. Failure dismisses the contact sheet and shows a visible, concise error; reopening and retrying succeeds. The existing successful-copy and responsive contact tests remain intact.
4. Error red and Home accent foreground were darkened without changing the primary purple, canvas, layout or component hierarchy. Calculated error-on-white contrast improves from 3.76:1 to 6.47:1; large Home accent-on-canvas from 2.54:1 to 4.36:1.
5. README/setup/checklist inaccuracies were corrected: actual database roles, working category filters, user-reported live evidence and remaining checks. Storage SQL changes are comments only; executable SQL is unchanged.
6. Added five focused regressions. No existing test was changed or removed.

No authentication/session/ownership architecture, endpoints, CRUD behavior, status rules, schema, policies, dependencies or signing settings were changed. No commit or push was made.

## B. SCORECARD

Scores are judgment-based university-project estimates, not coverage percentages or a guaranteed instructor grade.

| Category | Score /10 | Reason | What prevents 10/10 |
|---|---:|---|---|
| Functionality | 8.8 | Both roles, owned CRUD, photos, favorites, filtering, contact and viewing decisions implemented; category/range behavior verified | Forgot-password placeholder; named-area shortcuts do not prefill; duplicate viewing prevention limited |
| Code Quality | 8.0 | Clear direct-REST design, shared form, scoped requests, mounted checks and focused tests | Large Search/Detail widgets, repeated request/error code, magic-string options and unused legacy model fields |
| UI/UX | 8.3 | Consistent identity, responsive contact, 48px hearts, visible selected filters, safe short Favorites states and improved contrast | Terse manager empty states, lost Search tab state, default launcher icon, some truncated long content and placeholders |
| Security | 8.3 | No detected privileged secrets; protected client flows plus supplied live property/viewing/Storage denial evidence | No deployed policy/grant/trigger export inspected; profiles/favorites denial cases and token lifecycle incompletely evidenced |
| Database/API Integration | 8.5 | Real field payloads, JWT owner operations, correct joins/status capitalization, tested upload retry/preservation | Integer model loses external decimal rent; some mutations trust status only; no complete reproducible schema contract |
| Testing | 8.7 | All original regressions preserved, five useful additions, 65 layout probes and Android builds | Mostly mocked tests, no line/branch coverage measurement, no physical-device/iOS integration suite |
| Error Handling | 7.5 | Loading/empty/error separation, retries, mutation guards, upload failure handling and clipboard recovery | No request deadline/shared 401 recovery, some inline+snackbar duplication, Auth can display server-provided messages |
| Demo/Presentation Readiness | 8.4 | Runnable APKs, documented flow and fallback, meaningful user-reported live success | Uncommitted/untracked source, final exact-APK rehearsal, demo data cleanup and default icon |
| Creativity | 8.0 | Coherent branded renter/manager workflow with realistic scoped photo/viewing integration | Familiar rental-app concept; limited distinctive interaction beyond sound execution |
| **Overall Final Project Score** | **8.3** | Rounded mean of the nine category scores (74.5/9) | Practical submission packaging and the remaining documented limits |

## C. P0 BLOCKERS

**NONE demonstrated.** Baseline and post-fix commands are recorded below. No known broken core route, build blocker, unconditional main-flow crash, runtime fake favorites or privileged credential was found.

This verdict is scoped to the tested source and supplied evidence. It is not proof that every possible server/device/data combination works.

## D. P1 FIX BEFORE SUBMISSION

### P1-1 — Submit the actual tested source, not the historical Git snapshot

**Files:** all current implementation/tests/docs, particularly untracked `lib/config/`, session/helpers, manager screens/shared form, test fixtures/support and new regression files. See section K and `docs/FINAL_SOURCE_CHECKLIST.md` for the exact inventory.

There is one reachable historical commit. Many current files are modified/untracked, while obsolete runtime demo/Partner files are intentionally deleted. `git archive HEAD` or an incomplete copy would omit functioning code. Review, deliberately commit or archive the complete current tree, preserve intentional deletions and verify the packaged source. Do not automatically restore old demo files.

### P1-2 — Finish the exact-APK presentation rehearsal and preserve live evidence

**Files:** `docs/FINAL_DEMO_CHECKLIST.md`, `docs/SECURITY_LIVE_TEST_CHECKLIST.md`.

The supplied live tests already establish important property/viewing/Storage behaviors; they are not being treated as failures. Remaining presentation checks are final-device login/gallery/contact copy, a clean Reject example, appropriate Pending requests and source/APK identification. Retain sanitized evidence for the already-passed denial checks. No policy rewrite is needed.

The invalid rent range was a functional validation defect before this audit and is now fixed. The short/large-text Favorites overflow and clipboard exception path are also resolved. **No additional demonstrated P1 code defect remains.**

## E. P2 SAFE POLISH

| Issue | Exact area | Recommendation / reason not changed now |
|---|---|---|
| Named-area shortcuts open generic Search | `home_screen.dart` (Sukhumvit, Chulalongkorn University) | Category shortcuts work; optional text-query prefilling remains |
| Dual type controls can intentionally intersect to zero matches | `search_screen.dart` quick types + More Filters type | Clarify active filters or unify controls later; do not silently change existing combination semantics at submission |
| Plain manager empty states | `manager_properties_screen.dart`, `manager_viewings_screen.dart` | Optional compact icon/guidance; states already usable, not blockers |
| Default launcher artwork | Android/iOS icon assets | Brand before packaging only if time permits; RoomStay application labels are correct |
| Small lavender decorative text contrast | `home_screen.dart`, `app_colors.dart` | Review remaining accent uses; this audit improved error/hero text, not every possible pair |
| Auth error messages can originate at server | `login_screen.dart`, `register_screen.dart` | Optional safe mapping to friendly messages; no auth logic changed |
| Some errors duplicate inline text and Snackbar | Home/Search/Detail/My Viewings | Prefer one primary error presentation in a later focused polish |
| Missing discard warning; long content truncates | Property form/viewing messages/cards | Optional discard confirmation/full-content access; no data semantics changed |
| External decimal rent | `models/property.dart` | Confirm demo data is whole baht; model/format change needs a deliberate data contract decision |
| Additional property type conventions | Form/Search | New form offers Apartment/Condo/House/Dormitory; Studio is bedrooms=0. Legacy `type=Studio` is preserved on Edit but has no quick type chip. Verify actual data before extending options |

## F. P3 FUTURE IMPROVEMENTS

Finite HTTP deadlines and clear session-expiry recovery; secure persisted sessions/refresh; tab-state preservation; pagination; Android picker process-loss recovery; duplicate Pending-request rules; reference-aware Storage cleanup; a complete reviewed schema/grant/trigger migration history; smaller reusable widgets/request helpers.

These are future hardening/maintenance tasks, not reasons to replace the simple teacher-style architecture. Chat, payments, booking, maps, notifications, reviews, admin dashboards, multiple photos and analytics remain outside the final MVP.

## G. FEATURE CHECKLIST

**PASS means inspected implementation and relevant local tests; live attribution is explicitly noted.** It does not certify every backend configuration. All feature failures discovered in this pass are resolved unless a limitation is stated.

### Renter

| Final feature | Result | Evidence / limitation |
|---|---|---|
| Register | PASS | Required name/email/password/confirmation/Terms; minimum 8, uppercase/lowercase/digit; Auth metadata only; trigger/confirmation settings remain deployment assumptions |
| Login | PASS | Password grant, token/user validation, own profile read, invalid/unknown role errors, duplicate-submit guard |
| Role-based navigation | PASS | Stored `renter` → five-tab renter shell; stored `partner` → three-tab manager shell |
| Logout | PASS | All six UserSession fields cleared; previous navigation stack removed; local logout, no remote revocation |
| Home cards / images / availability | PASS | Real property GET, newest IDs first, fallback image, availability labels. Catalogue includes unavailable rows rather than hiding them; Detail disables request for unavailable snapshot |
| Apartments / Condos | PASS | Canonical type filter passed to existing Search tab; selected chip first/visible; case/whitespace-tolerant type comparison |
| Houses / Dormitories | PASS | Same flow with House/Dormitory |
| Pet Friendly / Near University / Near Transit | PASS | Boolean model fields; no invented near_bts field; transit label corrected |
| Shortcut reset/count/combination/Back | PASS | 17 category tests cover selection/results/count, parent rebuild, reset, More Filters, Back and mobile layout |
| Text search | PASS | Name/location/type match; text clear works |
| Price / bedrooms / facilities / availability | PASS | Existing numeric/AND filtering preserved; whole-baht fixture values; selectable filters |
| Invalid minimum > maximum | PASS — FIXED | Inline message, Apply disabled, reset and equal-bounds regression |
| Sorting / Reset / no results | PASS | Numeric ascending/descending sort, clear initial Home filter, clean zero-match state |
| Property Detail content | PASS | Image/name/location/rent/type/bedrooms/description/facilities/flags/manager, loading/not-found/error paths |
| Manager name/email / Copy Email | PASS | Related profile GET; six responsive/copy tests plus new exception/retry test |
| Request Viewing | PASS | Future combined local date/time required; real renter/property IDs and exact Pending status; duplicate-tap guard |
| Favorite add/remove/list | PASS | Current-user JWT GET/POST/DELETE; local IDs change after success; requests/version guards |
| Favorite navigation/reload/empty/error | PASS | Shared MainScreen IDs; actual empty response shows “No saved rooms yet”; no runtime demo fallback; short-state fix tested |
| My Viewings / Pending / Approved / Rejected | PASS | Renter-scoped relation GET and status labels; supplied live approval→renter status evidence |
| Edit only Pending | PASS | UI and direct edit route guard; PATCH includes ID+renter+Pending; returned rows required |
| Cancel only Pending | PASS | Confirmation, ID+renter+Pending DELETE, returned rows required; no Edit/Cancel on Approved/Rejected |
| Manager status visible to renter | PASS | Mock coverage and user-reported live Approved display; refresh/reopen needed, not realtime |
| Profile identity/role | PASS | Session name/email; Renter label; no hardcoded demo account identity |
| Bottom navigation | PASS | Home / Search / Favorites / My Viewings / Profile unchanged |

### Property Manager

| Final feature | Result | Evidence / limitation |
|---|---|---|
| Partner login → Property Manager | PASS | Actual DB role remains partner; no role migration |
| Own management list | PASS | GET partner_id=current session and defensive row filtering; supplied B-vs-A UI evidence |
| Add Property | PASS | Owner from session, no owner input; required fields; representation before success |
| Edit Property | PASS | ID+owner read/PATCH; unrelated direct route denied; zero-row changes do not claim success |
| Delete Property | PASS | Confirmation; ID+owner DELETE; failures stay visible; 23503 friendly FK message; own delete/foreign denial supplied live |
| Availability | PASS | Existing boolean persisted and displayed; no schema extension |
| Photo upload / preview / replace / remove | PASS | Gallery, optional preview, signatures/MIME, own UUID/timestamp object, no upsert, public URL; preservation/retry/remove-null paths tested |
| Facilities selection | PASS | Set→List<String>, wrapping selected chips, edit preselection; unknown legacy labels retained |
| Validation / type / bedrooms | PASS | Trimmed required name/location; positive integer rent; required type; Studio–5 integer bedrooms; edit preselection |
| Responsive form / empty state | PASS | Shared scrolling form; real layout probes and permanent tests; manager empty states terse but functional |
| Owned viewing requests | PASS | Fetch owned property IDs, filter viewing query/returned rows; related renter labels optional |
| Approve / Reject Pending | PASS | Ownership recheck, ID+property+Pending PATCH, only status payload, returned ID/status checked; live Approve supplied, explicit live Reject not supplied |
| No cross-account actions | PASS | Mocked own/other/session-change tests plus supplied direct live property/viewing denials; no reliance solely on hidden buttons |
| Loading/error/status behavior | PASS | Spinners, retry/refresh, labelled statuses, duplicate decision guard, decided cards omit actions |
| Profile/logout | PASS | Shared identity/Property Manager display and session clearing |
| Bottom navigation | PASS | Properties / Viewing Requests / Profile unchanged |

### Actual model/database contract

The supplied actual property fields are `id`, `partner_id`, `name`, `location`, `type`, `monthly_rent`, `bedrooms`, four booleans, `facilities`, `description`, `image_url`, `rating`, `created_at`, `updated_at`. The form writes only its intended editable fields and session owner on create; it does not write timestamps, rating, bathrooms or size.

`bathrooms`/`size_sqm` remain legacy model-only fields, default to zero and are unused by active UI; no assertion is made that they exist in Supabase. They were retained to avoid unnecessary model/fixture churn. `rating` is a real supplied field and positive ratings appear on cards alongside availability. Numeric decimal rent truncates to int; decimal strings fall back to zero. Current form rejects decimals, so external/legacy data needs a consistent whole-baht convention.

## H. SECURITY CHECKLIST

| Area | Result / source | Limits / action |
|---|---|---|
| Client secrets/current files | PASS static scan | 172 current text files scanned; no high-confidence secret/private-key/privileged JWT/database credential URI; pattern scan is not a guarantee |
| Git history | PASS static scan | One reachable commit, 219 unique blobs, 187 text blobs; no high-confidence finding |
| Auth | PASS inspected/mock | JWT from real Auth password response; no fake success; no refresh/session-expiry recovery |
| Property ownership | PASS user-reported live + mocks | B UI excluded A; B PATCH returned []; B DELETE did not remove A; A deleted own temporary property |
| Viewing ownership/status | PASS user-reported live + mocks | B could not PATCH A; A read/approved own request; renter saw Approved/no actions; direct Approved edit blocked; Pending→Approved returned 403 and stayed Pending |
| Storage | PASS user-reported live + inspected/mock | B→A-folder and renter uploads blocked; no forbidden objects; public delivery intentionally separate from restricted uploads |
| Role handling | PASS for actual constraint | DB roles are renter/partner. UI says Property Manager. Existing property_manager compatibility is retained but never provisioned/written by Flutter |
| Profile access | PASS client compatibility | Only GET profiles in login/detail/manager viewings; signup uses Auth metadata/trigger, not direct POST/PATCH profiles. Immutable-role/SELECT-only grants not independently inspected |
| Client key handling | PASS | URL + publishable key expected; authenticated operations add Bearer token; no privileged client path |
| Favorites isolation/uniqueness | PASS client/mock; live evidence incomplete | User filters and post-success state; supplied new live evidence does not establish pair constraint/other-renter denial |
| Ignore rules | PASS | .env patterns and platform signing/local config ignored; no tracked build/cache/env/signing-secret paths found |

No passwords, tokens, project URL or key values are printed in this report. The supplied manager accounts both use internal role **partner**. No database role was migrated to property_manager.

### SQL/documentation consistency

Current exact viewing values are **Pending / Approved / Rejected**; runtime guards and payloads use this capitalization. Human-readable lowercase prose is not a status comparison. Legacy Cancelled rendering remains, but cancellation deletes a Pending row and does not require creating a new status value.

`docs/property_manager_supabase.md` and Storage SQL are historical conditional proposals, not a dump of working deployed protections. They do not fully encode the supplied renter column/status restrictions. Documentation now warns against reapplying them to working policies and corrects role assumptions. RLS rows and column/transition restrictions are distinct concerns. Storage SQL executable statements were not changed; comments only were added.

The client constructs `<UserSession.userId>/<microseconds>.<extension>` paths and uses JWT/MIME plus `x-upsert:false`. Known live protections must remain as supplied. Public catalogue property GETs use only the publishable key; intended public SELECT is required. A public listing is not private manager viewing/renter data.

## I. UI/UX REVIEW

### What was exercised

Thirteen major screens were rendered with realistic Roboto metrics at 360×640, 400×800, 360×480 with 200px keyboard inset, 360×640 at 2×, and 360×320 at 2×: **65 variants**. Before fixes, 64 passed and Favorites empty at the shortest 2× size overflowed by 60px. After the scrolling fix, **65/65 passed**. Temporary font-dependent probes were saved outside the project and removed from the permanent suite. The existing six contact tests remain portable and test full Copy Email behavior.

These are widget/render probes, not a physical-device/TalkBack/VoiceOver certification. The post-fix suite also tests Favorites error/retry at the same short 2× size. No global text scaling was disabled.

| Screen | Assessment / remaining improvement |
|---|---|
| Splash | Branded safe-area logo, timer disposed; no new issue observed |
| Login/Register | Scrollable, consistent labels/white loading spinner; lightweight @ email check delegates real validity to Auth; Forgot password/Terms destinations incomplete |
| Home | Branded hierarchy and adaptive tiles; selected categories work; hero foreground contrast improved; fixed-location control and named-area shortcuts remain partial |
| Search | Selected initial chip visible first, correct counts, combined filters/reset; invalid rent now explicit; advanced and quick type controls may create a deliberate empty intersection |
| Favorites | Useful icon/copy, real empty/error separation; newly scrollable short/2× empty/error content |
| Detail/contact | Clear content hierarchy, wrapped facilities, 48px back/heart, scrollable contact sheet and sticky CTAs; Copy failure now handled; broken images use placeholder |
| Request/Edit Viewing | Scrollable fields, future-time validation, disabled loading submission; no new overflow; success feedback clear |
| My Viewings | Text+color status, Pending-only actions, confirmation; long messages truncate and status needs refresh |
| Manager Properties | Owned cards, obvious destructive action and confirmation; empty message is plain and could have a small icon |
| Add/Edit Property | Shared single-column form, expected fields, dropdown preselection, facility chips, modest photo preview, aligned SwitchListTiles; Back discards unsaved edits without prompt |
| Manager Requests | Clear Pending decisions, neutral Cancelled styling, optional renter fallback; empty state could explain when requests arrive |
| Profile | Correct Renter/Property Manager labels, scrollable name/email; no logout confirmation, which is not data-destructive and preserves existing behavior |

Inputs/buttons generally use 12px radius, cards 16px, horizontal page padding around 22px. Icon-only actions have useful tooltips where present; hearts are 48px. Availability/status always includes a text label. Some 11–12px secondary text and decorative lavender contrast remain polish items. Error/hero color changes improve specific measured pairs, not a claim of universal accessibility compliance.

### API/error/lifecycle findings

Core network screens separate loading from empty/error. Home/Search/Detail/My Viewings can show both inline error and Snackbar. Manager/property/form reads and actions have mounted guards and duplicate-submit controls. Splash cancels its timer. Favorites guards stale responses; not every read versions every possible concurrent request.

No HTTP call uses a timeout. MainScreen awaits initial favorite loading before detail navigation, so a hung request may block it. This is a known network-resilience limitation, categorized as future hardening rather than a demonstrated current crash. Favorites POST/DELETE and viewing creation trust success status without verifying the returned row; manager mutations and renter viewing edit/delete require returned rows. Most malformed payloads are caught, but safe defaults can hide incomplete property data. Clipboard exception recovery is newly tested.

## J. TEST RESULTS

### Baseline and post-fix checks

| Command | Before fixes | After fixes |
|---|---|---|
| `dart format .` | PASS — 55 files, 0 changed | PASS — 56 files, 0 changed on final rerun |
| `flutter analyze` | PASS — no issues, 1.5s | PASS — no issues, 1.4s |
| `flutter test` | PASS — 190, 0 failures | PASS — 195 tests, 0 failures (13s) |
| `flutter build apk --debug` | PASS | PASS — assembleDebug 4.5s |
| `flutter build apk --release` | PASS — 54.7 MB | PASS — 54.7 MB; assembleRelease 16.7s |

The first post-fix analysis found one missing-braces lint in the new test; it was corrected and all five commands rerun successfully. The initial formatting pass formatted three changed files; the final formatting pass made no changes.

Release manifest includes INTERNET and application label RoomStay; iOS photo-library usage text is present. Both platforms display RoomStay. Android package remains `com.example.roomstay_mobile`, minSdk 24/target 36 and debug signing for classroom sideloading. No signing change; not store-ready signing. iOS was not built/run.

### Coverage inventory

| Tests | Count after fixes | Main coverage |
|---|---:|---|
| widget | 11 | Auth/register/splash/navigation/profile |
| phase3 | 9 | Renter search/detail/profile/viewing UI |
| favorites + favorites_runtime | 13 | Real empty/error, state, pending/stale behavior |
| viewing_crud + viewing_helpers | 10 | Create/edit/cancel, relation/date/time helpers |
| property_mapping | 2 | Model/default mapping |
| project_audit | 18 | Errors, owner predicates, zero rows, lifecycle/concurrency |
| property_manager | 37 | Routing/CRUD/decisions, validation, dropdowns, layouts |
| property_form_media | 17 | Facilities, picker, upload/preserve/remove/retry/failure |
| submission_fixes | 10 | Pet filter/sort, Home order, status/time rules, large text |
| contact_manager_sheet | 6 | Long email/name, narrow/short/2×, full clipboard value |
| manager_authorization | 27 | Own/other-account/session changes, renter rejection, decided rows |
| home_search_categories | 17 | Every category, count, combinations/reset, Back/layout |
| final_submission (new) | 5 | Rent range/equal/reset; short Favorites empty/error/retry; clipboard failure/retry |
| partner | 13 | 2 current role-routing tests, 11 legacy prototype tests |
| **Total** | **195** | Existing 190 preserved; five meaningful additions |

No tests connect to live Supabase. No line/branch coverage was measured. Legacy prototype tests are not counted as live-manager integration evidence. Missing evidence includes physical gallery permission/activity-loss behavior, iOS, true concurrent backend races, expired-token recovery and the remaining profile/favorite grant checks.

## K. SOURCE/SUBMISSION CHECK

Git inventory at audit time: **31 modified tracked paths, 11 intentional tracked deletions, 39 untracked files**, no staged changes, one historical commit. Counts include previous work and are not the audit's own change count.

**Audit's application changes:** `lib/screens/search_screen.dart`, `lib/screens/favorites_screen.dart`, `lib/screens/room_detail_screen.dart`, `lib/theme/app_colors.dart`. Added `test/final_submission_test.dart`. Documentation updated: README, this report, final demo/security/source checklists, manager setup notes and comments in the Storage setup SQL.

Critical files verified unchanged against the start snapshot: UserSession/config, Auth screens, MainScreen/Home navigation, manager ownership/CRUD, form Storage implementation, all viewing business-rule code, pubspec and lockfile. Existing test files were unchanged. Temporary layout probes were removed.

No tracked source/config file exceeded 1 MB. Asset declaration resolves to the existing RoomStay SVG; flutter_svg/image_picker/http are used. No unnecessary new package, runtime test fixture, debug print or new TODO was introduced. Build/cache/local SDK/signing files are ignored; build outputs exist locally and should be submitted only if the rubric requests an APK separately.

### Existing tracked changes requiring review

These include earlier project work; only the four application files named above were edited by this audit.

Modified tracked paths:

- `.gitignore`
- `README.md`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`
- `lib/models/property.dart`
- `lib/screens/favorites_screen.dart`
- `lib/screens/home_screen.dart`
- `lib/screens/login_screen.dart`
- `lib/screens/main_screen.dart`
- `lib/screens/my_viewings_screen.dart`
- `lib/screens/profile_screen.dart`
- `lib/screens/register_screen.dart`
- `lib/screens/request_viewing_screen.dart`
- `lib/screens/room_detail_screen.dart`
- `lib/screens/search_screen.dart`
- `lib/screens/splash_screen.dart`
- `lib/screens/update_viewing_screen.dart`
- `lib/theme/app_colors.dart`
- `lib/theme/app_text_styles.dart`
- `lib/widgets/property_card.dart`
- `linux/flutter/generated_plugin_registrant.cc`
- `linux/flutter/generated_plugins.cmake`
- `macos/Flutter/GeneratedPluginRegistrant.swift`
- `pubspec.lock`
- `pubspec.yaml`
- `test/partner_test.dart`
- `test/phase3_test.dart`
- `test/viewing_crud_test.dart`
- `test/widget_test.dart`
- `windows/flutter/generated_plugin_registrant.cc`
- `windows/flutter/generated_plugins.cmake`

Intentional tracked deletions:

- `lib/data/api_config.dart`
- `lib/data/demo_viewings.dart`
- `lib/data/partner_demo_data.dart`
- `lib/data/sample_properties.dart`
- `lib/screens/partner/add_property_screen.dart`
- `lib/screens/partner/my_properties_screen.dart`
- `lib/screens/partner/partner_dashboard_screen.dart`
- `lib/screens/partner/partner_main_screen.dart`
- `lib/screens/partner/partner_profile_screen.dart`
- `lib/screens/partner/partner_viewings_screen.dart`
- `lib/screens/partner/update_property_screen.dart`

### Untracked important files

- `CLEANUP_REPORT.md`
- `FINAL_PROJECT_AUDIT.md`
- `docs/FINAL_DEMO_CHECKLIST.md`
- `docs/FINAL_SOURCE_CHECKLIST.md`
- `docs/SECURITY_LIVE_TEST_CHECKLIST.md`
- `docs/property_images_storage_setup.sql`
- `docs/property_manager_supabase.md`
- `lib/config/supabase_config.dart`
- `lib/data/favorite_helpers.dart`
- `lib/data/user_session.dart`
- `lib/data/viewing_helpers.dart`
- `lib/screens/manager_properties_screen.dart`
- `lib/screens/manager_viewings_screen.dart`
- `lib/screens/property_form_screen.dart`
- `lib/screens/property_manager_main_screen.dart`
- `test/contact_manager_sheet_test.dart`
- `test/favorites_runtime_test.dart`
- `test/favorites_test.dart`
- `test/final_submission_test.dart`
- `test/fixtures/demo_viewings.dart`
- `test/fixtures/partner_demo_data.dart`
- `test/fixtures/sample_properties.dart`
- `test/home_search_categories_test.dart`
- `test/manager_authorization_test.dart`
- `test/project_audit_test.dart`
- `test/property_form_media_test.dart`
- `test/property_manager_test.dart`
- `test/property_mapping_test.dart`
- `test/submission_fixes_test.dart`
- `test/support/legacy_partner/add_property_screen.dart`
- `test/support/legacy_partner/my_properties_screen.dart`
- `test/support/legacy_partner/partner_dashboard_screen.dart`
- `test/support/legacy_partner/partner_main_screen.dart`
- `test/support/legacy_partner/partner_profile_screen.dart`
- `test/support/legacy_partner/partner_viewings_screen.dart`
- `test/support/legacy_partner/update_property_screen.dart`
- `test/support/manager_backend.dart`
- `test/support/test_backend.dart`
- `test/viewing_helpers_test.dart`

### Include / exclude

Include the complete current `lib/`, `assets/`, `test/` including support/fixtures, `docs/`, pubspec/lockfile, platform source/configuration, README and this audit. Preserve intentional removal of old runtime demo/Partner files. Keep existing tracked platform plugin registrants as project source; do not confuse them with generated caches.

Exclude build/, .dart_tool/, .gradle/Pods/ephemeral caches, local SDK paths, .env credentials, signing keystores/key.properties, passwords, access/refresh tokens and privileged Supabase/database keys. Existing .env and signing ignore rules were checked. Do not commit temporary audit logs/probes. No source was staged, committed or pushed automatically.

The complete previous clean export passed checks before this audit; current source-package evidence and exact inventory are maintained in `docs/FINAL_SOURCE_CHECKLIST.md`. Freeze/re-export the final current tree, not HEAD, before submission.

## L. DEMO DATA CLEANUP

No live rows were fetched or deleted in this audit, so it would be misleading to invent a list of current bad row IDs. Review these exact categories manually and record chosen IDs before any cleanup:

1. Temporary properties explicitly created for the cross-account PATCH/DELETE tests. Keep one realistic listing with a working photo; remove only confirmed disposable, unreferenced rows.
2. Duplicate Pending viewings created while rehearsing. Keep one deliberate Pending row for Approve, a separate Pending row for Reject and one already Approved example; use future dates/times and actual property ownership.
3. Temporary test messages/throwaway names, placeholder descriptions and malformed or unexplained status values. Do not change capitalized valid statuses to lowercase.
4. Old Demo Partner display names, if still present. Correct profile display data through the trusted process; keep internal role `partner`.
5. Broken public image URLs, properties with no facilities unintentionally, inconsistent facility spellings and hidden legacy “Pet friendly” array strings. The boolean is authoritative for pet filtering.
6. Fractional rent values from external tools; agree on whole baht for the current mobile model. Check legacy bedrooms outside 0–5 and distinct `type=Studio` before demoing Edit.
7. Test accounts are intentional presentation accounts; do not expose their passwords/tokens in README or slides. Do not mass-delete accounts.
8. Old Storage objects after replacement/removal are an acknowledged limitation. No forbidden objects were reported in the live denial checks. Remove only objects proven unreferenced; do not bulk-clean the bucket.

Never delete the Approved request used as successful live evidence merely to make the list look tidier. Verify FK restrictions before demonstrating property deletion.

## M. TOP 5 ACTIONS BEFORE SUBMISSION

1. **Freeze and package the complete tested source/APK pair.** Include untracked implementation/tests/docs and intentional deletions; verify a clean extraction/checkout. Do not submit historical HEAD alone.
2. **Run the exact final APK through the 18-step demo.** Especially real gallery upload, contact copy, manager Reject and renter refresh. Preserve already-passed authorization evidence.
3. **Prepare a small clean dataset.** Realistic property/photo/contact/facilities, whole-baht rent, future Pending examples; remove only explicitly disposable test records after FK review.
4. **Finish the remaining bounded security evidence.** Profiles immutable role/SELECT-only grants, own/other renter favorites and Pending delete cases, signup trigger/confirmation and linked-record FK behavior. Do not weaken working policies.
5. **Prepare presentation fallback and explanations.** Use existing real records when uploads are slow; explain refresh/session and single-image limits honestly. Keep a prerecorded successful rehearsal for a complete outage, clearly labelled as recorded evidence.

## N. SCORE IMPROVEMENT

| Stage | Estimated score /10 | Basis |
|---|---:|---|
| Before this audit's safe fixes | 8.1 | Current category fix and newly supplied live security evidence credited; range-validation gap, short Favorites overflow, clipboard exception and stale docs still present |
| After safe fixes | **8.3** | Five useful regressions, responsive-state repair, clear range validation, clipboard recovery, measured contrast and accurate role/live-evidence documentation |
| Possible after final packaging/demo cleanup | **8.4–8.5** | Conditional on a complete matching source/APK, polished real data and successful exact-device rehearsal; not achieved merely by writing a checklist |

The earlier 7.9 estimate used older evidence and a different scorecard. The supplied live tests improve confidence; they are not attributed to the automated suite or newly performed work. Final scores remain below 10 because reliability, documentation reproducibility and device/backend coverage still have practical limits.
