import 'package:flutter/material.dart';
// import '../../core/services/auth_service.dart'; // Will be used later with BLoC

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
      // Simulate a call to auth service.
      // In a real app, this would involve state management (BLoC) to handle UI updates.
      // For now, just print to console.
      print('Attempting login with API Key: $apiKey');
      // UserModel? user = await _authService.signInWithOpenAI(apiKey);
      // if (user != null) {
      //   print('Login successful: ${user.email}');
      //   // TODO: Navigate to ChatScreen or Home Screen
      //   // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ChatScreen()));
      // } else {
      //   print('Login failed');
      //   // TODO: Show error message
      // }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conceptual login with API Key: $apiKey. Check console.'))
      );
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
