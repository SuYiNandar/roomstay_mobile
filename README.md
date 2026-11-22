# RoomStay

## Overview

RoomStay is a CSC452 Flutter university project for finding rental rooms and arranging property viewings. It supports renters and Property Managers using Supabase-backed data.

## Problem

Renters need a clear way to compare available rooms, save properties, contact their manager and request a viewing. Property Managers need to maintain listings and respond to those requests without a separate complex management system.

## User Roles

- **Renter:** browse, save and request viewings.
- **Property Manager:** manage owned listings and decide viewing requests. The current database constraint allows only `renter` and `partner`; managers use `partner`. The client retains compatibility with `property_manager`, but do not create that role or migrate the database to it. The legacy `properties.partner_id` ownership column is retained.

## Main Features

### Renter

- Register/Login with password rules and confirmation.
- Browse properties and images; search/filter/sort.
- Favorites with real loading, empty and error states.
- Property Detail with availability, description and facilities.
- Search rejects contradictory rent ranges; Home categories visibly preselect their filters.
- Contact Property Manager and Copy Email.
- Request Viewing with a future date/time.
- Edit/Cancel **Pending** viewing requests; read Approved/Rejected status.
- Profile/Logout.

### Property Manager

- Login with a provisioned manager profile.
- Manage owned properties; Add/Edit/Delete where backend policies/FKs allow.
- Availability management, facilities chips and bedrooms dropdown (Studio–5).
- Optional gallery photo preview/upload/replacement/removal.
- View requests for owned properties; Approve/Reject Pending requests.
- Profile/Logout.

## Technology Stack

Flutter, Dart, Supabase Auth, Supabase PostgreSQL, Supabase REST API, Supabase Storage, Row Level Security (RLS), `image_picker`, `http` and `flutter_svg`.

## Architecture

```text
Flutter screens / controllers / setState
    → HTTP REST
    → Supabase Auth / Database / Storage
```

The app uses direct REST calls and a small in-memory UserSession. It does not use supabase_flutter or a state-management framework. Automated tests explicitly inject mocked HTTP and gallery behavior; production does not fall back to demo data.

## Database Tables

| Table | Purpose |
|---|---|
| `profiles` | Auth user identity, name/email and trusted role |
| `properties` | Listing data; `partner_id` is the manager owner |
| `favorites` | User/property saved pairs |
| `viewings` | Renter/property date/time/message/status |

The repository is not a complete schema migration history. Verify actual constraints, grants, RLS and the Auth profile-creation trigger using [backend inspection notes](docs/property_manager_supabase.md). Do not blindly apply SQL to an existing project.

## Property Images

A manager selects one gallery image, previews it, then uploads to the Supabase Storage bucket `property-images` at `<manager-user-id>/<unique filename>`. The public URL is saved in `properties.image_url`. Replacing/removing an image updates the property reference; old Storage objects may remain. Broken/missing images display a placeholder.

[Storage setup notes](docs/property_images_storage_setup.sql) describe the intentional public-read bucket and narrow manager/own-folder INSERT policy. No privileged key belongs in the app.

## Security

- Public project configuration uses the Supabase URL and **publishable key** only.
- Protected requests carry the logged-in user's JWT.
- Property mutations constrain both property ID and session-derived owner ID.
- Viewing decisions recheck property ownership and use a Pending predicate.
- Manager mutation guards reject renter roles; asynchronous operations recheck relevant session access.
- **RLS, grants and constraints are the actual authorization boundary.** Client guards and mocked tests are not proof of deployed isolation.
- Flutter reads profiles; signup profile creation is expected from a trusted database trigger. Client profile INSERT/UPDATE is not required.

No service-role key, database password, private key or real account password should be committed. Run [manual live security checks](docs/SECURITY_LIVE_TEST_CHECKLIST.md) before claiming authorization is verified.

## Setup

1. Install Flutter with a Dart SDK compatible with `pubspec.yaml` (`^3.12.1`) and Android tooling. Run `flutter doctor` and resolve the toolchain issues relevant to Android. iOS needs Xcode on macOS and has not been validated by the final Android checks.
2. Obtain this complete source tree, including untracked files listed in [the source checklist](docs/FINAL_SOURCE_CHECKLIST.md) if sharing the current working copy.
3. Set `supabaseUrl` and `supabasePublishableKey` in `lib/config/supabase_config.dart` for the intended project. Use only public client configuration; the app does not load .env or Dart defines for these values.
4. Verify the existing tables, trusted signup trigger, protected roles, RLS, necessary public catalogue reads and related profile reads. Provision a manager through a trusted process; the login selector does not assign roles.
5. Verify the `property-images` bucket and policies. The included SQL is manual guidance, not automatically applied setup.
6. Android INTERNET permission and iOS photo-library usage text are configured. Use a real/emulated device to verify gallery behavior and network access.

## Run

```bash
flutter pub get
flutter run
```

## Testing

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Tests are network-independent and cover authentication, renter flows, property CRUD, ownership predicates, favorites, viewing status rules, mocked gallery/Storage failures and responsive contact-sheet behavior. They do not connect to live Supabase or certify RLS. See [the final audit](FINAL_PROJECT_AUDIT.md) for the latest executed counts/results and limitations.

## Build APK

```bash
flutter build apk --debug
flutter build apk --release
```

Outputs are under `build/app/outputs/flutter-apk/`. The current package is `com.example.roomstay_mobile`; release uses debug signing for classroom sideloading. This is not Play Store signing configuration. Keep the APK matched to its tested source commit/archive.

## Demo Accounts

Prepare a renter and a provisioned Property Manager privately. For security verification, prepare a second manager and renter. **No real credentials are published here.** Any presentation accounts should be disposable, clearly demo-only, and shared through an appropriate private channel.

## MVP Limitations

- No realtime chat, payments, booking, maps, notifications, reviews or admin dashboard.
- One property image; old Storage files may remain after replacement/removal.
- Session is memory-only; no automatic token refresh or HTTP timeout. Log in again after expiry.
- Status updates require refresh/reopening; Search state resets when switching tabs.
- Forgot-password is a placeholder; Terms/privacy text is not a policy-document route.
- Mobile rent input is whole baht; external fractional rents are not represented accurately by the integer model.
- Home category shortcuts preselect Search filters. Named-area shortcuts (for example Sukhumvit) still open Search without prefilled text.
- Duplicate viewing requests and Android picker process-loss recovery need further work.
- Cross-manager property/viewing protection, renter status protection and forbidden Storage uploads were reported live-tested by the project owner on 22 November 2026; see the security checklist. Remaining grant/trigger/FK cases and the exact final APK rehearsal are separate checks. iOS build/runtime is not verified.

## Future Improvements

Bounded requests and session recovery, state preservation, named-area shortcut behavior, Android form recovery, pagination, reference-aware image cleanup, and a reproducible schema/runbook. Keep final submission focused on reliable existing flows.

## Final Demo Checklist

Follow [FINAL_DEMO_CHECKLIST.md](docs/FINAL_DEMO_CHECKLIST.md), then record [manual security results](docs/SECURITY_LIVE_TEST_CHECKLIST.md). Review [FINAL_SOURCE_CHECKLIST.md](docs/FINAL_SOURCE_CHECKLIST.md) before committing or creating the submission archive. Current evidence and scores are in [FINAL_PROJECT_AUDIT.md](FINAL_PROJECT_AUDIT.md).
