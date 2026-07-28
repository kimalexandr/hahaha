import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventa/src/core/app_runtime_config.dart';
import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/push/domain/notification_settings.dart';
import 'package:flutter/material.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key, required this.isOrganizer});

  final bool isOrganizer;

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  NotificationSettings _settings = const NotificationSettings();
  bool _loading = true;
  String? _uid;
  String? _updatingField;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = await getIt<AuthRepository>().currentUserId();
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    _uid = uid;

    if (!appUsesFirebaseBackend) {
      if (mounted) {
        setState(() {
          _settings = const NotificationSettings();
          _loading = false;
        });
      }
      return;
    }

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final raw = doc.data()?['notificationSettings'];
      final settings = NotificationSettings.fromMap(
        raw is Map ? Map<dynamic, dynamic>.from(raw) : null,
      );
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _update(String field, bool value) async {
    final uid = _uid;
    setState(() {
      _updatingField = field;
      _settings = NotificationSettings(
        meetingChat:
            field == 'meetingChat' ? value : _settings.meetingChat,
        meetingJoined:
            field == 'meetingJoined' ? value : _settings.meetingJoined,
        eventChatDigest:
            field == 'eventChatDigest' ? value : _settings.eventChatDigest,
        campaignUpdates:
            field == 'campaignUpdates' ? value : _settings.campaignUpdates,
      );
    });

    if (uid == null || !appUsesFirebaseBackend) {
      if (mounted) setState(() => _updatingField = null);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'notificationSettings.$field': value,
      });
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'notificationSettings': _settings.toMap(),
        }, SetOptions(merge: true));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось сохранить: ${e.message}')),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Не удалось сохранить: $e')));
        await _load();
      }
    } finally {
      if (mounted) setState(() => _updatingField = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Уведомления')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                children: [
                  if (!appUsesFirebaseBackend)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'В демо-режиме настройки сохраняются только локально '
                        'на время сессии.',
                      ),
                    ),
                  SwitchListTile(
                    title: const Text('Сообщения в чате встречи'),
                    subtitle: const Text('Пуш при новом сообщении в чате компании'),
                    value: _settings.meetingChat,
                    onChanged:
                        _updatingField == 'meetingChat'
                            ? null
                            : (v) => _update('meetingChat', v),
                  ),
                  SwitchListTile(
                    title: const Text('Новый участник встречи'),
                    subtitle: const Text(
                      'Когда кто-то присоединился или группа набрана',
                    ),
                    value: _settings.meetingJoined,
                    onChanged:
                        _updatingField == 'meetingJoined'
                            ? null
                            : (v) => _update('meetingJoined', v),
                  ),
                  SwitchListTile(
                    title: const Text('Дайджест чата события'),
                    subtitle: const Text(
                      'Сводка непрочитанных сообщений раз в ~20 минут',
                    ),
                    value: _settings.eventChatDigest,
                    onChanged:
                        _updatingField == 'eventChatDigest'
                            ? null
                            : (v) => _update('eventChatDigest', v),
                  ),
                  if (widget.isOrganizer)
                    SwitchListTile(
                      title: const Text('Обновления по кампаниям'),
                      subtitle: const Text(
                        'Новые встречи под вашу кампанию сбора компании',
                      ),
                      value: _settings.campaignUpdates,
                      onChanged:
                          _updatingField == 'campaignUpdates'
                              ? null
                              : (v) => _update('campaignUpdates', v),
                    ),
                ],
              ),
    );
  }
}
