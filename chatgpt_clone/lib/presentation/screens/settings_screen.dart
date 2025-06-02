// In chatgpt_clone/lib/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chatgpt_clone/core/services/auth_service.dart';
import 'package:chatgpt_clone/core/services/database_helper.dart';
import 'package:chatgpt_clone/bloc/conversation_list/conversation_list_bloc.dart';
import 'package:chatgpt_clone/presentation/screens/login_screen.dart';
import 'package:chatgpt_clone/core/models/user_model.dart'; // For UserModel

class SettingsScreen extends StatefulWidget { // Changed to StatefulWidget for API key status
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserModel? _currentUser; // To hold API key status

  @override
  void initState() {
    super.initState();
    _loadApiKeyStatus();
  }

  Future<void> _loadApiKeyStatus() async {
    // Access AuthService using RepositoryProvider.of, not context.read in initState if context is not fully available.
    // However, it's generally safer to do this in didChangeDependencies or pass it if needed immediately.
    // For this simple read, doing it here and then calling setState should be fine.
    // listen: false is important in initState if context is used this way.
    final authService = RepositoryProvider.of<AuthService>(context, listen: false);
    _currentUser = await authService.getCurrentUser();
    if (mounted) { // Check if the widget is still in the tree
      setState(() {});
    }
  }

  Future<void> _confirmClearAllData(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear All Chat Data?'),
          content: const Text(
              'Are you sure you want to delete ALL conversations and messages? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear All Data'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true && context.mounted) {
      final dbHelper = RepositoryProvider.of<DatabaseHelper>(context, listen: false); // listen: false for event handlers
      context.read<ConversationListBloc>().add(LoadConversations()); // This might be better after dbHelper.clearAllData()
      await dbHelper.clearAllData();
      // It's often better to reload after the operation is complete.
      // context.read<ConversationListBloc>().add(LoadConversations());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All chat data cleared.')),
      );
       // After clearing data, also refresh API key status in case it was tied to user session conceptually
      _loadApiKeyStatus();
    }
  }

  Future<void> _logout(BuildContext context) async {
    final authService = RepositoryProvider.of<AuthService>(context, listen: false); // listen: false for event handlers
    await authService.signOut();
    
    if (context.mounted) {
      // After signing out, also update API key status locally for immediate UI feedback
      setState(() {
        _currentUser = null;
      });
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'API Key Status:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _currentUser != null && _currentUser!.accessToken.isNotEmpty 
                      ? 'Active (Key is stored)' 
                      : 'Not Set (Login to provide an API Key)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _currentUser != null && _currentUser!.accessToken.isNotEmpty 
                           ? Colors.green
                           : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            subtitle: const Text('Sign out & clear stored API Key.'),
            onTap: () => _logout(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
            title: const Text('Clear All Chat Data', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Deletes all local conversations and messages.'),
            onTap: () => _confirmClearAllData(context),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
