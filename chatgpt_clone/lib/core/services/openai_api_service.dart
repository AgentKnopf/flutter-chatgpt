import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_request_model.dart';
import '../models/api_response_model.dart';
import '../models/chat_message_model.dart';
import '../utils/api_constants.dart';
import '../errors/api_exceptions.dart';
import 'auth_service.dart'; // To get the API key

class OpenAIApiService {
  final http.Client _client;
  final AuthService _authService; // For retrieving API key/token

  OpenAIApiService({http.Client? client, required AuthService authService})
      : _client = client ?? http.Client(),
        _authService = authService;

  Future<String> getApiKey() async {
    // In a real app, the AuthService would provide the OAuth token.
    // For this conceptual version, it might still be direct API key from user input
    // or a saved key if implementing full API key auth.
    final user = await _authService.getCurrentUser();
    if (user == null || user.accessToken.isEmpty) {
      throw ApiException('User not authenticated or API key not found.');
    }
    return user.accessToken; // This is the API key in our current conceptual model
  }

  Future<ChatMessageModel> sendChatCompletion(List<ChatMessageModel> messages) async {
    final apiKey = await getApiKey();
    final requestModel = ChatCompletionRequest(
      model: ApiConstants.defaultChatModel,
      messages: messages,
      // temperature: 0.7, // Optional: set temperature
    );

    final uri = Uri.parse(ApiConstants.openAIBaseUrl + ApiConstants.chatCompletionsEndpoint);

    try {
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestModel.toJson()),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(utf8.decode(response.bodyBytes)); // Ensure UTF-8 decoding
        final chatResponse = ChatCompletionResponse.fromJson(responseBody);

        if (chatResponse.choices.isNotEmpty) {
          final aiMessage = chatResponse.choices.first.message;
          return ChatMessageModel(
            id: chatResponse.id, // Or generate a new client-side ID
            text: aiMessage.content,
            sender: MessageSender.ai,
            timestamp: DateTime.now(), conversationId: 'DUMMY ID',
          );
        } else {
          throw ApiException('No response choices received from API.');
        }
      } else {
        // Attempt to parse error message from API
        String errorMessage = 'API request failed';
        try {
            final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
            if (errorBody['error'] != null && errorBody['error']['message'] != null) {
                errorMessage = errorBody['error']['message'];
            }
        } catch (e) {
            // Ignore parsing error, use default message + body
            errorMessage = 'API request failed with status ${response.statusCode}. Body: ${response.body}';
        }
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to connect to OpenAI API: ${e.toString()}');
    }
  }
}
