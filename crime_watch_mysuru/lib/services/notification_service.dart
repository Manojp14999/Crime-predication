import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'crime_alerts',
    'Crime Alerts',
    description: 'Emergency crime alerts for Mysuru District',
    importance: Importance.max,
    playSound: true,
  );

  static Future<void> init() async {
    try {
      // Request permission only on Android 13+ (API 33+)
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('Notification permission error: $e');
    }

    try {
      // Create Android notification channel
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    } catch (e) {
      debugPrint('Notification channel error: $e');
    }

    try {
      // Init local notifications
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      await _localNotifications.initialize(
        const InitializationSettings(android: androidSettings),
      );
    } catch (e) {
      debugPrint('Notification init error: $e');
    }

    try {
      // Foreground message handler
      FirebaseMessaging.onMessage.listen((message) {
        showLocalNotification(message);
      });
    } catch (e) {
      debugPrint('Foreground listener error: $e');
    }

    try {
      // Subscribe to all alerts topic
      await FirebaseMessaging.instance.subscribeToTopic('crime_alerts');
      // Get FCM token
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('FCM Token: $token');
    } catch (e) {
      debugPrint('FCM subscribe error: $e');
    }
  }

  static Future<void> subscribeToArea(String area) async {
    final topic = area.toLowerCase().replaceAll(' ', '_');
    await FirebaseMessaging.instance.subscribeToTopic(topic);
  }

  static Future<void> unsubscribeFromArea(String area) async {
    final topic = area.toLowerCase().replaceAll(' ', '_');
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
  }

  static void showLocalNotification(RemoteMessage message) {
    try {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (e) {
      debugPrint('showLocalNotification error: $e');
    }
  }

  static Future<void> showLocalAlert({
    required String title,
    required String body,
  }) async {
    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (e) {
      debugPrint('showLocalAlert error: $e');
    }
  }
}
