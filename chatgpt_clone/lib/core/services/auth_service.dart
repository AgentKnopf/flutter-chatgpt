import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

// Conceptual Authentication Service
class AuthService {
  static const String _accessTokenKey = 'openai_access_token';
  static const String _userIdKey = 'openai_user_id';
  static const String _userEmailKey = 'openai_user_email';

  // Simulate logging in with OpenAI (OAuth flow would happen here)
  // In a real app, this would involve webviews or platform-specific libraries
  Future<UserModel?> signInWithOpenAI(String apiKey) async {
    // ** CLARIFICATION FOR USER / DEVELOPER **
    // This method simulates a "sign-in" by directly accepting an OpenAI API key.
    // 1. It stores the provided API key in shared_preferences.
    // 2. The OpenAIApiService will later retrieve this key to make authenticated
    //    calls to the OpenAI API.
    // This is a direct API key authentication approach. It does not perform
    // any validation of the key against OpenAI at this stage, only when an
    // actual API call (e.g., sending a message) is made.
    // The "conceptual" nature mentioned by the AI assistant previously refers to its
    // inability to test live API calls, not that this key storage and usage
    // mechanism is non-functional.
    
    if (apiKey.isNotEmpty) {
      // Simulate fetching user info after successful token exchange
      final user = UserModel(
        id: 'simulated_user_id_${DateTime.now().millisecondsSinceEpoch}',
        email: 'user@example.com', // Simulated email
        accessToken: apiKey, // In reality, this would be the OAuth token
      );
      await _saveUserSession(user);
      return user;
    }
    return null; // Failed authentication
  }

  Future<void> _saveUserSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, user.accessToken);
    await prefs.setString(_userIdKey, user.id);
    await prefs.setString(_userEmailKey, user.email);
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);
    final userId = prefs.getString(_userIdKey);
    final email = prefs.getString(_userEmailKey);

    if (token != null && userId != null && email != null) {
      return UserModel(id: userId, email: email, accessToken: token);
    }
    return null;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    // In a real app, also notify BLoCs/listeners to update UI
  }
}
