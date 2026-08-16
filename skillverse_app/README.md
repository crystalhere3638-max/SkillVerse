# SkillVerse — Auth + Firestore Integration

Production-ready Firebase Authentication and Cloud Firestore wiring for the
existing SkillVerse UI. No screens were redesigned, no colors changed, no
navigation flow altered — this only replaces mock state with real backend
calls.

## Setup

1. `flutter pub get`
2. Install the FlutterFire CLI and generate real Firebase config:
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This overwrites `lib/firebase_options.dart` (currently a placeholder)
   with your project's real values and wires up Android/iOS/Web.
3. In the Firebase Console:
   - Enable **Authentication → Email/Password**
   - Enable **Authentication → Google**
   - Create a **Cloud Firestore** database (production mode)
   - Publish `firestore.rules` from the project root
4. Android: add your debug + release **SHA-1 / SHA-256** fingerprints to the
   Firebase Android app for Google Sign-In to work.
5. `flutter run`

## Architecture

```
lib/
  core/                  theme tokens, validators, error mapping
  data/
    models/app_user.dart          mirrors users/{uid} Firestore doc
    services/                     thin SDK wrappers (Auth, Google, Firestore)
    repositories/                 business logic + validation, throws AppAuthException
  providers/
    auth_provider.dart            auth state, loading, error — screens read this only
    user_provider.dart            live Firestore profile stream
  presentation/
    screens/auth/                 login, signup, forgot password, auth_gate (router)
    screens/setup/                category, goal (onboarding)
    screens/home/                 home shell + tabs
    widgets/                      shared button, text field, snackbar, empty state
```

Screens never call Firebase directly — they call `AuthProvider` /
`UserProvider`, which call a `Repository`, which calls a `Service`. This
keeps the UI layer swappable and testable, and keeps Firestore field names
in exactly one place (`AppUser`).

## Firestore schema — `users/{uid}`

| Field | Type | Notes |
|---|---|---|
| uid | string | matches document ID |
| username | string | |
| email | string | |
| photoUrl | string? | from Google account, if any |
| mainCategory | string? | null until onboarding step 1 |
| goal | string? | null until onboarding step 2 |
| xp / coins / level | number | default 0 / 0 / 1 |
| skillRating | number | default 0 |
| followers / following | number | default 0 |
| streak | number | default 0 |
| verified | bool | default false |
| createdAt / lastLogin | timestamp | server-set |

## Routing rules (AuthGate)

- No cached Firebase session → **Login**
- Signed in, `mainCategory` missing → **Category**
- Signed in, `goal` missing → **Goal**
- Signed in, both present → **Home**

Auto-login relies entirely on Firebase's own persisted session
(`authStateChanges`) — there is no separate local "logged in" flag to get
out of sync.

## Scope

Implemented: email signup/login, Google sign-in, forgot password, logout,
auto-login, Firestore user document creation/read, full validation, and
user-friendly error messages for every FirebaseAuthException case plus
no-network and cancelled-sign-in cases.

Not implemented (by design, per spec): posts, chat, competitions,
marketplace, AI features, courses, payments, notifications. The Compete /
Create / Community tabs render an empty-state placeholder so the nav
structure is preserved without faking functionality.

## Create Post feature (new)

Fully local/mock — no Firebase involved yet, per spec. Lives in:

```
lib/data/models/post_model.dart          Post + PostDraft
lib/data/services/post_local_storage_service.dart   SharedPreferences persistence
lib/data/repositories/post_repository.dart          mock seed data + create/persist
lib/providers/post_provider.dart                    feed state, simulated upload progress
lib/presentation/screens/create_post/               composer screen + media preview + success animation
lib/presentation/widgets/post_card.dart              reusable feed card
```

- Tapping the center **Create** nav button opens the composer as a full-screen
  route (existing bottom nav itself is unchanged).
- Selecting an image clears any selected video and vice versa (one media type
  at a time), enforced in `CreatePostScreen`.
- Caption is capped at 1000 characters with a live counter; publishing is
  blocked while empty, over the limit, or missing a category.
- "Save Draft" persists caption/category/media locally and is restored next
  time the composer opens; a successful publish clears the draft.
- Publish simulates an upload progress bar, disables the button while
  running, then shows a success animation before returning to the feed.
- New posts are prepended to the feed (newest first) and persisted locally,
  so they survive app restarts without any backend.

### Native permissions (required for image_picker / video_player)

Add once you run `flutter create .` against real `android/`/`ios/` folders:

**Android** — `android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
<!-- For devices below Android 13 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
```

**iOS** — `ios/Runner/Info.plist`
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>SkillVerse needs access to your photos to attach images and videos to posts.</string>
```

## Social Interaction System (new)

Fully local/mock — no Firebase, per spec. Adds to the existing `PostProvider`
and `Post` model rather than introducing a parallel system:

```
lib/data/models/comment_model.dart          Comment (+ reply via parentId)
lib/data/models/report_model.dart           ReportReason + Report
lib/data/models/activity_model.dart         ActivityEntry (+ ActivityType)
lib/data/services/interaction_local_storage_service.dart   activity log + reports (SharedPreferences)
lib/data/repositories/activity_repository.dart
lib/data/repositories/report_repository.dart
lib/core/services/share_service.dart        placeholder share contract (no share_plus yet)
lib/presentation/widgets/double_tap_like.dart     double-tap heart pop + haptic
lib/presentation/widgets/comment_sheet.dart       comment/reply/edit bottom sheet
lib/presentation/widgets/comment_tile.dart        reusable comment/reply row
lib/presentation/widgets/report_sheet.dart        reason picker + success state
lib/presentation/widgets/share_sheet.dart         placeholder share UI
lib/presentation/screens/profile/saved_posts_screen.dart
lib/presentation/screens/profile/liked_posts_screen.dart
lib/presentation/screens/profile/recent_activity_screen.dart
```

- **Like**: tap the heart (optimistic, scale-pop animation, haptic) or
  double-tap anywhere on the caption/media (like-only — never unlikes).
- **Comments**: bottom sheet with nested replies (one level), edit/delete
  restricted to the comment's own author (matched by username), 300-char
  limit, a quick-emoji row, and a fade/slide-in animation per comment.
- **Save**: bookmark icon or the three-dot menu; surfaced in Profile → Saved
  Posts.
- **Share**: visual placeholder sheet (Copy Link / WhatsApp / Telegram /
  Email / More) — none of these actually share yet; `ShareService` is the
  seam to wire in `share_plus` later without touching the UI.
- **Report**: three-dot menu → reason list (Spam / Harassment / Fake
  Content / Violence / Other) → submit → success confirmation. Stored
  locally, ready for a moderation backend.
- **Post menu**: Save, Share, Report, Copy Link (copies a
  `skillverse://post/{id}` placeholder link to the clipboard).
- **Profile additions**: Saved Posts / Liked Posts nav tiles, an Activity
  Summary stat row (posts published, likes given, comments made), and a
  Recent Activity preview with "View all" → full activity list.

Every like/comment/save/publish action is appended to a local activity log
(`PostProvider.activityLog`), capped at 200 entries, and persisted via
`InteractionLocalStorageService`.

## Test checklist

- [ ] Signup creates a Firebase Auth user + Firestore doc with defaults
- [ ] Signup button stays disabled until username/email/password/confirm all pass validation
- [ ] Login works; wrong password / unknown user / no network show distinct messages
- [ ] Google Sign-In creates a Firestore doc on first login, reuses it after
- [ ] Forgot Password sends a reset email and shows confirmation
- [ ] Killing and reopening the app while logged in skips Login (auto-login)
- [ ] New user is routed Category → Goal → Home; returning user goes straight to Home
- [ ] Sign Out clears Firebase + Google session and returns to Login
- [ ] Publish is disabled with an empty caption and no media
- [ ] Publish is disabled past 1000 characters (counter turns red)
- [ ] Selecting an image after a video replaces it (and vice versa)
- [ ] Save Draft, leave the composer, come back — draft is restored
- [ ] Publish shows progress, then a success animation, then returns to Home
- [ ] New post appears at the top of the Home feed immediately
- [ ] Like/Save toggle instantly and persist after an app restart
- [ ] Double-tap on a post's caption/media likes it and pops a heart (never unlikes)
- [ ] Tapping the heart button toggles like/unlike with a scale animation + haptic
- [ ] Comment sheet opens, shows count, and adding a comment updates it live
- [ ] Replying nests under the parent comment; editing/deleting only shows for your own comments
- [ ] Deleting a top-level comment also removes its replies
- [ ] Comment input blocks past 300 characters and blocks empty submits
- [ ] Save/unsave a post and confirm it appears/disappears in Profile → Saved Posts
- [ ] Like a post and confirm it appears in Profile → Liked Posts
- [ ] Three-dot menu shows Save / Share / Report / Copy Link; Copy Link copies to clipboard
- [ ] Report flow: pick a reason, submit, see success confirmation, sheet auto-closes
- [ ] Profile's Activity Summary counts and Recent Activity list update after each action
- [ ] No overflow errors on small screens; feed keeps scrolling smoothly with comments open/closed
