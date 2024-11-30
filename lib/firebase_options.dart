// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDQT-SvcUhfBQGY2v79lfcAvcIVbJG3t1c',
    appId: '1:124791319956:web:0b6683ed836c307f267381',
    messagingSenderId: '124791319956',
    projectId: 'kbc-db-d926a',
    authDomain: 'kbc-db-d926a.firebaseapp.com',
    storageBucket: 'kbc-db-d926a.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyACVShVlKPF04Trs_5nPEgsvkXNQNi2tF4',
    appId: '1:124791319956:android:899d60fc2799f4ec267381',
    messagingSenderId: '124791319956',
    projectId: 'kbc-db-d926a',
    storageBucket: 'kbc-db-d926a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCxlRb3C0bEpDK8JKINnmtWq4ZZpxSx224',
    appId: '1:124791319956:ios:ef5f142fd58622d6267381',
    messagingSenderId: '124791319956',
    projectId: 'kbc-db-d926a',
    storageBucket: 'kbc-db-d926a.firebasestorage.app',
    iosBundleId: 'com.example.kbconnect',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCxlRb3C0bEpDK8JKINnmtWq4ZZpxSx224',
    appId: '1:124791319956:ios:ef5f142fd58622d6267381',
    messagingSenderId: '124791319956',
    projectId: 'kbc-db-d926a',
    storageBucket: 'kbc-db-d926a.firebasestorage.app',
    iosBundleId: 'com.example.kbconnect',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDQT-SvcUhfBQGY2v79lfcAvcIVbJG3t1c',
    appId: '1:124791319956:web:957cbc3d596fd7b2267381',
    messagingSenderId: '124791319956',
    projectId: 'kbc-db-d926a',
    authDomain: 'kbc-db-d926a.firebaseapp.com',
    storageBucket: 'kbc-db-d926a.firebasestorage.app',
  );

}