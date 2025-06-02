import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/conversation_model.dart';
import '../../core/services/database_helper.dart';

part 'conversation_list_event.dart';
part 'conversation_list_state.dart';

class ConversationListBloc extends Bloc<ConversationListEvent, ConversationListState> {
  final DatabaseHelper _databaseHelper;
  final Uuid _uuid = const Uuid();

  ConversationListBloc({required DatabaseHelper databaseHelper})
      : _databaseHelper = databaseHelper,
        super(const ConversationListState()) {
    on<LoadConversations>(_onLoadConversations);
    on<AddConversation>(_onAddConversation);
    on<DeleteConversation>(_onDeleteConversation);
    on<UpdateConversationTitle>(_onUpdateConversationTitle);
    on<CreateNewConversationAndSelect>(_onCreateNewConversationAndSelect);
  }

  Future<void> _onLoadConversations(
      LoadConversations event, Emitter<ConversationListState> emit) async {
    emit(state.copyWith(status: ConversationListStatus.loading));
    try {
      final conversations = await _databaseHelper.getAllConversations();
      emit(state.copyWith(
          status: ConversationListStatus.success, conversations: conversations));
    } catch (e) {
      emit(state.copyWith(
          status: ConversationListStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onAddConversation(
      AddConversation event, Emitter<ConversationListState> emit) async {
    // This event might be deprecated in favor of CreateNewConversationAndSelect
    // Or used for system-created conversations if needed.
    emit(state.copyWith(status: ConversationListStatus.loading));
    try {
      final newConversation = Conversation(
        id: _uuid.v4(),
        title: event.title,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _databaseHelper.insertConversation(newConversation);
      // Reload all conversations to reflect the new one
      add(LoadConversations());
    } catch (e) {
      emit(state.copyWith(
          status: ConversationListStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onCreateNewConversationAndSelect(
    CreateNewConversationAndSelect event, Emitter<ConversationListState> emit) async {
    emit(state.copyWith(status: ConversationListStatus.loading, clearSelectedConversationId: true));
    try {
      final newConversationId = _uuid.v4();
      // Simple title generation for now, can be more sophisticated
      final title = event.initialMessage != null && event.initialMessage!.isNotEmpty
          ? (event.initialMessage!.length > 30 ? event.initialMessage!.substring(0, 30) : event.initialMessage!) + '...'
          : 'New Chat';

      final newConversation = Conversation(
        id: newConversationId,
        title: title,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _databaseHelper.insertConversation(newConversation);

      final conversations = await _databaseHelper.getAllConversations();
      emit(state.copyWith(
        status: ConversationListStatus.success,
        conversations: conversations,
        selectedConversationIdOnCreation: newConversationId, // Signal UI to navigate
      ));
    } catch (e) {
      emit(state.copyWith(
          status: ConversationListStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleteConversation(
      DeleteConversation event, Emitter<ConversationListState> emit) async {
    emit(state.copyWith(status: ConversationListStatus.loading));
    try {
      await _databaseHelper.deleteConversation(event.conversationId);
      // Reload all conversations
      add(LoadConversations());
    } catch (e) {
      emit(state.copyWith(
          status: ConversationListStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdateConversationTitle(
      UpdateConversationTitle event, Emitter<ConversationListState> emit) async {
    // No loading state change, happens in background
    try {
      final conversation = await _databaseHelper.getConversation(event.conversationId);
      if (conversation != null) {
        conversation.title = event.newTitle;
        conversation.updatedAt = DateTime.now();
        await _databaseHelper.updateConversation(conversation);
        // Reload all conversations to reflect the change
        add(LoadConversations());
      } else {
        // Handle case where conversation to update is not found
         emit(state.copyWith(
          status: ConversationListStatus.failure, errorMessage: "Conversation not found for update."));
      }
    } catch (e) {
       emit(state.copyWith(
          status: ConversationListStatus.failure, errorMessage: e.toString()));
    }
  }
}
