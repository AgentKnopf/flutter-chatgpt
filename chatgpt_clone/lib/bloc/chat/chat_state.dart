part of 'chat_bloc.dart';

enum ChatStatus { initial, loadingMessages, messagesLoaded, sendingMessage, receivingResponse, error }

class ChatState extends Equatable {
  final String conversationId;
  final List<ChatMessageModel> messages;
  final ChatStatus status;
  final String? errorMessage;
  final Conversation? currentConversation; // Optional: for displaying title etc.

  const ChatState({
    required this.conversationId,
    this.messages = const [],
    this.status = ChatStatus.initial,
    this.errorMessage,
    this.currentConversation,
  });

  ChatState copyWith({
    // conversationId typically doesn't change for an instance of ChatBloc
    List<ChatMessageModel>? messages,
    ChatStatus? status,
    String? errorMessage,
    Conversation? currentConversation,
    bool clearError = false, // Flag to nullify error message
  }) {
    return ChatState(
      conversationId: conversationId,
      messages: messages ?? this.messages,
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      currentConversation: currentConversation ?? this.currentConversation,
    );
  }

  @override
  List<Object?> get props => [conversationId, messages, status, errorMessage, currentConversation];
}
