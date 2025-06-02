import 'package:flutter/material.dart';
import 'package:chatgpt_clone/core/services/auth_service.dart';
import 'package:chatgpt_clone/core/models/user_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chatgpt_clone/presentation/screens/conversations_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _apiKeyController = TextEditingController();
  // final _authService = AuthService(); // Instance for direct use, later via BLoC

  void _login() async {
    // **CONCEPTUAL LOGIN / API KEY SUBMISSION **
    // In a real app, this would trigger the OAuth flow.
    // Here, we'll just simulate checking an API key for simplicity.
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isNotEmpty) {
      // ** CLARIFICATION FOR USER / DEVELOPER **
      // The AuthService.signInWithOpenAI method with an API key is designed to:
      // 1. Store this API key securely using shared_preferences.
      // 2. This stored API key will then be retrieved by OpenAIApiService 
      //    and used as the Bearer token for actual API calls to OpenAI.
      // This is NOT an OAuth flow, but direct API key authentication.
      // The "conceptual" part previously mentioned by the AI assistant refers to
      // its inability to *test* these live calls in its sandboxed environment,
      // not that the mechanism itself is non-functional.
      // If you provide a valid OpenAI API key here, the app WILL attempt to use it.
      
      // The following lines simulate the service call and navigation for UI flow.
      // In a fully integrated app, this would be handled by an AuthBloc.
      print('Attempting to store API Key and simulate login with: $apiKey');
      final authService = RepositoryProvider.of<AuthService>(context, listen: false);
      UserModel? user = await authService.signInWithOpenAI(apiKey);
      // Simulate navigation or state update based on user
      if (user != null && context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API Key stored. Navigating to conversations... User: ${user.email}'))
        );
        // Navigate to ConversationsScreen after successful "login"
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ConversationsScreen()) // Assuming ConversationsScreen exists
        );
      } else if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to store API Key or simulate login.'))
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an API Key to simulate login.'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login to OpenAI')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'This is a conceptual login screen. '
              'In a real app, this would use OpenAI OAuth.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'Enter your OpenAI API Key (for simulation)',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Simulate Login / Continue'),
            ),
            const SizedBox(height: 10),
            const Text(
              'Note: No actual authentication is performed with OpenAI. '
              'This is a placeholder for the UI and service structure.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
}
