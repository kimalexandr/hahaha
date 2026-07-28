import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/chat/data/event_chat_local_storage.dart';
import 'package:eventa/src/features/chat/domain/entities/chat_message.dart';
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
  final _storage = EventChatLocalStorage();
  final _controller = TextEditingController();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  String _uid = 'user-1';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _uid = await getIt<AuthRepository>().currentUserId() ?? 'user-1';
    final messages = await _storage.readMessages(widget.eventId);
    if (!mounted) return;
    setState(() {
      _messages = messages;
      _loading = false;
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await _storage.addMessage(
      ChatMessage(
        id: 'emsg-${DateTime.now().millisecondsSinceEpoch}',
        chatId: widget.eventId,
        senderId: _uid,
        text: text,
        createdAt: DateTime.now(),
      ),
    );
    _controller.clear();
    await _load();
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
