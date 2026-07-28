import 'package:eventa/src/features/chat/domain/entities/chat_message.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ChatLocalStorage {
  static const String _boxName = 'eventa_chats';

  Future<Box<dynamic>> _openBox() async {
    return Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : Hive.openBox(_boxName);
  }

  static String chatIdFor({
    required String meetingId,
    required String userA,
    required String userB,
  }) {
    final pair = [userA, userB]..sort();
    return '$meetingId:${pair.join('_')}';
  }

  Future<List<ChatMessage>> readMessages(String chatId) async {
    final box = await _openBox();
    final raw = box.get(chatId);
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((item) => ChatMessage.fromMap(Map<dynamic, dynamic>.from(item)))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> addMessage(ChatMessage message) async {
    final messages = await readMessages(message.chatId);
    messages.add(message);
    final box = await _openBox();
    await box.put(message.chatId, messages.map((e) => e.toMap()).toList());
  }
}
