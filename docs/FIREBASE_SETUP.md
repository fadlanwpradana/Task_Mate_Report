# Firebase setup

## Services used

- Firebase Authentication: email/password and Google sign-in.
- Cloud Firestore: online community posts, comments, likes, views, chat, and other existing app data.
- Cloudinary: unsigned image uploads for community-post JPEGs.

The project is already associated with Firebase project `taskmatev4`; do not create another project. Cloudinary community images use cloud `mr5ddhj5`, unsigned upload preset `taskmate_upload`, and folder `taskmate`. The API secret must never be included in the Flutter app.

## Cloudinary setup

1. In the Cloudinary account for cloud `mr5ddhj5`, create or verify an **unsigned** upload preset named `taskmate_upload`.
2. Set its upload folder to `taskmate` (the client also supplies this folder on each upload).
3. Keep the API secret out of Flutter source, assets, and build-time client configuration. Unsigned uploads do not need a client-side secret.
4. The Flutter client cannot securely delete Cloudinary assets. If automatic asset cleanup is required, add a trusted server endpoint that signs and authorizes deletion requests.

## Firestore post policy

The existing `firestore.rules` preserves private-community membership checks and author-only deletion. Its post rules now permit an author to change only `title`, `body`, `tags`, and `imageUrls`; engagement counters, author identity, and creation time cannot be changed through the edit path. Photo lists are capped at four and non-empty image lists are restricted to public posts until private-media access is safely verified.

Deploy these rules through the existing Firebase project after Emulator validation; no rules were deployed by this change.

Cloudinary secure URLs are saved in the existing Firestore `imageUrls` field. The current UI and Firestore policy restrict image posts in private communities. Cloudinary uploads may leave unused assets if a post save fails, an image is removed during editing, or a post is deleted; the Flutter client does not perform unsigned destructive operations.

## Manual app/platform configuration

- Android camera permission is declared in `android/app/src/main/AndroidManifest.xml`.
- iOS camera and photo-library usage descriptions are in `ios/Runner/Info.plist`.
- `firebase_options.dart` is Android-only today. Run FlutterFire configuration for iOS against the **same existing project** if needed; do not overwrite or create a new Firebase project.
- Verify the unsigned preset and perform a real upload before describing Cloudinary image uploads as operational.
