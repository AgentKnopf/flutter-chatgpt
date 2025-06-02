import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chatgpt_clone/core/services/auth_service.dart';
import 'package:chatgpt_clone/core/services/database_helper.dart';
import 'package:chatgpt_clone/bloc/conversation_list/conversation_list_bloc.dart';
// Assuming LoginScreen is the route name or you have a direct way to navigate
import 'package:chatgpt_clone/presentation/screens/login_screen.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
      final dbHelper = RepositoryProvider.of<DatabaseHelper>(context);
      await dbHelper.clearAllData();
      // Notify ConversationListBloc to refresh
      context.read<ConversationListBloc>().add(LoadConversations());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All chat data cleared.')),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    final authService = RepositoryProvider.of<AuthService>(context);
    await authService.signOut();

    // After signing out, navigate to LoginScreen and remove all previous routes.
    // This is a simple way to reset the app state for now.
    // A more robust solution might involve an AuthBloc that MyApp listens to.
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false, // Remove all routes
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
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            subtitle: const Text('Sign out from your account.'),
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
          // Placeholder for other settings
          // ListTile(
          //   leading: const Icon(Icons.info_outline),
          //   title: const Text('About flutter_gpt'),
          //   onTap: () {
          //     // Show app version, etc.
          //   },
          // ),
        ],
      ),
    );
  }
}
