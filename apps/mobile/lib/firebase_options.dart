import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'mock-web-api-key',
    appId: '1:1234567890:web:1234567890',
    messagingSenderId: '1234567890',
    projectId: 'rideos-mock-project',
    authDomain: 'rideos-mock-project.firebaseapp.com',
    storageBucket: 'rideos-mock-project.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDqPBrQJ0zA6fc3CXt3KIfbeyMWZ5cxabA',
    appId: '1:121485873641:android:f8b6a1c2afe3e8d81bfb78',
    messagingSenderId: '121485873641',
    projectId: 'rideos-ai',
    storageBucket: 'rideos-ai.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'mock-ios-api-key',
    appId: '1:1234567890:ios:1234567890',
    messagingSenderId: '1234567890',
    projectId: 'rideos-mock-project',
    storageBucket: 'rideos-mock-project.appspot.com',
    iosBundleId: 'com.rideos.mobile',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'mock-macos-api-key',
    appId: '1:1234567890:ios:1234567890',
    messagingSenderId: '1234567890',
    projectId: 'rideos-mock-project',
    storageBucket: 'rideos-mock-project.appspot.com',
    iosBundleId: 'com.rideos.mobile.macos',
  );
}
