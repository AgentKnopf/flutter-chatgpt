part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadChat extends ChatEvent {
  final String conversationId;
  const LoadChat({required this.conversationId});

  @override
  List<Object> get props => [conversationId];
}

class SendMessage extends ChatEvent {
  final String text;
  // conversationId will be part of ChatBloc's internal state or constructor
  const SendMessage({required this.text});

  @override
  List<Object> get props => [text];
}

class RegenerateResponse extends ChatEvent {
  // Requires access to the last few messages, ChatBloc will handle this
  const RegenerateResponse();
}

// Internal event to update UI after AI response
class _ReceiveMessage extends ChatEvent {
  final ChatMessageModel message;
  const _ReceiveMessage({required this.message});

  @override
  List<Object> get props => [message];
}

// Internal event to report error
class _ReportError extends ChatEvent {
  final String errorMessage;
  const _ReportError({required this.errorMessage});
  @override
  List<Object> get props => [errorMessage];
}
