# KCAL TRACKER

A Flutter mobile food journal with a glassmorphism UI, Firebase Authentication, and Cloud Firestore. Supports Android and iOS.

## Features
- Email/password registration and login
- Firebase-backed user profiles
- Daily food diary with date picker
- Add, edit, and delete food entries
- Custom food name, kcal value, serving description, and meal category
- Daily total and entry count
- Meal filters: Breakfast, Lunch, Dinner, Snack
- Responsive glassmorphism UI

## Requirements
- Flutter stable (3.22+ recommended)
- Dart SDK compatible with `pubspec.yaml`
- A Firebase project
- Android Studio / Xcode for device builds (Xcode is required for iOS builds)

## 1. Open the project
Extract the ZIP, open the `kcal_tracker` folder in VS Code, then run:

```bash
flutter pub get
```

## 2. Connect Firebase
1. Create a project at https://console.firebase.google.com/.
2. In Firebase Authentication > Sign-in method, enable **Email/Password**.
3. Create a Cloud Firestore database.
4. Install the Firebase CLI and FlutterFire CLI:

```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

5. From the project folder, run:

```bash
flutterfire configure
```

Select your Firebase project and the Android and iOS platforms. This generates `lib/firebase_options.dart` and platform configuration files.

6. Update `lib/main.dart`: replace `await Firebase.initializeApp();` with:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

Also add this import at the top of `main.dart`:

```dart
import 'firebase_options.dart';
```

The generated Firebase options file contains project-specific identifiers. Do not copy configuration from another project.

## 3. Firestore security rules
In Firebase Console > Firestore Database > Rules, publish these rules:

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /food_entries/{entryId} {
        allow read, delete: if request.auth != null && request.auth.uid == userId;
        allow create, update: if request.auth != null
          && request.auth.uid == userId
          && request.resource.data.name is string
          && request.resource.data.name.size() > 0
          && request.resource.data.name.size() <= 100
          && request.resource.data.kcal is int
          && request.resource.data.kcal >= 0
          && request.resource.data.kcal <= 100000
          && request.resource.data.meal in ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
      }
    }
  }
}
```

## 4. Run the app

```bash
flutter run
```

For Android release build:

```bash
flutter build apk --release
```

For iOS (on macOS with Xcode):

```bash
flutter build ios --release
```

## Data model
Firestore path:

`users/{uid}/food_entries/{entryId}`

Fields:
- `name`: string
- `kcal`: integer
- `serving`: string
- `meal`: Breakfast | Lunch | Dinner | Snack
- `loggedAt`: Firestore timestamp
- `createdAt`: Firestore timestamp
- `updatedAt`: Firestore timestamp

## Notes
- The app records user-entered kcal estimates; it does not automatically identify food or verify nutrition labels.
- A Firestore composite index may be requested for the `loggedAt` date range and sort query. If Firebase shows an index link in the error, open it and create the suggested index.
- Firebase setup is project-specific. The source code is ready to connect, but it cannot authenticate or sync until you configure your own Firebase project.
