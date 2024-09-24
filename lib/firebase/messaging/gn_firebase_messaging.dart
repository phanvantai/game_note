import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:game_note/firebase/firestore/user/gn_firestore_user.dart';
import 'package:game_note/injection_container.dart';

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
      _getToken();
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

  // Get the FCM token
  void _getToken() async {
    String? token = await _firebaseMessaging.getToken();
    if (kDebugMode) {
      print("FCM Token: $token");
    }
    if (token != null) {
      // Save the token to the user's document in Firestore
      getIt<GNFirestore>().updateFcmToken(token);
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
