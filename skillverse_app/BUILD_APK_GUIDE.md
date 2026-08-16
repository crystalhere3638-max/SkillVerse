# Building the Release APK (Phone-only workflow)

This sandbox has no Flutter SDK and no internet access, so `flutter pub get`
and `flutter build apk --release` can't be run here. A GitHub Actions
workflow (`.github/workflows/build_apk.yml`) has been added to this project
so the release APK can be built in the cloud and downloaded straight to
your phone — no PC required.

## One-time setup

1. Create a new GitHub repository (via the GitHub mobile app or
   github.com in your phone browser).
2. Upload/push this entire project folder to that repository.
   - Easiest from a phone: use the GitHub mobile app's "Add file ->
     Upload files" for a first commit, or use a Git client app
     (e.g. Working Copy on iOS, or termux + git on Android) if you
     want proper version control.

## Every time you want a release APK

1. Open the repo in the GitHub app or github.com.
2. Go to the **Actions** tab.
3. Select **Build Release APK** in the left sidebar.
4. Tap **Run workflow** -> **Run workflow** (this triggers it manually).
   It also runs automatically on every push to `main`.
5. Wait a few minutes for the run to go green (✅).
6. Open the completed run, scroll to **Artifacts**, and download
   **app-release-apk** — that's your `app-release.apk`, ready to
   install/share.

## If the build fails

Open the failed run and check the **Build release APK** step's log —
it will show the exact Gradle/Dart error. Common first-build issues:

- **Firebase Google Sign-In errors at runtime (not build time)**: you
  still need to register your keystore's SHA-1 fingerprint in the
  Firebase console for Google Sign-In to work (see earlier notes).
- **Gradle wrapper**: already handled automatically by the workflow
  (it downloads `gradle-wrapper.jar` if missing).

## Alternative: Codemagic

If you'd rather use a GUI instead of YAML/Actions, Codemagic
(https://codemagic.io) also has a free tier, auto-detects Flutter
projects, and can build + deliver the APK to you — also usable
entirely from a phone browser. Connect the same GitHub repo there if
you'd prefer that flow instead.
