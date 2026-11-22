# RoomStay

RoomStay is a Flutter mobile application developed for the **CSC452 Flutter Mobile Programming** final project.

The application helps renters discover rental properties, save favorites, contact Property Managers, and request property viewings. Property Managers can manage their own listings and respond to viewing requests.

---

## Overview

Finding a suitable rental property can require renters to check information from multiple sources and contact property owners separately.

RoomStay provides a simple mobile platform where renters can:

- Browse available rental properties
- Search and filter listings
- Save favorite properties
- View property details
- Contact Property Managers
- Request property viewings
- Manage their viewing requests

Property Managers can:

- Add new properties
- Edit existing properties
- Delete their own properties
- Set property availability
- Upload property images
- Review viewing requests
- Approve or reject pending requests

---

## User Roles

RoomStay supports two application roles.

### Renter

Renters can:

- Register and log in
- Browse rental properties
- Search, filter, and sort listings
- Save properties to Favorites
- View detailed property information
- Contact the Property Manager
- Request property viewings
- Edit or cancel pending viewing requests
- View Pending, Approved, and Rejected viewing statuses
- View their profile
- Log out

### Property Manager

Property Managers can:

- Log in using a provisioned manager account
- View their own properties
- Add properties
- Edit properties
- Delete properties
- Mark properties as Available or Unavailable
- Select property facilities
- Upload or replace a property image
- View requests for their properties
- Approve or reject pending viewing requests
- View their profile
- Log out

> In the database, Property Managers are stored using the `partner` role. The application displays this role as **Property Manager**.

---

## Main Features

### Authentication

- User registration
- User login
- Password validation
- Role-based navigation
- Supabase Authentication
- Logout

### Property Browsing

- Property list
- Property images
- Property details
- Monthly rental price
- Property type
- Bedrooms
- Location
- Facilities
- Availability
- Property description

### Search and Filters

Users can search and filter properties using:

- Property name or location
- Property type
- Minimum rent
- Maximum rent
- Pet Friendly
- Near University
- Near Transit
- Availability

Home shortcuts can also open Search with a selected filter.

### Favorites

Renters can:

- Add properties to Favorites
- Remove properties from Favorites
- View all saved properties

### Contact Property Manager

The Property Detail screen allows renters to:

- View the Property Manager's email
- Copy the email address
- Continue to Request Viewing

### Viewing Requests

Renters can:

- Select a future viewing date
- Select a viewing time
- Add an optional message
- Submit a viewing request
- Edit a Pending request
- Cancel a Pending request
- View the request status

Viewing statuses are:

- `Pending`
- `Approved`
- `Rejected`

Only Pending requests can be edited or cancelled by renters.

### Property Management

Property Managers can:

- Add a property
- Edit a property
- Delete their own property
- Change property availability
- Select multiple facilities
- Upload a property image
- Replace or remove the property image

### Viewing Request Management

Property Managers can:

- View requests for properties they own
- Approve Pending requests
- Reject Pending requests

Managers cannot manage viewing requests belonging to another Property Manager's property.

---

## Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Mobile application framework |
| Dart | Programming language |
| Supabase Auth | User authentication |
| Supabase PostgreSQL | Application database |
| Supabase REST API | Database communication |
| Supabase Storage | Property image storage |
| Row Level Security (RLS) | Database authorization |
| `http` | REST API requests |
| `image_picker` | Property image selection |
| `flutter_svg` | SVG asset display |

---

## Architecture

RoomStay uses a simple architecture suitable for a Flutter university project.

```text
Flutter Mobile Application
        ↓
HTTP REST Requests
        ↓
Supabase
 ├── Authentication
 ├── PostgreSQL Database
 └── Storage
```

The application uses:

- `StatefulWidget`
- `setState()`
- `Form`
- `GlobalKey<FormState>`
- `TextEditingController`
- `Navigator`
- `MaterialPageRoute`
- `ListView`
- `async / await`
- HTTP GET / POST / PATCH / DELETE
- JSON encoding and decoding
- SnackBar
- CircularProgressIndicator

The project intentionally does not use Provider, Riverpod, BLoC, GetX, or another state-management framework.

---

## Database Tables

### `profiles`

Stores user profile information.

Main fields:

- `id`
- `full_name`
- `email`
- `role`
- `created_at`

### `properties`

Stores rental property information.

Main fields:

- `id`
- `partner_id`
- `name`
- `location`
- `type`
- `monthly_rent`
- `bedrooms`
- `available`
- `pet_friendly`
- `near_university`
- `near_transit`
- `facilities`
- `description`
- `image_url`
- `rating`
- `created_at`
- `updated_at`

### `favorites`

Stores properties saved by renters.

Main fields:

- `id`
- `user_id`
- `property_id`
- `created_at`

### `viewings`

Stores property viewing requests.

Main fields:

- `id`
- `property_id`
- `renter_id`
- `viewing_date`
- `viewing_time`
- `message`
- `status`
- `created_at`
- `updated_at`

---

## Property Images

Property Managers can select one image from the device gallery.

The selected image is uploaded to the Supabase Storage bucket:

```text
property-images
```

Storage object paths follow this format:

```text
<manager-user-id>/<unique-filename>
```

The public image URL is then stored in:

```text
properties.image_url
```

If an image is missing or cannot be loaded, the application displays a placeholder instead.

---

## Security

RoomStay uses both client-side validation and Supabase Row Level Security.

Important security rules include:

- The Flutter application uses only the Supabase public publishable key.
- No service-role key or database password is stored in the application.
- Protected API requests include the logged-in user's JWT.
- Property Managers can modify only properties they own.
- A second Property Manager cannot update or delete another manager's property.
- Renters can manage only their own viewing requests.
- Renters can edit or delete only Pending viewing requests.
- Renters cannot change a Pending request directly to Approved or Rejected.
- Property Managers can approve or reject only requests for properties they own.
- Property Managers can upload images only to their own Storage folder.

Supabase Row Level Security policies provide the primary backend authorization layer.

---

## Demo Accounts

The following disposable accounts can be used for classroom demonstration and testing.

**Password for all demo accounts: `password123`**

| Role | Email | Purpose |
|---|---|---|
| Renter | `renter@roomstay.test` | Main renter demonstration |
| Property Manager | `partner@roomstay.test` | Main Property Manager demonstration |
| Property Manager B | `managerb@roomstay.test` | Cross-manager security testing |

> Property Managers use the internal database role `partner`, while the user interface displays **Property Manager**.

---

## Setup

### 1. Install Flutter

Check the Flutter environment:

```bash
flutter doctor
```

### 2. Clone the project

```bash
git clone https://github.com/SuYiNandar/roomstay_mobile.git
cd roomstay_mobile
```

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Configure Supabase

The public Supabase configuration is located in:

```text
lib/config/supabase_config.dart
```

The application requires:

- Supabase Project URL
- Supabase Publishable Key

Do not use a service-role key or database password in the Flutter application.

### 5. Run the application

```bash
flutter run
```

If Dart Development Service causes a connection problem with the Android emulator:

```bash
flutter run -d emulator-5554 --disable-dds
```

---

## Testing

Run static analysis:

```bash
flutter analyze
```

Run automated tests:

```bash
flutter test
```

Final validated result:

```text
No issues found
208 tests passed
0 failures
```

The automated test suite covers areas including:

- Authentication
- Role-based navigation
- Property mapping
- Property CRUD
- Property Manager authorization
- Favorites
- Viewing request CRUD
- Viewing status rules
- Search and Home category filters
- Contact Property Manager
- Image and media handling
- Loading states
- Error states
- Empty states
- Responsive layouts

---

## Build APK

Build a debug APK:

```bash
flutter build apk --debug
```

Build a release APK:

```bash
flutter build apk --release
```

Generated APK files are located under:

```text
build/app/outputs/flutter-apk/
```

The final release APK was successfully built and validated for the CSC452 project submission.

---

## Final Validation

Before the final project submission, the following checks were completed:

- Flutter formatting passed
- Flutter analyzer passed with no issues
- 208 automated tests passed
- Debug APK built successfully
- Release APK built successfully
- Renter login tested
- Property Manager login tested
- Property CRUD tested
- Favorites tested
- Viewing request workflow tested
- Cross-manager property authorization tested
- Cross-manager viewing authorization tested
- Renter viewing-status protection tested
- Storage upload authorization tested
- Launcher icon added
- Responsive manager empty states tested

---

## MVP Limitations

The current RoomStay version intentionally focuses on the main rental and viewing workflow.

The following features are outside the current project scope:

- Realtime chat
- Online payments
- Rental booking
- Maps and GPS
- Reviews
- Push notifications
- Analytics
- Admin dashboard
- Multiple property images

Additional limitations:

- One image is stored per property.
- Replaced Storage images may leave old files in the Storage bucket.
- User sessions are stored in memory.
- There is no automatic token refresh.
- Forgot Password is currently a placeholder.
- Viewing status updates may require reopening or refreshing the screen.
- Duplicate viewing requests are not automatically prevented.

---

## Future Improvements

Possible future improvements include:

- Realtime chat between renters and Property Managers
- Push notifications
- Multiple property images
- Rental booking
- Payment integration
- Maps and location services
- Reviews and ratings
- Pagination
- Automatic session refresh
- Improved image cleanup
- Duplicate viewing prevention
- Admin management features

---

## Project Information

**Project Name:** RoomStay  
**Course:** CSC452 Flutter Mobile Programming  
**Project Type:** University Final Project  
**Platform:** Flutter Mobile Application  
**Backend:** Supabase  

---

## Repository

```text
https://github.com/SuYiNandar/roomstay_mobile
```
