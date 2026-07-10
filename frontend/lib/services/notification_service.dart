import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> initialize(BuildContext context) async {
    try {
      // 1. Request notification permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted notification permission.');

        // 2. Fetch FCM Token
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          print('FCM Token: $token');
          // If user is already logged in, update token on the backend
          if (await ApiService.isLoggedIn()) {
            await ApiService.updateFcmToken(token);
          }
        }

        // 3. Listen to token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) async {
          if (await ApiService.isLoggedIn()) {
            await ApiService.updateFcmToken(newToken);
          }
        });

        // 4. Handle Foreground Messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print('Notification received in foreground!');
          if (message.notification != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.notification!.title ?? 'Kap Oferten!',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.notification!.body ?? '',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF1E293B), // Premium dark gray
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'SHIKO',
                  textColor: const Color(0xFF10B981), // Premium emerald green
                  onPressed: () {
                    Navigator.pushNamed(context, '/notifications');
                  },
                ),
              ),
            );
          }
        });

        // 5. Handle Background Notification Click Routing
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          print('Notification clicked, routing to notifications screen.');
          Navigator.pushNamed(context, '/notifications');
        });
      }
    } catch (e) {
      print('Firebase Messaging initialization failed: $e. Running without push notifications.');
    }
  }
}
