// In chatgpt_clone/lib/presentation/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/chat/chat_bloc.dart';
import '../../core/models/chat_message_model.dart'; 
import '../widgets/message_bubble.dart';
import '../widgets/message_input_field.dart';
import '../../core/models/conversation_model.dart';

class ChatScreen extends StatelessWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) {
    final chatBloc = BlocProvider.of<ChatBloc>(context);
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
                // ... listener logic ...
                 if (state.status == ChatStatus.error && state.errorMessage != null) {
                  // This is if we want a Snackbar for errors in addition to them appearing in chat.
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
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final message = state.messages[index];
                    final isLastMessage = index == state.messages.length - 1;
                    // Condition from the prompt
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
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              bool isSending = state.status == ChatStatus.sendingMessage;
              return MessageInputField(
                onSendMessage: (text) {
                  if (!isSending) {
                    context.read<ChatBloc>().add(SendMessage(text: text));
                  }
                },
              );
            }
          ),
        ],
      ),
    );
  }
}
