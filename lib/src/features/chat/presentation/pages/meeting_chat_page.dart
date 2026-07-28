import 'dart:async';

import 'package:eventa/src/features/chat/domain/entities/chat_message.dart';
import 'package:eventa/src/features/meetings/data/meeting_repository.dart';
import 'package:eventa/src/features/push/presentation/push_ui_context.dart';
import 'package:flutter/material.dart';

class MeetingChatPage extends StatefulWidget {
  const MeetingChatPage({
    super.key,
    required this.meetingId,
    required this.myUserId,
    required this.title,
  });

  final String meetingId;
  final String myUserId;
  final String title;

  @override
  State<MeetingChatPage> createState() => _MeetingChatPageState();
}

class _MeetingChatPageState extends State<MeetingChatPage> {
  final _repo = MeetingRepository();
  final _controller = TextEditingController();
  StreamSubscription<List<ChatMessage>>? _sub;
  List<ChatMessage> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    PushUiContext.openMeetingChatId = widget.meetingId;
    _sub = _repo
        .watchMeetingChat(widget.meetingId)
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
    if (PushUiContext.openMeetingChatId == widget.meetingId) {
      PushUiContext.openMeetingChatId = null;
    }
    _sub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await _repo.sendMeetingChatMessage(
      meetingId: widget.meetingId,
      senderId: widget.myUserId,
      text: text,
    );
    // В Hive stream одноразовый — перезагружаем.
    final latest = await _repo.watchMeetingChat(widget.meetingId).first;
    if (!mounted) return;
    setState(() => _messages = latest);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
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
