# SkillVerse — Firestore Migration: Posts, Comments, Likes (Phase 2, partial)

This covers the first slice of the Firestore migration. Everything else
(videos, competitions, missions, badges, leaderboard, notifications) is
still local/mock — see "What's NOT migrated yet" below.

## Collections

### `posts/{postId}`
| field | type | notes |
|---|---|---|
| authorId | string | Firebase Auth uid, set at creation, immutable |
| authorName | string | denormalized so the feed never reads `users/{uid}` for other people |
| authorLevel | string | denormalized, e.g. `"Lv.1"` |
| category | string | |
| caption | string | max 1000 chars, enforced by security rules |
| mediaType | string | `"none" \| "image" \| "video"` |
| mediaUrl | string? | Firebase Storage download URL, or null for text-only posts |
| createdAt | Timestamp | server-assigned (`FieldValue.serverTimestamp()`) |
| likeCount | number | maintained by the `setLiked` transaction — never written directly by a client update outside that transaction |

### `comments/{commentId}`
| field | type | notes |
|---|---|---|
| postId | string | which post this belongs to |
| authorId | string | |
| authorName | string | |
| authorLevel | string | |
| text | string | max 500 chars |
| createdAt | Timestamp | |
| editedAt | Timestamp? | set on edit |
| parentId | string? | non-null = this is a reply |

### `likes/{postId}_{uid}`
Deterministic doc id (`postId_uid`) so "did I like this" is a single
doc read/existence check, not a query, and a user can't create two
like docs for the same post.
| field | type |
|---|---|
| postId | string |
| userId | string |
| createdAt | Timestamp |

### `saves/{postId}_{uid}`
Same shape/id scheme as `likes`. Not in the original 9-collection
list from the spec, but the app already had a Saved Posts screen
before this migration — needed somewhere to live.

### `users/{uid}`
Unchanged — already Firestore-backed before this pass
(`firestore_user_service.dart`), rules unchanged.

## What's NOT migrated yet
`videos`, `competitions`, `missions`, `badges`, `leaderboard`,
`notifications` are still local/mock (SharedPreferences or hardcoded).
`firestore.rules` locks all of these to **read-only, no client
writes** until each gets its own migration pass — this is
intentional, not an oversight, so a signed-in client can't write
unvalidated data into a collection the app doesn't police yet.

## Realtime behavior
`PostRepository.watchFeed(uid)` combines four live listeners
(`posts`, `comments`, `likes` filtered to `uid`, `saves` filtered to
`uid`) into one `Stream<List<Post>>`. `PostProvider` keeps its exact
pre-existing public API (`feedItems`, `toggleLike`, `addComment`,
etc.) — no screen needed to change.

One deliberate trade-off: after the *first* load, new snapshots
update engagement numbers/comments on posts already on screen in
place (so someone else's like ticking up mid-scroll doesn't jump your
list around), but a **brand-new post** only appears after the next
pull-to-refresh or filter change, not instantly. Fine for now; true
incremental "new post at top" handling can be added later without
touching the public API.

## Before this actually runs
1. `flutterfire configure` (or manually drop in `google-services.json`
   / `GoogleService-Info.plist` + a real `lib/firebase_options.dart`)
   — nothing here fabricates credentials, per your instruction.
2. `firebase deploy --only firestore:rules` (needs a `firebase.json`
   pointing at `firestore.rules`, and `firebase init` if you don't
   have one — not created here since it needs your real project id).
3. `flutter pub get`.
4. First run on a fresh project = an empty feed (no more fake mock
   seed data) — that's correct, not a bug. Publish a post to see the
   pipeline work end to end.
