part of 'conversation_list_bloc.dart';

abstract class ConversationListEvent extends Equatable {
  const ConversationListEvent();

  @override
  List<Object> get props => [];
}

class LoadConversations extends ConversationListEvent {}

class AddConversation extends ConversationListEvent {
  final String title; // Or perhaps it's auto-generated initially
  const AddConversation({required this.title});

  @override
  List<Object> get props => [title];
}

class CreateNewConversationAndSelect extends ConversationListEvent {
  final String? initialMessage; // Optional first message to seed the conversation title
  const CreateNewConversationAndSelect({this.initialMessage});

  @override
  List<Object> get props => [initialMessage ?? ''];
}

class DeleteConversation extends ConversationListEvent {
  final String conversationId;
  const DeleteConversation({required this.conversationId});

  @override
  List<Object> get props => [conversationId];
}

class UpdateConversationTitle extends ConversationListEvent {
  final String conversationId;
  final String newTitle;
  const UpdateConversationTitle({required this.conversationId, required this.newTitle});

  @override
  List<Object> get props => [conversationId, newTitle];
}
