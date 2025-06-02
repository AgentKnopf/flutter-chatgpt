// In chatgpt_clone/lib/presentation/screens/conversations_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/conversation_list/conversation_list_bloc.dart';
import '../../core/models/conversation_model.dart';
import 'chat_screen.dart'; // To navigate to ChatScreen
import 'settings_screen.dart'; // Import SettingsScreen
import '../../bloc/chat/chat_bloc.dart'; // For ChatBloc provision
import '../../core/services/openai_api_service.dart'; 
import '../../core/services/database_helper.dart';   
import '../../core/services/auth_service.dart'; 


class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    // Initial load is now handled by BlocProvider in main.dart
    // context.read<ConversationListBloc>().add(LoadConversations());
  }

  void _navigateToChat(BuildContext context, String conversationId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider<ChatBloc>(
          create: (context) => ChatBloc(
            conversationId: conversationId,
            databaseHelper: RepositoryProvider.of<DatabaseHelper>(context), 
            apiService: RepositoryProvider.of<OpenAIApiService>(context),
          )..add(LoadChat(conversationId: conversationId)),
          child: ChatScreen(conversationId: conversationId),
        ),
      ),
    ).then((_) {
      context.read<ConversationListBloc>().add(LoadConversations());
    });
  }

  Future<void> _showRenameDialog(BuildContext context, Conversation conversation) async {
    final TextEditingController titleController = TextEditingController(text: conversation.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Rename Conversation'),
          content: TextField(
            controller: titleController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter new title'),
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value.trim()),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Rename'),
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  Navigator.of(dialogContext).pop(titleController.text.trim());
                }
                // Optionally, show a small error if the title is empty, or disable Rename button.
              },
            ),
          ],
        );
      },
    );

    if (newTitle != null && newTitle.isNotEmpty && newTitle != conversation.title) {
      // Use context.read here as it's in response to an event, not during build
      context.read<ConversationListBloc>().add(
        UpdateConversationTitle(conversationId: conversation.id, newTitle: newTitle)
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('flutter_gpt Conversations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined), // Changed icon
            tooltip: 'Settings', // Added tooltip
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          )
        ],
      ),
      body: BlocConsumer<ConversationListBloc, ConversationListState>(
        listener: (context, state) {
          if (state.status == ConversationListStatus.failure && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.errorMessage}')),
            );
          } else if (state.status == ConversationListStatus.success && state.selectedConversationIdOnCreation != null) {
            _navigateToChat(context, state.selectedConversationIdOnCreation!);
            context.read<ConversationListBloc>().emit(state.copyWith(clearSelectedConversationId: true));
          }
        },
        builder: (context, state) {
          // ... (loading, error, empty states remain the same) ...
          if (state.status == ConversationListStatus.loading && state.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == ConversationListStatus.failure && state.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error loading conversations: ${state.errorMessage ?? "Unknown error"}'), // Added null check
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min, // Important for Row within ListTile trailing
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                      tooltip: 'Rename Conversation',
                      onPressed: () => _showRenameDialog(context, conversation),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      tooltip: 'Delete Conversation',
                      onPressed: () => _confirmDeleteConversation(context, conversation),
                    ),
                  ],
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
}
