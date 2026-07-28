import 'dart:async';

import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/chat/domain/entities/chat_message.dart';
import 'package:eventa/src/features/meetings/data/meeting_repository.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _uid = await getIt<AuthRepository>().currentUserId() ?? 'user-1';
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
    );
    final latest = await _repo.watchEventChat(widget.eventId).first;
    if (!mounted) return;
    setState(() => _messages = latest);
  }

  @override
  Widget build(BuildContext context) {
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
                        return Align(
                          alignment:
                              mine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
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
                            child: Text(msg.text),
                          ),
                        );
                      },
                    ),
          ),
          SafeArea(
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
