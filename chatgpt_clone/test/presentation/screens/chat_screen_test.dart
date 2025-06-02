import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chatgpt_clone/bloc/chat/chat_bloc.dart';
import 'package:chatgpt_clone/presentation/screens/chat_screen.dart';
import 'package:chatgpt_clone/presentation/widgets/message_bubble.dart';
import 'package:chatgpt_clone/presentation/widgets/message_input_field.dart';
import 'package:chatgpt_clone/core/models/chat_message_model.dart';
import 'package:chatgpt_clone/core/models/conversation_model.dart';
import 'package:mocktail/mocktail.dart';

class MockChatBloc extends MockBloc<ChatEvent, ChatState> implements ChatBloc {}

void main() {
  late MockChatBloc mockChatBloc;
  const tConversationId = 'testConv1';
  final tConversation = Conversation(id: tConversationId, title: "Test Chat", createdAt: DateTime.now(), updatedAt: DateTime.now());

  setUp(() {
    mockChatBloc = MockChatBloc();
    // Provide a default state for ChatBloc, including the conversationId it's responsible for
    when(() => mockChatBloc.state).thenReturn(
      ChatState(conversationId: tConversationId, status: ChatStatus.initial, currentConversation: tConversation)
    );
  });

  Widget createChatScreen() {
    return MaterialApp(
      home: BlocProvider<ChatBloc>.value(
        value: mockChatBloc,
        child: const ChatScreen(conversationId: tConversationId),
      ),
    );
  }
  
  final userMessage = ChatMessageModel(id: 'm1', conversationId: tConversationId, text: 'User says hi', sender: MessageSender.user, timestamp: DateTime.now());
  final aiMessage = ChatMessageModel(id: 'm2', conversationId: tConversationId, text: 'AI says hello', sender: MessageSender.ai, timestamp: DateTime.now());

  testWidgets('Shows loading indicator when ChatState is loadingMessages and messages are empty', (WidgetTester tester) async {
    when(() => mockChatBloc.state).thenReturn(
      ChatState(conversationId: tConversationId, status: ChatStatus.loadingMessages, messages: [], currentConversation: tConversation)
    );
    await tester.pumpWidget(createChatScreen());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Shows "No messages yet" when messages are empty and not loading', (WidgetTester tester) async {
    when(() => mockChatBloc.state).thenReturn(
       ChatState(conversationId: tConversationId, status: ChatStatus.messagesLoaded, messages: [], currentConversation: tConversation)
    );
    await tester.pumpWidget(createChatScreen());
    expect(find.text('No messages yet. Send one to start!'), findsOneWidget);
  });

  testWidgets('Displays messages from ChatBloc state', (WidgetTester tester) async {
    when(() => mockChatBloc.state).thenReturn(
      ChatState(conversationId: tConversationId, status: ChatStatus.messagesLoaded, messages: [userMessage, aiMessage], currentConversation: tConversation)
    );
    await tester.pumpWidget(createChatScreen());
    expect(find.byType(MessageBubble), findsNWidgets(2));
    expect(find.text('User says hi'), findsOneWidget);
    expect(find.text('AI says hello'), findsOneWidget);
  });

  testWidgets('Sends message via MessageInputField and dispatches SendMessage event', (WidgetTester tester) async {
    when(() => mockChatBloc.state).thenReturn(
      ChatState(conversationId: tConversationId, status: ChatStatus.messagesLoaded, messages: [], currentConversation: tConversation)
    );
    await tester.pumpWidget(createChatScreen());

    const testMsg = 'New message from input';
    await tester.enterText(find.byType(TextField), testMsg);
    await tester.tap(find.byIcon(Icons.send));
    
    verify(() => mockChatBloc.add(const SendMessage(text: testMsg))).called(1);
  });
  
  testWidgets('AppBar title displays conversation title from ChatBloc state', (WidgetTester tester) async {
    when(() => mockChatBloc.state).thenReturn(
      ChatState(conversationId: tConversationId, status: ChatStatus.messagesLoaded, currentConversation: tConversation)
    );
    await tester.pumpWidget(createChatScreen());
    expect(find.widgetWithText(AppBar, 'Test Chat'), findsOneWidget);
  });
  
  testWidgets('Shows refresh icon and dispatches RegenerateResponse when applicable', (WidgetTester tester) async {
    when(() => mockChatBloc.state).thenReturn(
      ChatState(conversationId: tConversationId, status: ChatStatus.messagesLoaded, messages: [aiMessage], currentConversation: tConversation) // Ensure an AI message exists
    );
    await tester.pumpWidget(createChatScreen());
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    await tester.tap(find.byIcon(Icons.refresh));
    verify(() => mockChatBloc.add(const RegenerateResponse())).called(1);
  });

  testWidgets('Does not show refresh icon if no AI messages', (WidgetTester tester) async {
    when(() => mockChatBloc.state).thenReturn(
      ChatState(conversationId: tConversationId, status: ChatStatus.messagesLoaded, messages: [userMessage], currentConversation: tConversation)
    );
    await tester.pumpWidget(createChatScreen());
    expect(find.byIcon(Icons.refresh), findsNothing);
  });
}
