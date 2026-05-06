import 'package:firebase_messaging/firebase_messaging.dart';
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
    // Request permission
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

    // Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Init local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings),
    );

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((message) {
      showLocalNotification(message);
    });

    // Subscribe to all alerts topic
    await FirebaseMessaging.instance.subscribeToTopic('crime_alerts');

    // Get and print FCM token (useful for testing)
    final token = await FirebaseMessaging.instance.getToken();
    // ignore: avoid_print
    print('FCM Token: $token');
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
  }

  static Future<void> showLocalAlert({
    required String title,
    required String body,
  }) async {
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
  }
}
