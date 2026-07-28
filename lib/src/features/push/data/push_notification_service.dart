import 'dart:async';

import 'package:eventa/src/core/app_runtime_config.dart';
import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/chat/presentation/pages/event_chat_page.dart';
import 'package:eventa/src/features/chat/presentation/pages/meeting_chat_page.dart';
import 'package:eventa/src/features/meetings/data/campaign_local_storage.dart';
import 'package:eventa/src/features/meetings/data/meeting_repository.dart';
import 'package:eventa/src/features/meetings/presentation/pages/campaign_detail_page.dart';
import 'package:eventa/src/features/meetings/presentation/pages/meeting_candidates_page.dart';
import 'package:eventa/src/features/push/data/push_device_storage.dart';
import 'package:eventa/src/features/push/presentation/push_ui_context.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Background handler (должен быть top-level).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Навигация обрабатывается при открытии через getInitialMessage /
  // onMessageOpenedApp.
}

class PushNotificationService {
  PushNotificationService({
    PushDeviceStorage? storage,
    FirebaseMessaging? messaging,
  }) : _storage = storage ?? PushDeviceStorage(),
       _messaging = messaging ?? FirebaseMessaging.instance;

  final PushDeviceStorage _storage;
  final FirebaseMessaging _messaging;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  GlobalKey<NavigatorState>? _navigatorKey;
  bool _started = false;

  Future<void> start(GlobalKey<NavigatorState> navigatorKey) async {
    if (!appUsesFirebaseBackend || kIsWeb) return;
    if (!(defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS)) {
      return;
    }

    _navigatorKey = navigatorKey;
    if (_started) return;
    _started = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
    } catch (_) {}

    final uid = await getIt<AuthRepository>().currentUserId();
    if (uid == null) return;

    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _storage.upsertToken(uid: uid, token: token);
      }
    } catch (e) {
      debugPrint('FCM getToken failed: $e');
    }

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) async {
      final currentUid = await getIt<AuthRepository>().currentUserId();
      if (currentUid == null) return;
      await _storage.upsertToken(uid: currentUid, token: token);
    });

    _openedSub?.cancel();
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);

    _foregroundSub?.cancel();
    _foregroundSub = FirebaseMessaging.onMessage.listen(_onForeground);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onOpened(initial);
      });
    }
  }

  Future<void> stopAndClearToken() async {
    final uid = await getIt<AuthRepository>().currentUserId();
    if (uid != null && appUsesFirebaseBackend) {
      try {
        await _storage.removeCurrentDevice(uid);
      } catch (_) {}
    }
    await _tokenRefreshSub?.cancel();
    await _openedSub?.cancel();
    await _foregroundSub?.cancel();
    _tokenRefreshSub = null;
    _openedSub = null;
    _foregroundSub = null;
    _started = false;
  }

  void _onForeground(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    if (type == 'meeting_chat' &&
        data['meetingId'] == PushUiContext.openMeetingChatId) {
      return;
    }
    if (type == 'event_chat_digest' &&
        data['eventId'] == PushUiContext.openEventChatId) {
      return;
    }

    final ctx = _navigatorKey?.currentContext;
    if (ctx == null || !ctx.mounted) return;
    final title = message.notification?.title ?? 'Eventa';
    final body = message.notification?.body ?? '';
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(body.isEmpty ? title : '$title\n$body'),
        action: SnackBarAction(
          label: 'Открыть',
          onPressed: () => _navigateFromData(data),
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  void _onOpened(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  Future<void> _navigateFromData(Map<String, dynamic> data) async {
    final ctx = _navigatorKey?.currentContext;
    if (ctx == null || !ctx.mounted) return;

    final type = data['type'] as String?;
    final uid = await getIt<AuthRepository>().currentUserId() ?? 'user-1';

    switch (type) {
      case 'meeting_chat':
        final meetingId = data['meetingId'] as String?;
        if (meetingId == null) return;
        final meeting = await MeetingRepository().readById(meetingId);
        if (!ctx.mounted) return;
        await Navigator.of(ctx).push(
          MaterialPageRoute(
            builder:
                (_) => MeetingChatPage(
                  meetingId: meetingId,
                  myUserId: uid,
                  title:
                      meeting?.topic.isNotEmpty == true
                          ? meeting!.topic
                          : (meeting?.venueName ?? 'Чат встречи'),
                ),
          ),
        );
      case 'meeting_joined':
        final meetingId = data['meetingId'] as String?;
        if (meetingId == null) return;
        final meeting = await MeetingRepository().readById(meetingId);
        if (meeting == null || !ctx.mounted) return;
        await Navigator.of(ctx).push(
          MaterialPageRoute(
            builder: (_) => MeetingCandidatesPage(meeting: meeting),
          ),
        );
      case 'campaign_new_meeting':
        final campaignId = data['campaignId'] as String?;
        if (campaignId == null) return;
        final all = await CampaignLocalStorage().readAll();
        final campaign = all.where((c) => c.id == campaignId).firstOrNull;
        if (campaign == null || !ctx.mounted) return;
        await Navigator.of(ctx).push(
          MaterialPageRoute(
            builder: (_) => CampaignDetailPage(campaign: campaign),
          ),
        );
      case 'event_chat_digest':
        final eventId = data['eventId'] as String?;
        final title = data['eventTitle'] as String? ?? 'Чат события';
        if (eventId == null || !ctx.mounted) return;
        await Navigator.of(ctx).push(
          MaterialPageRoute(
            builder: (_) => EventChatPage(eventId: eventId, eventTitle: title),
          ),
        );
    }
  }
}

/// Глобальный сервис push (один на процесс).
final pushNotificationService = PushNotificationService();
