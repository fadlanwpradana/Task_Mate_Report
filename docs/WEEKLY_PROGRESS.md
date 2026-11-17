# Weekly progress

## Checklist

- [x] Inspect the existing Flutter, community, Firebase, and persistence architecture.
- [x] Restore the missing community repository contract and add owner-checked post CRUD.
- [x] Add compatible `imageUrls`, image validation/compression, camera/gallery selection, previews, and progress UI.
- [x] Add SQLite storage for offline-demo posts and a per-user Firestore feed cache.
- [x] Keep Shared Preferences for settings and small local values.
- [x] Add focused model, CRUD, image, and SQLite tests.
- [x] Integrate unsigned Cloudinary image uploads for post creation and editing.
- [ ] Verify the Cloudinary unsigned preset and live image uploads.
- [ ] Provide a trusted signed endpoint if Cloudinary asset cleanup is required.
- [ ] Configure iOS Firebase if iOS sign-in/community is required.
- [ ] Run authorized Firebase Emulator or project-level integration checks and record results.

## Completed features

- Firestore and local community repositories support create, update, and delete operations. Both reject editing or deleting a post authored by someone else.
- Existing text-only Firestore posts load with an empty image list.
- Public posts can include up to four compressed JPEGs. Private-community photos remain blocked until their access policy can be verified without exposing private media.
- Post cards and detail screens show image galleries with loading/error states and full-screen swipe navigation.
- SQLite is the local structured post store/cache; Firestore remains the online source of truth.
- Shared Preferences remain in use for appearance, language, onboarding, notification settings, community metadata, and view markers.

## In progress / pending

- Cloudinary preset setup and live upload/download have not been verified.
- Cloudinary assets are not deleted by the unsigned Flutter client; a trusted signed backend is needed for cleanup.
- iOS Firebase options are not present in the repository.
- Desktop SQLite support needs a platform-appropriate factory.

## Suggested demonstrations through Session 13

1. **Session 1:** Run the app and explain the online/offline entry points.
2. **Session 2:** Create and browse text-only community posts.
3. **Session 3:** Show post likes, comments, and views remain available.
4. **Session 4:** Demonstrate post ownership and unavailable edit/delete actions on another user's post.
5. **Session 5:** Demonstrate gallery selection, preview, removal, and the four-photo limit.
6. **Session 6:** Demonstrate camera capture on a device with camera permission.
7. **Session 7:** Explain image validation, JPEG compression, and upload progress.
8. **Session 8:** Demonstrate image galleries and full-screen swipe navigation with the configured Cloudinary preset.
9. **Session 9:** Edit a post and verify its Firestore document ID and engagement counters are preserved.
10. **Session 10:** Delete a post and note that Cloudinary assets require a trusted backend for cleanup.
11. **Session 11:** Show Shared Preferences settings and onboarding persistence.
12. **Session 12:** Show SQLite cached feed/offline demo records and per-user cache separation.
13. **Session 13:** Review Firestore rules, Cloudinary preset setup, test results, and remaining platform setup.

## Sessions 14 and 15: final presentation preparation

- **Session 14:** Verify the Cloudinary unsigned preset, run the full analyzer/tests, and capture only verified app behavior.
- **Session 15:** Present architecture and CRUD/photo demonstrations, distinguish mock/Emulator/live verification, disclose platform/configuration gaps, and avoid claiming unverified Cloudinary behavior.
