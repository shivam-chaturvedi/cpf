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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBahIGKXFHSrZHdzBG4sLzGg2GVW0psTdc',
    appId: '1:424748901720:web:e4e636862ad2cc7712f12d',
    messagingSenderId: '424748901720',
    projectId: 'cpfportal-30104',
    authDomain: 'cpfportal-30104.firebaseapp.com',
    storageBucket: 'cpfportal-30104.firebasestorage.app',
    measurementId: 'G-B0QRY75CBW',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBahIGKXFHSrZHdzBG4sLzGg2GVW0psTdc',
    appId: '1:424748901720:android:YOUR_ANDROID_APP_ID', // You'll need to add Android app in Firebase Console
    messagingSenderId: '424748901720',
    projectId: 'cpfportal-30104',
    storageBucket: 'cpfportal-30104.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBahIGKXFHSrZHdzBG4sLzGg2GVW0psTdc',
    appId: '1:424748901720:ios:YOUR_IOS_APP_ID', // You'll need to add iOS app in Firebase Console
    messagingSenderId: '424748901720',
    projectId: 'cpfportal-30104',
    storageBucket: 'cpfportal-30104.firebasestorage.app',
    iosBundleId: 'com.example.cpfportal', // Change this to your actual iOS bundle ID
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBahIGKXFHSrZHdzBG4sLzGg2GVW0psTdc',
    appId: '1:424748901720:ios:YOUR_IOS_APP_ID', // You'll need to add macOS app in Firebase Console
    messagingSenderId: '424748901720',
    projectId: 'cpfportal-30104',
    storageBucket: 'cpfportal-30104.firebasestorage.app',
    iosBundleId: 'com.example.cpfportal', // Change this to your actual macOS bundle ID
  );
}