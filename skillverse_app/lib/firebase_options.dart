// GENERATED PLACEHOLDER — replace by running:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// This will overwrite this file with real values for your Firebase
// project (Android/iOS/Web) and register the apps automatically.
// Do NOT commit real API keys from this placeholder — it intentionally
// contains dummy values so the project does not compile against a
// live project by accident.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform. '
          'Run `flutterfire configure` to generate real options.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    authDomain: 'REPLACE_ME.firebaseapp.com',
    storageBucket: 'REPLACE_ME.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDls3m4PUlecR5rW6xNb-IFmX3NvnUBNIA',
    appId: '1:355191998600:android:d590f83bf45d069dd6373d',
    messagingSenderId: '355191998600',
    projectId: 'skillverse-2d596',
    storageBucket: 'skillverse-2d596.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME.appspot.com',
    iosBundleId: 'com.example.skillverseApp',
  );
}
