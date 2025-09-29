import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:pes_arena/firebase/firestore/user/gn_firestore_user.dart';
import 'package:pes_arena/injection_container.dart';

import '../firestore/gn_firestore.dart';

class GNFirebaseMessaging {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Initialize Firebase and set up the message handlers
  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    _requestNotificationPermissions();
    _handleForegroundMessages();
    _handleBackgroundMessages();

    _onRefreshToken();

    _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // Request permissions for iOS
  void _requestNotificationPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted permission');
      }
      _getTokenSafely();
    } else {
      if (kDebugMode) {
        print('User declined or has not accepted permission');
      }
    }
  }

  void _onRefreshToken() {
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      if (kDebugMode) {
        print('Token refreshed: $token');
      }
      // Save the token to the user's document in Firestore
      getIt<GNFirestore>().updateFcmToken(token);
    });
  }

  // Get the FCM token safely, handling iOS APNS token requirement
  void _getTokenSafely() async {
    try {
      if (Platform.isIOS) {
        // On iOS, ensure APNS token is available before getting FCM token
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken == null) {
          if (kDebugMode) {
            print('APNS token not available yet, waiting...');
          }
          // Wait a bit and try again
          await Future.delayed(const Duration(seconds: 2));
          apnsToken = await _firebaseMessaging.getAPNSToken();
          if (apnsToken == null) {
            if (kDebugMode) {
              print(
                  'APNS token still not available, skipping FCM token retrieval');
            }
            return;
          }
        }
        if (kDebugMode) {
          print("APNS Token available: ${apnsToken.isNotEmpty}");
        }
      }

      String? token = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        print("FCM Token: $token");
      }
      if (token != null) {
        // Save the token to the user's document in Firestore
        getIt<GNFirestore>().updateFcmToken(token);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
    }
  }

  // Handle foreground messages
  void _handleForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Message received in foreground: ${message.notification?.body}');
      }
    });
  }

  // Handle messages when app is in background but not terminated
  void _handleBackgroundMessages() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Message clicked: ${message.notification?.body}');
        print('Message data: ${message.data}');
      }
    });
  }

  // Static background message handler
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    if (kDebugMode) {
      print("Handling a background message: ${message.messageId}");
    }
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}
