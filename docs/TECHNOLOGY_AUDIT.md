# Technology audit

## SQLite

- **Status:** Implemented as a local post cache and offline-demo post store.
- **Database:** `lib/core/database/app_database.dart` creates `task_mate.db` at schema version 2. Version 2 adds an index for per-user cache reads; upgrades from version 1 create that index.
- **Operations:** `lib/core/database/database_helper.dart` reads, replaces, upserts, and deletes cached posts scoped by user ID.
- **Integration:** `FirestoreCommunityRepository` caches the signed-in user's public feed for read-through/offline display. `LocalCommunityRepository` uses SQLite for offline-demo posts and migrates legacy Shared Preferences post JSON on first open. Firestore remains the authoritative online feed.
- **Platform note:** The `sqflite` adapter is intended for Android and iOS. Desktop targets need a compatible SQLite factory before this feature can be used there.

## Shared Preferences

- **Status:** Implemented and retained for small local values.
- **Files:** `lib/core/services/storage_service.dart`, `lib/features/profile/services/profile_settings.dart`, `lib/core/services/locale_controller.dart`, and `lib/features/intro/services/onboarding_controller.dart`.
- **Purpose:** Profile appearance, language, notification/UI settings, onboarding completion, community metadata, and the small set of local view markers.
- **Post migration:** Offline-demo post records move from the legacy `posts` preference key into SQLite; new post writes use SQLite when the application supplies the database helper.
- **Limit:** Do not put credentials or growing post datasets in preferences.

## Firebase

- **Status:** Android initialization, Authentication, and Cloud Firestore are configured in the project. Community images use Cloudinary unsigned uploads.
- **Initialization/configuration:** `lib/core/services/firebase_service.dart`, `lib/firebase_options.dart`, `android/app/google-services.json`, and `firebase.json`.
- **Authentication:** `lib/features/auth/services/auth_repository.dart` supports email/password and Google sign-in.
- **Firestore:** Community posts and their existing likes/comments/views use `lib/features/community/services/firestore_community_repository.dart`; Firestore remains the online source of truth. `firestore.rules` restricts edits/deletes to authors and limits post photos to public posts.
- **Community images:** `lib/features/community/services/cloudinary_service.dart` uploads JPEGs using the `taskmate_upload` unsigned preset to folder `taskmate`. The preset configuration and live upload have not been verified. Cloudinary asset deletion requires a trusted signed backend and is not performed by the Flutter client.
- **Platform gap:** `lib/firebase_options.dart` explicitly reports iOS, web, macOS, Windows, and Linux Firebase options as unconfigured. iOS photo permission descriptions are present, but Firebase-backed iOS behavior is not configured.

## Missing / manual verification

1. Verify the Cloudinary unsigned preset and perform a real upload; see [Firebase setup](./FIREBASE_SETUP.md).
2. Verify Firestore create, edit, and delete against the existing Firebase project or Emulator. No live Firebase operation was performed as part of this audit.
3. Configure iOS Firebase options if iOS is an intended Firebase platform.
4. Configure a SQLite factory separately before using the app on desktop targets.

Sensors, Bluetooth, microphone, and speaker features are outside this project's scope and were not added.
