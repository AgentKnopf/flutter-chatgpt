import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:chatgpt_clone/core/services/openai_api_service.dart';
import 'package:chatgpt_clone/core/services/auth_service.dart';
import 'package:chatgpt_clone/core/models/user_model.dart';
import 'package:chatgpt_clone/core/models/chat_message_model.dart';
import 'package:chatgpt_clone/core/models/api_request_model.dart';
import 'package:chatgpt_clone/core/models/api_response_model.dart';
import 'package:chatgpt_clone/core/errors/api_exceptions.dart';
import 'package:chatgpt_clone/core/utils/api_constants.dart';

// Mocks
class MockHttpClient extends Mock implements http.Client {}
class MockAuthService extends Mock implements AuthService {}

void main() {
  late OpenAIApiService apiService;
  late MockHttpClient mockHttpClient;
  late MockAuthService mockAuthService;

  setUpAll(() {
    // Fallback for ChatCompletionRequest if used with any()
    registerFallbackValue(ChatCompletionRequest(model: '', messages: [])); 
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockAuthService = MockAuthService();
    apiService = OpenAIApiService(client: mockHttpClient, authService: mockAuthService);

    // Default stub for auth service
    when(() => mockAuthService.getCurrentUser())
        .thenAnswer((_) async => UserModel(id: 'test_user', email: 'test@example.com', accessToken: 'test_api_key'));
    
    // Also stub getApiKey directly as it's called by sendChatCompletion
    when(() => mockAuthService.getApiKey()) // Assuming AuthService has getApiKey or similar
        .thenAnswer((_) async => 'test_api_key');

  });

  final tUserMessages = [
    ChatMessageModel(id: '1', conversationId: 'c1', text: 'Hello', sender: MessageSender.user, timestamp: DateTime.now())
  ];

  group('OpenAIApiService - sendChatCompletion', () {
    test('returns ChatMessageModel on successful API call (200)', () async {
      final mockResponsePayload = {
        "id": "chatcmpl-test123",
        "object": "chat.completion",
        "created": 1677652288,
        "model": ApiConstants.defaultChatModel,
        "choices": [
          {
            "index": 0,
            "message": {"role": "assistant", "content": "Hello there! How can I help you today?"},
            "finish_reason": "stop"
          }
        ],
        "usage": {"prompt_tokens": 9, "completion_tokens": 12, "total_tokens": 21}
      };

      when(() => mockHttpClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(jsonEncode(mockResponsePayload), 200, headers: {'content-type': 'application/json; charset=utf-8'}));


      final result = await apiService.sendChatCompletion(tUserMessages);

      expect(result, isA<ChatMessageModel>());
      expect(result.sender, MessageSender.ai);
      expect(result.text, "Hello there! How can I help you today?");
      verify(() => mockHttpClient.post(
        Uri.parse(ApiConstants.openAIBaseUrl + ApiConstants.chatCompletionsEndpoint),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer test_api_key'},
        body: any(named: 'body'), 
      )).called(1);
    });

    test('throws ApiException when user is not authenticated (getApiKey throws)', () async {
      // Override the default stub for getApiKey for this specific test
      when(() => mockAuthService.getApiKey())
          .thenThrow(ApiException('User not authenticated or API key not found.'));

      expect(
        () => apiService.sendChatCompletion(tUserMessages),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'User not authenticated or API key not found.'))
      );
      verifyNever(() => mockHttpClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')));
    });
    
    test('throws ApiException on API error (e.g., 401 Unauthorized)', () async {
      final errorPayload = {"error": {"message": "Incorrect API key provided.", "type": "invalid_request_error"}};
      when(() => mockHttpClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(jsonEncode(errorPayload), 401, headers: {'content-type': 'application/json; charset=utf-8'}));


      expect(
        () => apiService.sendChatCompletion(tUserMessages),
        throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 401)
          .having((e) => e.message, 'message', 'Incorrect API key provided.'))
      );
    });

    test('throws ApiException on general HTTP error (e.g., 500)', () async {
      when(() => mockHttpClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response('Server Error', 500, headers: {'content-type': 'text/plain; charset=utf-8'}));
      
      expect(
        () => apiService.sendChatCompletion(tUserMessages),
        throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 500)
          .having((e) => e.message, 'message', startsWith('API request failed with status 500')))
      );
    });
    
    test('throws ApiException if API returns no choices', () async {
       final mockResponsePayload = {
        "id": "chatcmpl-test123", "object": "chat.completion", "created": 1677652288, "model": ApiConstants.defaultChatModel,
        "choices": [], // Empty choices
        "usage": {"prompt_tokens": 9, "completion_tokens": 0, "total_tokens": 9}
      };
      when(() => mockHttpClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(jsonEncode(mockResponsePayload), 200, headers: {'content-type': 'application/json; charset=utf-8'}));


      expect(
        () => apiService.sendChatCompletion(tUserMessages),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'No response choices received from API.'))
      );
    });

    test('throws ApiException on network or other client error', () async {
      when(() => mockHttpClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenThrow(Exception('Network error'));
      
      expect(
        () => apiService.sendChatCompletion(tUserMessages),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Failed to connect to OpenAI API: Exception: Network error'))
      );
    });
  });
}
