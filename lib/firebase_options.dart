// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAmoQjpmoGK8SpW7a9YU3Q3-0mnvwC0I0U',
    appId: '1:256841801977:android:34ed79428e1c2ce16b8228',
    messagingSenderId: '256841801977',
    projectId: 'gamenoteapp',
    storageBucket: 'gamenoteapp.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDwmjbMx0b7m8fAPe5g8934X1y003mrFH0',
    appId: '1:256841801977:ios:ca5f6c73eff78aac6b8228',
    messagingSenderId: '256841801977',
    projectId: 'gamenoteapp',
    storageBucket: 'gamenoteapp.appspot.com',
    androidClientId: '256841801977-4gk9c14654vco9ivfsj6r94hlem7sj72.apps.googleusercontent.com',
    iosClientId: '256841801977-j6gpu5cq3etlp5pgsrclkd0m9iddrbl3.apps.googleusercontent.com',
    iosBundleId: 'com.november.gameNote',
  );

}