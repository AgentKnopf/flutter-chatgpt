import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/conversation_model.dart';
import '../models/chat_message_model.dart';
import 'dart:async'; // For FutureOr

class DatabaseHelper {
  static const _databaseName = "FlutterGPT.db"; // Changed from chatgpt_clone
  static const _databaseVersion = 1;

  static const tableConversations = 'conversations';
  static const tableMessages = 'messages';

  // Conversation table columns
  static const colId = 'id';
  static const colTitle = 'title';
  static const colCreatedAt = 'createdAt';
  static const colUpdatedAt = 'updatedAt';

  // Message table columns
  // colId is shared
  static const colConversationId = 'conversationId';
  static const colText = 'text';
  static const colSender = 'sender';
  static const colTimestamp = 'timestamp';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableConversations (
        $colId TEXT PRIMARY KEY,
        $colTitle TEXT NOT NULL,
        $colCreatedAt TEXT NOT NULL,
        $colUpdatedAt TEXT NOT NULL
      )
      ''');

    await db.execute('''
      CREATE TABLE $tableMessages (
        $colId TEXT PRIMARY KEY,
        $colConversationId TEXT NOT NULL,
        $colText TEXT NOT NULL,
        $colSender TEXT NOT NULL,
        $colTimestamp TEXT NOT NULL,
        FOREIGN KEY ($colConversationId) REFERENCES $tableConversations ($colId) ON DELETE CASCADE
      )
      ''');
  }

  // --- Conversation CRUD Methods ---

  Future<int> insertConversation(Conversation conversation) async {
    Database db = await instance.database;
    return await db.insert(tableConversations, conversation.toMap());
  }

  Future<List<Conversation>> getAllConversations() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(tableConversations, orderBy: '$colUpdatedAt DESC');
    return List.generate(maps.length, (i) {
      return Conversation.fromMap(maps[i]);
    });
  }

  Future<Conversation?> getConversation(String id) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableConversations,
      where: '$colId = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Conversation.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateConversation(Conversation conversation) async {
    Database db = await instance.database;
    return await db.update(
      tableConversations,
      conversation.toMap(),
      where: '$colId = ?',
      whereArgs: [conversation.id],
    );
  }

  Future<int> deleteConversation(String id) async {
    Database db = await instance.database;
    // Messages associated with this conversation will be deleted automatically
    // due to ON DELETE CASCADE in the foreign key constraint.
    return await db.delete(
      tableConversations,
      where: '$colId = ?',
      whereArgs: [id],
    );
  }

  // --- Message CRUD Methods ---

  Future<int> insertMessage(ChatMessageModel message) async {
    Database db = await instance.database;
    // Ensure conversation's updatedAt is touched when a new message is added
    await db.rawUpdate(
      "UPDATE $tableConversations SET $colUpdatedAt = ? WHERE $colId = ?",
      [DateTime.now().toIso8601String(), message.conversationId]
    );
    return await db.insert(tableMessages, message.toMap());
  }

  Future<List<ChatMessageModel>> getMessagesForConversation(String conversationId, {int limit = 50, int offset = 0}) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableMessages,
      where: '$colConversationId = ?',
      whereArgs: [conversationId],
      orderBy: '$colTimestamp ASC', // Typically messages are ordered chronologically
      limit: limit,
      offset: offset,
    );
    return List.generate(maps.length, (i) {
      return ChatMessageModel.fromMap(maps[i]);
    });
  }
  
  Future<int> deleteMessage(String messageId) async {
    Database db = await instance.database;
    return await db.delete(
        tableMessages,
        where: '$colId = ?',
        whereArgs: [messageId],
    );
  }

  // Optional: Update message (e.g., if user can edit their messages)
  Future<int> updateMessage(ChatMessageModel message) async {
    Database db = await instance.database;
    return await db.update(
      tableMessages,
      message.toMap(),
      where: '$colId = ?',
      whereArgs: [message.id],
    );
  }
  
  // Optional: Clear all data (for development/testing or user request)
  Future<void> clearAllData() async {
    Database db = await instance.database;
    await db.delete(tableMessages);
    await db.delete(tableConversations);
  }
}
