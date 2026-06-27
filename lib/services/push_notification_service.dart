import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../utils/fcm_token_manager.dart';
import '../firebase_options.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FCMTokenManager _tokenManager = FCMTokenManager();

  Future<void> initialize() async {
    if (kIsWeb) {
      try {
        // Check if service worker is registered
        if (await _isServiceWorkerRegistered()) {
          debugPrint('Service Worker is registered and ready');
        } else {
          debugPrint('WARNING: Service Worker not registered properly');
        }

        // Request permission for web
        NotificationSettings settings = await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          debugPrint('User granted permission for push notifications');

          // Get and register FCM token
          await _registerToken();

          // Set up message handlers
          _setupMessageHandlers();
        } else {
          debugPrint('User declined or has not accepted permission for push notifications');
        }
      } catch (e) {
        debugPrint('Error initializing push notifications: $e');
      }
    }
  }

  Future<bool> _isServiceWorkerRegistered() async {
    // This is a web-specific check that will be handled by JavaScript
    // For now, we'll assume it's registered if we're in web mode
    return kIsWeb;
  }

  Future<void> _registerToken() async {
    try {
      String? token = await _firebaseMessaging.getToken(
        vapidKey: DefaultFirebaseOptions.vapidKey,
      );

      if (token != null) {
        debugPrint('FCM Token obtained successfully: ${token.substring(0, 50)}...');
        await _tokenManager.saveToken(token);
        debugPrint('FCM Token saved to Firestore successfully');
      } else {
        debugPrint('ERROR: FCM Token is null');
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Handle messages when app is opened from background/terminated state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message opened app: ${message.notification?.title}');
      _handleMessageClick(message);
    });

    // Handle messages when app is in background (for initial launch)
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App launched from notification: ${message.notification?.title}');
        _handleMessageClick(message);
      }
    });
  }

  void _showLocalNotification(RemoteMessage message) {
    // For web, the service worker handles showing notifications
    // This is just for logging
    debugPrint('Foreground notification: ${message.notification?.title} - ${message.notification?.body}');
  }

  void _handleMessageClick(RemoteMessage message) {
    // Navigate based on the click action
    final clickAction = message.data['click_action'] ?? '/admin/notificacoes';
    debugPrint('Handling notification click: $clickAction');

    // Navigation will be handled by the app's routing system
    // This is just a placeholder for future implementation
  }

  Future<void> deleteToken() async {
    await _tokenManager.deleteToken();
  }

  /// Save FCM token for the current user (public method)
  Future<void> saveTokenForCurrentUser() async {
    await _registerToken();
  }
}
