// Replaces the temporary ChatMessage in chat_screen.dart
enum MessageSender { user, ai, system } // Ensure this enum is here or imported

class ChatMessageModel {
  final String id; // Unique ID for the message
  final String conversationId; // Foreign key to Conversation
  final String text;
  final MessageSender sender;
  final DateTime timestamp;

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.text,
    required this.sender,
    required this.timestamp,
  });

  // For sending to API (remains the same)
  Map<String, dynamic> toApiJson() {
    String role;
    switch (sender) {
      case MessageSender.user:
        role = 'user';
        break;
      case MessageSender.ai:
        role = 'assistant';
        break;
      case MessageSender.system:
        role = 'system';
        break;
    }
    return {'role': role, 'content': text};
  }

  // For database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'text': text,
      'sender': sender.name, // Store enum as string
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id'],
      conversationId: map['conversationId'],
      text: map['text'],
      sender: MessageSender.values.byName(map['sender']), // Retrieve enum from string
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
