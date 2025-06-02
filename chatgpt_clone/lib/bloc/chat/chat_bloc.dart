import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/chat_message_model.dart';
import '../../core/models/conversation_model.dart';
import '../../core/services/database_helper.dart';
import '../../core/services/openai_api_service.dart';
import '../../core/errors/api_exceptions.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final DatabaseHelper _databaseHelper;
  final OpenAIApiService _apiService;
  final Uuid _uuid = const Uuid();

  ChatBloc({
    required String conversationId, // Each ChatBloc instance is for one conversation
    required DatabaseHelper databaseHelper,
    required OpenAIApiService apiService,
  })  : _databaseHelper = databaseHelper,
        _apiService = apiService,
        super(ChatState(conversationId: conversationId, status: ChatStatus.initial)) {
    on<LoadChat>(_onLoadChat);
    on<SendMessage>(_onSendMessage);
    on<RegenerateResponse>(_onRegenerateResponse);
    on<_ReceiveMessage>(_onReceiveMessage);
    on<_ReportError>(_onReportError);
  }

  Future<void> _onLoadChat(LoadChat event, Emitter<ChatState> emit) async {
    emit(state.copyWith(status: ChatStatus.loadingMessages, clearError: true));
    try {
      final messages = await _databaseHelper.getMessagesForConversation(event.conversationId);
      final conversation = await _databaseHelper.getConversation(event.conversationId);
      emit(state.copyWith(
        messages: messages,
        currentConversation: conversation,
        status: ChatStatus.messagesLoaded,
      ));
    } catch (e) {
      emit(state.copyWith(status: ChatStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    if (event.text.trim().isEmpty) return;

    final userMessage = ChatMessageModel(
      id: _uuid.v4(),
      conversationId: state.conversationId,
      text: event.text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(
      messages: List.from(state.messages)..add(userMessage),
      status: ChatStatus.sendingMessage,
      clearError: true,
    ));

    try {
      await _databaseHelper.insertMessage(userMessage);
      // The OpenAIApiService needs the full history
      final conversationHistory = await _databaseHelper.getMessagesForConversation(state.conversationId);

      final aiResponseModel = await _apiService.sendChatCompletion(conversationHistory);
      add(_ReceiveMessage(message: aiResponseModel)); // Trigger internal event

    } on ApiException catch (e) {
      add(_ReportError(errorMessage: e.toString()));
      // Optionally, mark userMessage as failed or remove it if desired
    } catch (e) {
      add(_ReportError(errorMessage: 'An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<void> _onRegenerateResponse(RegenerateResponse event, Emitter<ChatState> emit) async {
    emit(state.copyWith(status: ChatStatus.sendingMessage, clearError: true));
    try {
      // Get messages, remove last AI response if it exists and was an error or normal response
      var history = List<ChatMessageModel>.from(state.messages);
      if (history.isNotEmpty && (history.last.sender == MessageSender.ai || history.last.sender == MessageSender.system)) {
        // For now, just remove the last message if it's AI/System.
        // More sophisticated logic might be needed for specific error messages.
        history.removeLast();
      }
      // Ensure we don't send an empty history if the only message was an AI one we removed.
      if (history.isEmpty) {
        emit(state.copyWith(status: ChatStatus.messagesLoaded, errorMessage: "Cannot regenerate from an empty history."));
        return;
      }

      final aiResponseModel = await _apiService.sendChatCompletion(history);
      add(_ReceiveMessage(message: aiResponseModel));

    } on ApiException catch (e) {
      add(_ReportError(errorMessage: e.toString()));
    } catch (e) {
      add(_ReportError(errorMessage: 'An unexpected error occurred while regenerating: ${e.toString()}'));
    }
  }

  Future<void> _onReceiveMessage(_ReceiveMessage event, Emitter<ChatState> emit) async {
     final aiMessage = ChatMessageModel(
        id: event.message.id, // Use ID from API or generate client-side
        conversationId: state.conversationId,
        text: event.message.text,
        sender: MessageSender.ai, // Assuming event.message is from AI
        timestamp: DateTime.now(), // Or use timestamp from API if available
      );
    await _databaseHelper.insertMessage(aiMessage);
    emit(state.copyWith(
      messages: List.from(state.messages)..add(aiMessage),
      status: ChatStatus.messagesLoaded,
    ));
  }

  Future<void> _onReportError(_ReportError event, Emitter<ChatState> emit) async {
    // You could also add the error as a system message to the chat list
    final errorMessage = ChatMessageModel(
      id: _uuid.v4(),
      conversationId: state.conversationId,
      text: event.errorMessage,
      sender: MessageSender.system,
      timestamp: DateTime.now(),
    );
    await _databaseHelper.insertMessage(errorMessage); // Persist error message in chat
    emit(state.copyWith(
      status: ChatStatus.error,
      errorMessage: event.errorMessage,
      messages: List.from(state.messages)..add(errorMessage)
    ));
  }
}
