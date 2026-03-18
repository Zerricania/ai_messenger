import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Сервис для работы с push-уведомлениями (Firebase Cloud Messaging).
class FcmService {
  FcmService._();

  static final _messaging = FirebaseMessaging.instance;
  static final _firestore = FirebaseFirestore.instance;

  static Future<void> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('FCM: пользователь отклонил уведомления');
      return;
    }

    await _saveToken();
    _messaging.onTokenRefresh.listen(_updateToken);

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
          'FCM foreground: ${message.notification?.title} — ${message.notification?.body}');
    });
  }

  static Future<void> _saveToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await _messaging.getToken();
    if (token == null) return;
    await _updateToken(token);
    debugPrint('FCM token сохранён');
  }

  static Future<void> _updateToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).update({
      'fcmToken': token,
      'fcmTokenUpdatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<void> onUserLoggedIn() async {
    await _saveToken();
  }

  static Future<void> onUserLoggedOut() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).update({
      'fcmToken': FieldValue.delete(),
    });
    await _messaging.deleteToken();
  }
}
