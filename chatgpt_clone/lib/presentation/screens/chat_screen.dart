// In chatgpt_clone/lib/presentation/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/chat/chat_bloc.dart';
import '../../core/models/chat_message_model.dart'; 
import '../widgets/message_bubble.dart';
import '../widgets/message_input_field.dart';
// Services will be injected into ChatBloc, not directly used here
// import '../../core/services/openai_api_service.dart';
// import '../../core/services/auth_service.dart';
// import '../../core/services/database_helper.dart';
import '../../core/models/conversation_model.dart'; // For Conversation type in ChatState

class ChatScreen extends StatelessWidget { // Changed to StatelessWidget
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) {
    // ChatBloc is expected to be provided above this widget in the tree,
    // typically via BlocProvider in the route generation or parent widget.
    // For now, we are dispatching LoadChat in initState of ConversationsScreen's navigation.
    // A better way is to ensure ChatBloc is provided and LoadChat is called upon Bloc creation or screen init.
    // context.read<ChatBloc>().add(LoadChat(conversationId: conversationId)); // This might be too late if not already provided

    final chatBloc = BlocProvider.of<ChatBloc>(context);
    // Ensure LoadChat is called if not already loaded or if conversationId changed
    // This is a common pattern if Bloc is scoped to this screen.
    if (chatBloc.state.conversationId != conversationId || chatBloc.state.status == ChatStatus.initial) {
        chatBloc.add(LoadChat(conversationId: conversationId));
    }

    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            return Text(state.currentConversation?.title ?? 'Chat');
          },
        ),
        // Removed general refresh icon from AppBar
        actions: [
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              // Keep loading indicator in AppBar for sendingMessage status
              if (state.status == ChatStatus.sendingMessage || state.status == ChatStatus.loadingMessages) {
                return const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: SizedBox(
                    width: 24, height: 24, 
                    child: CircularProgressIndicator(strokeWidth: 2.0)
                  )
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                // Optional: Show snackbar for errors if not displayed inline
                if (state.status == ChatStatus.error && state.errorMessage != null) {
                  // Error messages are now part of the chat list as system messages
                  // So, a snackbar might be redundant or for different kinds of errors.
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   SnackBar(content: Text('Error: ${state.errorMessage}')),
                  // );
                }
              },
              builder: (context, state) {
                if (state.status == ChatStatus.loadingMessages && state.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.messages.isEmpty && state.status != ChatStatus.loadingMessages) {
                  return const Center(child: Text('No messages yet. Send one to start!'));
                }

                return ListView.builder(
                  // Consider a ScrollController if you need to manage scrolling from BLoC
                  // For auto-scrolling, it might need to be managed within this widget
                  // or via events from BLoC if complex.
                  // controller: _scrollController, // Re-add if needed
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final message = state.messages[index];
                    final isLastMessage = index == state.messages.length - 1;
                    // Condition for showing regenerate button
                    final bool canRegenerate = isLastMessage && 
                                               (message.sender == MessageSender.ai || message.sender == MessageSender.system) && 
                                               state.status != ChatStatus.sendingMessage; 

                    return MessageBubble(
                      key: ValueKey(message.id),
                      text: message.text,
                      sender: message.sender == MessageSender.user
                          ? MessageBubbleSender.user
                          : MessageBubbleSender.ai, // System messages also appear as AI for bubble style
                      showRegenerateButton: canRegenerate,
                      onRegenerate: canRegenerate 
                        ? () => context.read<ChatBloc>().add(const RegenerateResponse()) 
                        : null,
                    );
                  },
                );
              },
            ),
          ),
          BlocBuilder<ChatBloc, ChatState>( // To disable input field while sending
            builder: (context, state) {
              bool isSending = state.status == ChatStatus.sendingMessage;
              return MessageInputField(
                onSendMessage: (text) {
                  if (!isSending) { // Prevent sending multiple messages if one is in flight
                    context.read<ChatBloc>().add(SendMessage(text: text));
                  }
                },
                // enabled: !isSending, // MessageInputField doesn't have 'enabled'
                                      // but you could wrap it or modify it.
                                      // For now, the check in onSendMessage is key.
              );
            }
          ),
        ],
      ),
    );
  }
}
