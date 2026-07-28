import 'package:eventa/src/features/chat/data/chat_local_storage.dart';
import 'package:eventa/src/features/chat/domain/entities/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'dart:io';

void main() {
  late Directory dir;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('eventa_chat_test');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('chat stores messages by chatId', () async {
    final storage = ChatLocalStorage();
    final chatId = ChatLocalStorage.chatIdFor(
      meetingId: 'm1',
      userA: 'u2',
      userB: 'u1',
    );
    expect(chatId, 'm1:u1_u2');

    await storage.addMessage(
      ChatMessage(
        id: '1',
        chatId: chatId,
        senderId: 'u1',
        text: 'Привет',
        createdAt: DateTime.now(),
      ),
    );
    final messages = await storage.readMessages(chatId);
    expect(messages, hasLength(1));
    expect(messages.first.text, 'Привет');
  });
}
