import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chatgpt_clone/bloc/conversation_list/conversation_list_bloc.dart';
import 'package:chatgpt_clone/presentation/screens/conversations_screen.dart';
import 'package:chatgpt_clone/core/models/conversation_model.dart';
import 'package:chatgpt_clone/core/services/database_helper.dart'; // For ChatBloc dependencies
import 'package:chatgpt_clone/core/services/openai_api_service.dart'; // For ChatBloc dependencies
import 'package:chatgpt_clone/core/services/auth_service.dart'; // For OpenAIApiService dependency
import 'package:mocktail/mocktail.dart';

// Mocks for BLoC and its dependencies
class MockConversationListBloc extends MockBloc<ConversationListEvent, ConversationListState> implements ConversationListBloc {}
// Mocks for services needed by ChatBloc when navigating
class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockOpenAIApiService extends Mock implements OpenAIApiService {}
class MockAuthService extends Mock implements AuthService {}


void main() {
  late MockConversationListBloc mockConversationListBloc;
  // Mocks for services that ChatBloc (created on navigation) will need
  late MockDatabaseHelper mockDatabaseHelper;
  late MockOpenAIApiService mockOpenAIApiService;
  late MockAuthService mockAuthService;


  setUp(() {
    mockConversationListBloc = MockConversationListBloc();
    mockDatabaseHelper = MockDatabaseHelper();
    mockOpenAIApiService = MockOpenAIApiService();
    mockAuthService = MockAuthService();

    // Stub the auth service for OpenAIApiService
    when(() => mockAuthService.getCurrentUser()).thenAnswer((_) async => null); // Default to no user for OpenAIApiService init
  });

  Widget createConversationsScreen() {
    return MultiRepositoryProvider(
      providers: [
        // Provide mocks for services that ChatBloc (created on navigation) will need
        RepositoryProvider<DatabaseHelper>.value(value: mockDatabaseHelper),
        RepositoryProvider<OpenAIApiService>.value(value: mockOpenAIApiService),
        RepositoryProvider<AuthService>.value(value: mockAuthService), // Though OpenAIApiService gets it directly
      ],
      child: MaterialApp(
        home: BlocProvider<ConversationListBloc>.value(
          value: mockConversationListBloc,
          child: const ConversationsScreen(),
        ),
        // Need a navigator observer for verifying navigation if we go that deep
      ),
    );
  }

  final tConversation1 = Conversation(id: '1', title: 'Chat 1', createdAt: DateTime.now(), updatedAt: DateTime.now());
  final tConversation2 = Conversation(id: '2', title: 'Chat 2', createdAt: DateTime.now(), updatedAt: DateTime.now().add(const Duration(minutes: 5)));

  testWidgets('Shows loading indicator when status is loading and conversations are empty', (WidgetTester tester) async {
    when(() => mockConversationListBloc.state).thenReturn(
      const ConversationListState(status: ConversationListStatus.loading, conversations: [])
    );
    await tester.pumpWidget(createConversationsScreen());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Shows error message when status is failure and conversations are empty', (WidgetTester tester) async {
    when(() => mockConversationListBloc.state).thenReturn(
      const ConversationListState(status: ConversationListStatus.failure, errorMessage: 'DB Error', conversations: [])
    );
    await tester.pumpWidget(createConversationsScreen());
    expect(find.textContaining('Error loading conversations: DB Error'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);
  });

  testWidgets('Shows "No conversations yet" when status is success and conversations are empty', (WidgetTester tester) async {
    when(() => mockConversationListBloc.state).thenReturn(
      const ConversationListState(status: ConversationListStatus.success, conversations: [])
    );
    await tester.pumpWidget(createConversationsScreen());
    expect(find.text('No conversations yet.'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Start New Chat'), findsOneWidget);
  });

  testWidgets('Displays list of conversations when status is success and conversations exist', (WidgetTester tester) async {
    final conversations = [tConversation1, tConversation2];
    when(() => mockConversationListBloc.state).thenReturn(
      ConversationListState(status: ConversationListStatus.success, conversations: conversations)
    );
    await tester.pumpWidget(createConversationsScreen());
    expect(find.byType(ListView), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Chat 1'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Chat 2'), findsOneWidget);
  });

  testWidgets('Tapping FAB dispatches CreateNewConversationAndSelect event', (WidgetTester tester) async {
    when(() => mockConversationListBloc.state).thenReturn(
      const ConversationListState(status: ConversationListStatus.success, conversations: []) // Start with empty to show FAB easily
    );
    await tester.pumpWidget(createConversationsScreen());
    await tester.tap(find.byType(FloatingActionButton));
    verify(() => mockConversationListBloc.add(const CreateNewConversationAndSelect())).called(1);
  });

  testWidgets('Tapping "Start New Chat" button dispatches CreateNewConversationAndSelect event', (WidgetTester tester) async {
    when(() => mockConversationListBloc.state).thenReturn(
      const ConversationListState(status: ConversationListStatus.success, conversations: [])
    );
    await tester.pumpWidget(createConversationsScreen());
    await tester.tap(find.widgetWithText(ElevatedButton, 'Start New Chat'));
    verify(() => mockConversationListBloc.add(const CreateNewConversationAndSelect())).called(1);
  });

  testWidgets('Tapping a conversation tile navigates (placeholder check)', (WidgetTester tester) async {
    // This test is more complex due to navigation creating another BLoC.
    // We'll primarily test that the tap occurs. Deep navigation testing is harder.
    final conversations = [tConversation1];
     when(() => mockConversationListBloc.state).thenReturn(
      ConversationListState(status: ConversationListStatus.success, conversations: conversations)
    );
    await tester.pumpWidget(createConversationsScreen());

    // Stub the ChatBloc creation dependencies if navigation is attempted
    // This part is tricky as ChatScreen itself is not directly part of this widget test's scope for deep interaction.
    // The navigation pushes a new route with a new BLoC.
    // We're testing ConversationsScreen, not the full navigation flow here.

    await tester.tap(find.widgetWithText(ListTile, 'Chat 1'));
    await tester.pumpAndSettle(); // Allow navigation to process

    // Verification of navigation is complex. For a unit/widget test of ConversationsScreen,
    // ensuring the tap handler is called or an event *would* be dispatched is often enough.
    // Here, the navigation is directly in the onTap.
    // We can't easily verify the new screen without a full integration test or complex NavigatorObserver setup.
    // For now, this test ensures no crash on tap.
    // To truly test the BlocProvider in navigation, one might need a test helper for navigation.
  });

  testWidgets('Tapping delete on a conversation shows confirmation dialog and dispatches event on confirm', (WidgetTester tester) async {
    final conversations = [tConversation1];
    when(() => mockConversationListBloc.state).thenReturn(
      ConversationListState(status: ConversationListStatus.success, conversations: conversations)
    );
    await tester.pumpWidget(createConversationsScreen());

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle(); // For dialog animation

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Delete Conversation?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle(); // Close dialog

    verify(() => mockConversationListBloc.add(DeleteConversation(conversationId: tConversation1.id))).called(1);
    expect(find.byType(AlertDialog), findsNothing); // Dialog is gone
  });
}
