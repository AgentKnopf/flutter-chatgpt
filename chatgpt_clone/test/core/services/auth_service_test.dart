import 'package:flutter_test/flutter_test.dart';
import 'package:chatgpt_clone/core/services/auth_service.dart';
import 'package:chatgpt_clone/core/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';

// Mock SharedPreferences if direct calls are problematic in test environment
// For this test, we'll use SharedPreferences.setMockInitialValues for simplicity

void main() {
  late AuthService authService;

  setUp(() {
    authService = AuthService();
    // It's important that SharedPreferences are prepared for each test
    // if they are not mocked away completely.
  });

  group('AuthService', () {
    const testApiKey = 'test_api_key';
    const testUserId = 'simulated_user_id_test';
    const testUserEmail = 'user@example.com';

    test('signInWithOpenAI stores user details in SharedPreferences and returns UserModel', () async {
      // Prepare SharedPreferences mock values
      SharedPreferences.setMockInitialValues({});

      final user = await authService.signInWithOpenAI(testApiKey);

      expect(user, isNotNull);
      expect(user!.accessToken, testApiKey);
      expect(user.email, testUserEmail); // Based on hardcoded value in AuthService
      expect(user.id, startsWith('simulated_user_id_'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('openai_access_token'), testApiKey);
      expect(prefs.getString('openai_user_email'), testUserEmail);
      expect(prefs.getString('openai_user_id'), user.id);
    });

    test('signInWithOpenAI returns null if API key is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final user = await authService.signInWithOpenAI('');
      expect(user, isNull);
    });

    test('getCurrentUser returns UserModel if session exists', () async {
      SharedPreferences.setMockInitialValues({
        'openai_access_token': testApiKey,
        'openai_user_id': testUserId,
        'openai_user_email': testUserEmail,
      });

      final user = await authService.getCurrentUser();

      expect(user, isNotNull);
      expect(user!.accessToken, testApiKey);
      expect(user.id, testUserId);
      expect(user.email, testUserEmail);
    });

    test('getCurrentUser returns null if no session exists', () async {
      SharedPreferences.setMockInitialValues({});
      final user = await authService.getCurrentUser();
      expect(user, isNull);
    });

    test('getCurrentUser returns null if session is incomplete', () async {
      SharedPreferences.setMockInitialValues({
        'openai_access_token': testApiKey,
        // Missing userId and email
      });
      final user = await authService.getCurrentUser();
      expect(user, isNull);
    });

    test('signOut clears user details from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'openai_access_token': testApiKey,
        'openai_user_id': testUserId,
        'openai_user_email': testUserEmail,
      });

      await authService.signOut();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('openai_access_token'), isNull);
      expect(prefs.getString('openai_user_id'), isNull);
      expect(prefs.getString('openai_user_email'), isNull);
    });
  });
}
