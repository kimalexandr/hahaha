import 'package:eventa/src/features/chat/data/chat_local_storage.dart';
import 'package:eventa/src/features/chat/domain/entities/chat_message.dart';
import 'package:flutter/material.dart';

class MeetingChatPage extends StatefulWidget {
  const MeetingChatPage({
    super.key,
    required this.chatId,
    required this.myUserId,
    required this.peerName,
  });

  final String chatId;
  final String myUserId;
  final String peerName;

  @override
  State<MeetingChatPage> createState() => _MeetingChatPageState();
}

class _MeetingChatPageState extends State<MeetingChatPage> {
  final _storage = ChatLocalStorage();
  final _controller = TextEditingController();
  List<ChatMessage> _messages = [];
  bool _loading = true;

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
    final messages = await _storage.readMessages(widget.chatId);
    if (!mounted) return;
    setState(() {
      _messages = messages;
      _loading = false;
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final message = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      chatId: widget.chatId,
      senderId: widget.myUserId,
      text: text,
      createdAt: DateTime.now(),
    );
    await _storage.addMessage(message);
    _controller.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Чат с ${widget.peerName}')),
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
                        final mine = msg.senderId == widget.myUserId;
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
                        hintText: 'Сообщение',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
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
