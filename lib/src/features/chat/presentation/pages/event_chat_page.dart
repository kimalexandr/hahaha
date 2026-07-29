import 'dart:async';

import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/core/widgets/app_user_avatar.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/chat/domain/entities/chat_message.dart';
import 'package:eventa/src/features/meetings/data/meeting_repository.dart';
import 'package:eventa/src/features/profile/data/profile_persistence.dart';
import 'package:eventa/src/features/profile/presentation/pages/public_profile_page.dart';
import 'package:eventa/src/features/push/presentation/push_ui_context.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventChatPage extends StatefulWidget {
  const EventChatPage({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  final String eventId;
  final String eventTitle;

  @override
  State<EventChatPage> createState() => _EventChatPageState();
}

class _EventChatPageState extends State<EventChatPage> {
  final _repo = MeetingRepository();
  final _controller = TextEditingController();
  StreamSubscription<List<ChatMessage>>? _sub;
  List<ChatMessage> _messages = [];
  bool _loading = true;
  String _uid = 'user-1';
  String _myName = 'Я';
  String? _myPhoto;

  @override
  void initState() {
    super.initState();
    PushUiContext.openEventChatId = widget.eventId;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _uid = await getIt<AuthRepository>().currentUserId() ?? 'user-1';
    final me = await ProfilePersistence().read(_uid);
    if (me != null && mounted) {
      setState(() {
        _myName = me.name;
        _myPhoto = me.mainPhotoUrl;
      });
    }
    _sub = _repo
        .watchEventChat(widget.eventId)
        .listen(
          (messages) {
            if (!mounted) return;
            setState(() {
              _messages = messages;
              _loading = false;
            });
          },
          onError: (_) {
            if (!mounted) return;
            setState(() => _loading = false);
          },
        );
  }

  @override
  void dispose() {
    if (PushUiContext.openEventChatId == widget.eventId) {
      PushUiContext.openEventChatId = null;
    }
    _sub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await _repo.sendEventChatMessage(
      eventId: widget.eventId,
      senderId: _uid,
      text: text,
      senderName: _myName,
      senderPhotoUrl: _myPhoto,
    );
    final latest = await _repo.watchEventChat(widget.eventId).first;
    if (!mounted) return;
    setState(() => _messages = latest);
  }

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm', 'ru');
    return Scaffold(
      appBar: AppBar(title: Text('Чат: ${widget.eventTitle}')),
      body: Column(
        children: [
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                    ? const Center(child: Text('Напишите первое сообщение'))
                    : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final mine = msg.senderId == _uid;
                        final name =
                            msg.senderName?.isNotEmpty == true
                                ? msg.senderName!
                                : (mine ? _myName : 'Участник');
                        return Align(
                          alignment:
                              mine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * 0.82,
                            ),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    mine
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer
                                        : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppUserAvatar(
                                    photoUrl:
                                        msg.senderPhotoUrl ??
                                        (mine ? _myPhoto : null),
                                    name: name,
                                    radius: 16,
                                    onTap: () {
                                      openPublicProfile(
                                        context,
                                        userId: msg.senderId,
                                        fallbackName: name,
                                        fallbackPhotoUrl:
                                            msg.senderPhotoUrl ??
                                            (mine ? _myPhoto : null),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(msg.text),
                                        const SizedBox(height: 4),
                                        Text(
                                          timeFmt.format(
                                            msg.createdAt.toLocal(),
                                          ),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelSmall?.copyWith(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Сообщение участникам',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(onPressed: _send, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
