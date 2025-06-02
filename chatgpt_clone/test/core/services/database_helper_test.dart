// In chatgpt_clone/test/core/services/database_helper_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:chatgpt_clone/core/services/database_helper.dart'; // Adjust path as needed
import 'package:chatgpt_clone/core/models/conversation_model.dart';
import 'package:chatgpt_clone/core/models/chat_message_model.dart';
import 'package:uuid/uuid.dart';

void main() {
  // Initialize FFI
  sqfliteFfiInit();
  
  // Use an in-memory database for testing
  databaseFactory = databaseFactoryFfi;

  late DatabaseHelper dbHelper;
  final uuid = Uuid();

  setUp(() async {
    // Get a fresh instance for each test to avoid data leakage between tests.
    // This typically means re-creating the DatabaseHelper or ensuring its internal _database is reset.
    // For simplicity, as DatabaseHelper is a singleton, we might need to clear data or use a new DB name per test/group.
    // A common approach for testing singletons that manage a DB is to have a method to close and delete the DB.
    // For this test suite, we'll rely on clearing data or unique conversation IDs per test.
    // A better way for testing would be to make DatabaseHelper not a singleton or allow db name injection.
    dbHelper = DatabaseHelper.instance; 
    
    // Ensure the database is clean before each test
    // This is crucial if the db instance is shared across tests (due to singleton)
    await dbHelper.clearAllData(); 
  });

  tearDownAll(() async {
    // Optional: clean up the database file after all tests if not using in-memory for everything
    // If using `databaseFactoryFfiNoWeb`, it creates files. In-memory is cleaner.
    // await deleteDatabase(await dbHelper.database.then((db) => db.path));
  });

  group('Conversations CRUD', () {
    test('insertConversation and getConversation', () async {
      final convId = uuid.v4();
      final conversation = Conversation(id: convId, title: 'Test Conv', createdAt: DateTime.now(), updatedAt: DateTime.now());
      
      await dbHelper.insertConversation(conversation);
      final retrieved = await dbHelper.getConversation(convId);

      expect(retrieved, isNotNull);
      expect(retrieved!.id, convId);
      expect(retrieved.title, 'Test Conv');
    });

    test('getAllConversations returns conversations in descending order of updatedAt', () async {
      final now = DateTime.now();
      final conv1 = Conversation(id: uuid.v4(), title: 'Conv 1', createdAt: now, updatedAt: now); // older
      final conv2 = Conversation(id: uuid.v4(), title: 'Conv 2', createdAt: now, updatedAt: now.add(const Duration(hours: 1))); // newer
      
      await dbHelper.insertConversation(conv1);
      await dbHelper.insertConversation(conv2);

      final conversations = await dbHelper.getAllConversations();
      expect(conversations.length, 2);
      expect(conversations[0].id, conv2.id); // conv2 should be first (newer)
      expect(conversations[1].id, conv1.id);
    });

    test('updateConversation updates title and updatedAt', () async {
      final convId = uuid.v4();
      final originalTime = DateTime.now().subtract(const Duration(minutes: 10));
      final conversation = Conversation(id: convId, title: 'Original Title', createdAt: originalTime, updatedAt: originalTime);
      await dbHelper.insertConversation(conversation);

      final newTitle = 'Updated Title';
      final newUpdateTime = DateTime.now();
      // Create a new conversation instance for update to mimic how it might be handled in app
      final updatedConversationData = Conversation(
        id: convId,
        title: newTitle,
        createdAt: originalTime, // createdAt should not change
        updatedAt: newUpdateTime,
      );
      
      await dbHelper.updateConversation(updatedConversationData);
      final retrieved = await dbHelper.getConversation(convId);

      expect(retrieved, isNotNull);
      expect(retrieved!.title, newTitle);
      // Compare milliseconds since epoch for DateTime because object identity might differ
      expect(retrieved.updatedAt.millisecondsSinceEpoch, newUpdateTime.millisecondsSinceEpoch);
    });

    test('deleteConversation removes the conversation', () async {
      final convId = uuid.v4();
      final conversation = Conversation(id: convId, title: 'To Delete', createdAt: DateTime.now(), updatedAt: DateTime.now());
      await dbHelper.insertConversation(conversation);

      var retrieved = await dbHelper.getConversation(convId);
      expect(retrieved, isNotNull);

      await dbHelper.deleteConversation(convId);
      retrieved = await dbHelper.getConversation(convId);
      expect(retrieved, isNull);
    });
  });

  group('Messages CRUD and Cascade Delete', () {
    late String testConvId;

    setUp(() async {
      testConvId = uuid.v4();
      final conversation = Conversation(id: testConvId, title: 'Messages Test', createdAt: DateTime.now(), updatedAt: DateTime.now());
      await dbHelper.insertConversation(conversation);
    });

    test('insertMessage and getMessagesForConversation', () async {
      final msg1 = ChatMessageModel(id: uuid.v4(), conversationId: testConvId, text: 'Msg 1', sender: MessageSender.user, timestamp: DateTime.now());
      final msg2 = ChatMessageModel(id: uuid.v4(), conversationId: testConvId, text: 'Msg 2', sender: MessageSender.ai, timestamp: DateTime.now().add(const Duration(seconds: 1)));
      
      await dbHelper.insertMessage(msg1);
      await dbHelper.insertMessage(msg2);

      final messages = await dbHelper.getMessagesForConversation(testConvId);
      expect(messages.length, 2);
      expect(messages[0].text, 'Msg 1');
      expect(messages[1].text, 'Msg 2');
    });

    test('insertMessage updates parent conversation updatedAt timestamp', () async {
      final conversation = await dbHelper.getConversation(testConvId);
      final originalUpdatedAt = conversation!.updatedAt;
      
      await Future.delayed(const Duration(milliseconds: 50)); // Ensure time difference

      final newMessage = ChatMessageModel(id: uuid.v4(), conversationId: testConvId, text: 'New message', sender: MessageSender.user, timestamp: DateTime.now());
      await dbHelper.insertMessage(newMessage);

      final updatedConversation = await dbHelper.getConversation(testConvId);
      expect(updatedConversation!.updatedAt.isAfter(originalUpdatedAt), isTrue);
    });
    
    test('deleteMessage removes a specific message', () async {
      final msgIdToDelete = uuid.v4();
      final msg1 = ChatMessageModel(id: msgIdToDelete, conversationId: testConvId, text: 'To delete', sender: MessageSender.user, timestamp: DateTime.now());
      final msg2 = ChatMessageModel(id: uuid.v4(), conversationId: testConvId, text: 'To keep', sender: MessageSender.ai, timestamp: DateTime.now().add(const Duration(seconds: 1)));
      await dbHelper.insertMessage(msg1);
      await dbHelper.insertMessage(msg2);

      await dbHelper.deleteMessage(msgIdToDelete);
      final messages = await dbHelper.getMessagesForConversation(testConvId);
      expect(messages.length, 1);
      expect(messages.first.id, msg2.id);
    });

    test('updateMessage updates existing message', () async {
      final msgId = uuid.v4();
      final originalText = "Original text";
      final updatedText = "Updated text";
      final message = ChatMessageModel(id: msgId, conversationId: testConvId, text: originalText, sender: MessageSender.user, timestamp: DateTime.now());
      await dbHelper.insertMessage(message);

      // Create a new instance for update, ensuring all fields are correctly set
      final messageToUpdate = ChatMessageModel(id: msgId, conversationId: testConvId, text: updatedText, sender: MessageSender.user, timestamp: message.timestamp);
      await dbHelper.updateMessage(messageToUpdate);

      final messages = await dbHelper.getMessagesForConversation(testConvId);
      expect(messages.length, 1);
      expect(messages.first.text, updatedText);
    });

    test('deleting a conversation also deletes its messages (ON DELETE CASCADE)', () async {
      final msg1 = ChatMessageModel(id: uuid.v4(), conversationId: testConvId, text: 'Msg A', sender: MessageSender.user, timestamp: DateTime.now());
      await dbHelper.insertMessage(msg1);

      var messages = await dbHelper.getMessagesForConversation(testConvId);
      expect(messages.length, 1);

      await dbHelper.deleteConversation(testConvId);
      messages = await dbHelper.getMessagesForConversation(testConvId);
      expect(messages.isEmpty, isTrue);
    });
  });

  test('clearAllData removes all conversations and messages', () async {
      final convId1 = uuid.v4();
      final conv1 = Conversation(id: convId1, title: 'Conv 1', createdAt: DateTime.now(), updatedAt: DateTime.now());
      await dbHelper.insertConversation(conv1);
      final msg1 = ChatMessageModel(id: uuid.v4(), conversationId: convId1, text: 'Msg for Conv 1', sender: MessageSender.user, timestamp: DateTime.now());
      await dbHelper.insertMessage(msg1);

      final convId2 = uuid.v4();
      final conv2 = Conversation(id: convId2, title: 'Conv 2', createdAt: DateTime.now(), updatedAt: DateTime.now());
      await dbHelper.insertConversation(conv2);

      await dbHelper.clearAllData();

      final conversations = await dbHelper.getAllConversations();
      final messagesConv1 = await dbHelper.getMessagesForConversation(convId1);
      
      expect(conversations.isEmpty, isTrue);
      expect(messagesConv1.isEmpty, isTrue);
  });
}
