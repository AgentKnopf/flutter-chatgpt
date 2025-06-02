import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // For RepositoryProvider if used
import 'package:chatgpt_clone/presentation/screens/login_screen.dart';
import 'package:chatgpt_clone/core/services/auth_service.dart'; // For providing AuthService
import 'package:mocktail/mocktail.dart'; // If AuthService needs mocking

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
    // Stub the signInWithOpenAI method for the conceptual login
    when(() => mockAuthService.signInWithOpenAI(any())).thenAnswer((_) async => null); // Default: login fails or no user
  });

  Widget createLoginScreen() {
    return MaterialApp(
      home: RepositoryProvider<AuthService>.value(
        value: mockAuthService, // Provide the mock
        child: const LoginScreen(),
      ),
    );
  }

  testWidgets('LoginScreen renders correctly and handles input', (WidgetTester tester) async {
    await tester.pumpWidget(createLoginScreen());

    // Verify presence of key widgets
    expect(find.byType(TextField), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Simulate Login / Continue'), findsOneWidget);
    expect(find.textContaining('Enter your OpenAI API Key'), findsOneWidget);

    // Enter text into the TextField
    await tester.enterText(find.byType(TextField), 'test_api_key');
    expect(find.text('test_api_key'), findsOneWidget);

    // Tap the login button
    // The actual login logic is conceptual and uses console print/snackbar.
    // We are testing that the button can be tapped.
    // The AuthService interaction is mocked if LoginScreen directly calls it.
    // Current LoginScreen uses its own _apiKeyController and calls print/ScaffoldMessenger.
    // If it were calling authService.signInWithOpenAI directly, we'd verify that.

    // For current LoginScreen that uses its own controller and shows a SnackBar:
    await tester.tap(find.widgetWithText(ElevatedButton, 'Simulate Login / Continue'));
    await tester.pump(); // For SnackBar animation

    // Verify SnackBar appears (if it's part of the widget's behavior on tap)
    // This depends on LoginScreen's implementation detail of showing a snackbar.
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Conceptual login with API Key: test_api_key'), findsOneWidget);
  });

  testWidgets('LoginScreen shows error SnackBar if API key is empty', (WidgetTester tester) async {
    await tester.pumpWidget(createLoginScreen());

    await tester.tap(find.widgetWithText(ElevatedButton, 'Simulate Login / Continue'));
    await tester.pump(); // For SnackBar animation

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Please enter an API Key to simulate login.'), findsOneWidget);
  });
}
