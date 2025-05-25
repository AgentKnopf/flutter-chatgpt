import 'chat_message_model.dart';

class ChatCompletionRequest {
  final String model;
  final List<ChatMessageModel> messages; // Use the new ChatMessageModel
  final double? temperature; // Optional: Add other parameters as needed
  // final int? maxTokens;

  ChatCompletionRequest({
    required this.model,
    required this.messages,
    this.temperature,
    // this.maxTokens,
  });

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'messages': messages.map((msg) => msg.toApiJson()).toList(),
      if (temperature != null) 'temperature': temperature,
      // if (maxTokens != null) 'max_tokens': maxTokens,
    };
  }
}
