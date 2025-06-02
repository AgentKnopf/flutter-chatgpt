import 'dart:developer' as developer;

import 'package:chatgpt_clone/core/models/chat_message_model.dart';
import 'package:chatgpt_clone/core/models/conversation_model.dart';
import 'package:chatgpt_clone/core/services/database_helper.dart';
import 'package:sqflite_common/sqlite_api.dart';

class InMemoryDatabaseHelper implements DatabaseHelper {
  final Map<String, List<ChatMessageModel>> _messages = {};

  @override
  Future<void> saveMessage(
      String conversationId, ChatMessageModel message) async {
    developer.log('saveMessage called with id: $conversationId');
    _messages.putIfAbsent(conversationId, () => []).add(message);
    return Future.value(1);
  }

  @override
  Future<List<ChatMessageModel>> getMessages(String conversationId) async {
    developer.log('deleteConversation called with id: $conversationId');
    return _messages[conversationId] ?? [];
  }

  @override
  Future<int> deleteConversation(String id) {
    developer.log('deleteConversation called with id: $id');
    //Simulate successful deletion
    return Future.value(1);
  }

  @override
  Future<void> clearAllData() {
    developer.log('clearAllData called');
    //Simulate successful deletion
    return Future.value(1);
  }

  @override
  Future<Database> get database => throw UnimplementedError();

  @override
  Future<int> deleteMessage(String messageId) {
    developer.log('deleteMessage called with id: $messageId');
    //Simulate successful deletion
    return Future.value(1);
  }

  @override
  Future<List<Conversation>> getAllConversations() {
    // TODO: implement getAllConversations
    throw UnimplementedError();
  }

  @override
  Future<Conversation?> getConversation(String id) {
    // TODO: implement getConversation
    throw UnimplementedError();
  }

  @override
  Future<List<ChatMessageModel>> getMessagesForConversation(
      String conversationId,
      {int limit = 50,
      int offset = 0}) {
    // TODO: implement getMessagesForConversation
    throw UnimplementedError();
  }

  @override
  Future<int> insertConversation(Conversation conversation) {
    // TODO: implement insertConversation
    throw UnimplementedError();
  }

  @override
  Future<int> insertMessage(ChatMessageModel message) {
    // TODO: implement insertMessage
    throw UnimplementedError();
  }

  @override
  Future<int> updateConversation(Conversation conversation) {
    // TODO: implement updateConversation
    throw UnimplementedError();
  }

  @override
  Future<int> updateMessage(ChatMessageModel message) {
    // TODO: implement updateMessage
    throw UnimplementedError();
  }
}
