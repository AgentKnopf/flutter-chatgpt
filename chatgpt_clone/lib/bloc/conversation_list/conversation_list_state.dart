part of 'conversation_list_bloc.dart';

enum ConversationListStatus { initial, loading, success, failure }

class ConversationListState extends Equatable {
  final List<Conversation> conversations;
  final ConversationListStatus status;
  final String? errorMessage;
  final String? selectedConversationIdOnCreation; // To navigate after creation

  const ConversationListState({
    this.conversations = const [],
    this.status = ConversationListStatus.initial,
    this.errorMessage,
    this.selectedConversationIdOnCreation,
  });

  ConversationListState copyWith({
    List<Conversation>? conversations,
    ConversationListStatus? status,
    String? errorMessage,
    String? selectedConversationIdOnCreation,
    bool clearSelectedConversationId = false, // Flag to nullify selectedConversationIdOnCreation
  }) {
    return ConversationListState(
      conversations: conversations ?? this.conversations,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedConversationIdOnCreation: clearSelectedConversationId ? null : selectedConversationIdOnCreation ?? this.selectedConversationIdOnCreation,
    );
  }

  @override
  List<Object?> get props => [conversations, status, errorMessage, selectedConversationIdOnCreation];
}
