import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/conversation_list/conversation_list_bloc.dart';
import '../../core/models/conversation_model.dart';
import 'chat_screen.dart'; // To navigate to ChatScreen
import '../../bloc/chat/chat_bloc.dart'; // Import ChatBloc
import '../../core/services/openai_api_service.dart'; // Needed for ChatBloc
import '../../core/services/database_helper.dart';   // Needed for ChatBloc


class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    // Load conversations when the screen is initialized
    // context.read<ConversationListBloc>().add(LoadConversations()); // Moved to main.dart's BlocProvider create
  }

  void _navigateToChat(BuildContext context, String conversationId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider<ChatBloc>(
          create: (context) => ChatBloc(
            conversationId: conversationId,
            // Assuming these services are available via context.read from a MultiRepositoryProvider in main.dart
            databaseHelper: RepositoryProvider.of<DatabaseHelper>(context), 
            apiService: RepositoryProvider.of<OpenAIApiService>(context),
          )..add(LoadChat(conversationId: conversationId)), // Initial load event
          child: ChatScreen(conversationId: conversationId),
        ),
      ),
    ).then((_) {
      // When returning from ChatScreen, refresh conversations list
      // as a conversation's title or updatedAt might have changed.
      context.read<ConversationListBloc>().add(LoadConversations());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('flutter_gpt Conversations'), // Updated app name
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("App Info / Settings Placeholder"))
              );
            },
          )
        ],
      ),
      body: BlocConsumer<ConversationListBloc, ConversationListState>(
        listener: (context, state) {
          if (state.status == ConversationListStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.errorMessage}')),
            );
          } else if (state.status == ConversationListStatus.success && state.selectedConversationIdOnCreation != null) {
            _navigateToChat(context, state.selectedConversationIdOnCreation!);
            context.read<ConversationListBloc>().emit(state.copyWith(clearSelectedConversationId: true));
          }
        },
        builder: (context, state) {
          if (state.status == ConversationListStatus.loading && state.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == ConversationListStatus.failure && state.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error loading conversations: ${state.errorMessage}'),
                  ElevatedButton(
                    onPressed: () => context.read<ConversationListBloc>().add(LoadConversations()),
                    child: const Text('Retry'),
                  )
                ],
              ),
            );
          }
          if (state.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No conversations yet.'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                       context.read<ConversationListBloc>().add(const CreateNewConversationAndSelect());
                    },
                    child: const Text('Start New Chat'),
                  )
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: state.conversations.length,
            itemBuilder: (context, index) {
              final conversation = state.conversations[index];
              return ListTile(
                title: Text(conversation.title),
                subtitle: Text('Updated: ${conversation.updatedAt.toLocal().toString().substring(0, 16)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _confirmDeleteConversation(context, conversation),
                ),
                onTap: () => _navigateToChat(context, conversation.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<ConversationListBloc>().add(const CreateNewConversationAndSelect());
        },
        tooltip: 'New Chat',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDeleteConversation(BuildContext context, Conversation conversation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Conversation?'),
          content: Text('Are you sure you want to delete "${conversation.title}"? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      context.read<ConversationListBloc>().add(DeleteConversation(conversationId: conversation.id));
    }
  }
}
