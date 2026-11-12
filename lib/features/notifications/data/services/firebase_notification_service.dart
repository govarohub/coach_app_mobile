import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/router/route_names.dart';

class FirebaseNotificationService {
  FirebaseNotificationService._();

  static final FirebaseNotificationService instance =
      FirebaseNotificationService._();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, String> _activeTokens = {};

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _openedMessageSubscription;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(
      _showForegroundMessage,
    );
    _openedMessageSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _openReservations,
    );
    _tokenSubscription = _messaging.onTokenRefresh.listen((token) {
      final uid = _auth.currentUser?.uid;
      if (uid != null) unawaited(_saveToken(uid, token));
    });
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) unawaited(_registerUser(user.uid));
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openReservations(initialMessage);
      });
    }
  }

  Future<void> unregisterCurrentUserToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final tokens = await _firestore
          .collection('fcmTokens')
          .where('uid', isEqualTo: user.uid)
          .get();
      final batch = _firestore.batch();
      for (final token in tokens.docs) {
        batch.delete(token.reference);
      }
      if (tokens.docs.isNotEmpty) await batch.commit();
      _activeTokens.remove(user.uid);
    } catch (error) {
      debugPrint('No fue posible retirar el token de notificaciones: $error');
    }
  }

  Future<void> _registerUser(String uid) async {
    if (!_supportsPushNotifications) return;

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }

      const webVapidKey = String.fromEnvironment('FCM_WEB_VAPID_KEY');
      if (kIsWeb && webVapidKey.isEmpty) {
        debugPrint('Push web omitido: falta FCM_WEB_VAPID_KEY.');
        return;
      }

      final token = await _messaging.getToken(
        vapidKey: kIsWeb ? webVapidKey : null,
      );
      if (token != null && token.isNotEmpty) {
        await _saveToken(uid, token);
      }
    } catch (error) {
      debugPrint('No fue posible registrar notificaciones push: $error');
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    final previousToken = _activeTokens[uid];
    final tokenReference = _firestore
        .collection('fcmTokens')
        .doc(_tokenDocumentId(token));

    await tokenReference.set({
      'uid': uid,
      'token': token,
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _activeTokens[uid] = token;
    if (previousToken != null && previousToken != token) {
      await _firestore
          .collection('fcmTokens')
          .doc(_tokenDocumentId(previousToken))
          .delete();
    }
  }

  bool get _supportsPushNotifications {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  String _tokenDocumentId(String token) => Uri.encodeComponent(token);

  void _showForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title?.trim();
    final body = message.notification?.body?.trim();
    final text = [title, body]
        .whereType<String>()
        .where((part) => part.isNotEmpty)
        .join('\n');
    if (text.isEmpty) return;

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(text),
        action: SnackBarAction(
          label: 'Ver reservas',
          onPressed: () => _openReservations(message),
        ),
      ),
    );
  }

  void _openReservations(RemoteMessage message) {
    if (message.data['reservationId'] == null) return;
    AppRouter.router.goNamed(RouteNames.reservations);
  }
}