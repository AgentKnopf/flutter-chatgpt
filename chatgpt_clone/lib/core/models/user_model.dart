// Conceptual model for user data obtained after authentication
class UserModel {
  final String id;
  final String email; // Or other relevant user info from OpenAI
  final String accessToken; // Store securely

  UserModel({
    required this.id,
    required this.email,
    required this.accessToken,
  });

  // Placeholder for potential future methods like toJson/fromJson
}
