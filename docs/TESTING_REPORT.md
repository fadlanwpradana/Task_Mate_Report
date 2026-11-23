# Testing report

## Commands executed

| Command | Result |
|---|---|
| `flutter pub get` | Passed after adding `video_player`; existing `http` and `image_picker` are reused. |
| `dart format .` | Passed: all 99 Dart files formatted; final run made no further changes. |
| `flutter analyze` | Passed: no issues found. |
| `flutter test test/features/community/post_options_menu_test.dart` | Passed: 2 widget tests for owner-only delete access, confirmation, and successful feed refresh. |
| `flutter test test/features/community/post_image_test.dart` | Passed: 6 tests, including Cloudinary request settings and failure handling. |
| `flutter test test/features/community/post_crud_test.dart` | Passed: 5 tests for create/delete and ownership behavior, including video deletion isolation. |
| `flutter test` | Passed: 79 tests, 0 failures. |
| `git diff --check` | Passed: no whitespace errors. |

## Test coverage and test type

- Post model compatibility, including legacy documents without `imageUrls`: local unit tests.
- Firestore community post creation/deletion and ownership checks: `fake_cloud_firestore`; **mock only**, not the Firebase Emulator.
- Image capacity, byte validation, compression, Cloudinary request fields, secure URL handling, and upload rejection: local tests with a mock HTTP client.
- SQLite cache CRUD: `sqflite_common_ffi` in-memory database; real SQLite operations through the FFI test driver.
- Application navigation and post/comment interactions: Flutter widget tests with local repositories; Firebase services are not contacted.

## Firebase verification

- No Firebase Emulator, live Firebase project, or live Cloudinary upload was used.
- Authentication, Firestore rules deployment, the Cloudinary unsigned preset, and end-to-end photo upload remain unverified.
- Cloudinary media deletion is not implemented in the Flutter client; a trusted signed backend is required for asset cleanup.
- See [Firebase setup](./FIREBASE_SETUP.md) for the existing configuration gaps and manual verification steps.

## Remaining issues

- Verify the unsigned Cloudinary preset in the existing account and test an actual image upload.
- Add a trusted signed deletion endpoint if automatic cleanup of Cloudinary assets is required.
- Add iOS Firebase options if iOS Firebase support is required.
- Desktop SQLite requires a platform-appropriate database factory; the in-memory FFI test driver does not configure a production desktop target.

## Cloudinary video posts

- The unsigned `taskmate_upload` preset in cloud `mr5ddhj5`, folder `taskmate`,
  must allow MP4/video in addition to images. This preset configuration cannot
  be inspected or changed by the Flutter app.
- Video limits are 15 seconds and 50 MB, with at most one MP4 per post. A post
  cannot contain both video and images.
- Local tests can verify MP4 header/name, size/duration limits, mocked multipart
  upload handling, Firestore serialization, and deletion. They do not prove
  that the real Cloudinary preset or Firebase rules accept an upload.
- Real-device check: select a short MP4 from the gallery, preview and play/pause
  it, publish, and confirm the feed can play it. Then test invalid/over-limit
  files, upload failure/retry, and deletion. No microphone permission is
  required.
- Firestore post deletion does not delete the Cloudinary asset. Cleanup requires
  a trusted signed backend; no unsigned client-side asset deletion is made.
