// In chatgpt_clone/test/bloc/chat/chat_bloc_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:chatgpt_clone/bloc/chat/chat_bloc.dart'; // Ensure correct path
import 'package:chatgpt_clone/core/models/chat_message_model.dart';
import 'package:chatgpt_clone/core/models/conversation_model.dart';
import 'package:chatgpt_clone/core/services/database_helper.dart';
import 'package:chatgpt_clone/core/services/openai_api_service.dart';
import 'package:chatgpt_clone/core/errors/api_exceptions.dart';
import 'package:mocktail/mocktail.dart';
// Uuid is internal to ChatBloc, similar to ConversationListBloc.

// Mocks
class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockOpenAIApiService extends Mock implements OpenAIApiService {}

void main() {
  late ChatBloc chatBloc;
  late MockDatabaseHelper mockDatabaseHelper;
  late MockOpenAIApiService mockOpenAIApiService;
  const tConversationId = 'conv1';

  // Sample messages
  final tUserMessage = ChatMessageModel(id: 'user1', conversationId: tConversationId, text: 'Hello', sender: MessageSender.user, timestamp: DateTime.now());
  final tAiResponseMessage = ChatMessageModel(id: 'ai1', conversationId: tConversationId, text: 'Hi there!', sender: MessageSender.ai, timestamp: DateTime.now().add(const Duration(seconds: 1)));
  final tSystemErrorMessage = ChatMessageModel(id: 'sys1', conversationId: tConversationId, text: 'Error: API Failure', sender: MessageSender.system, timestamp: DateTime.now().add(const Duration(seconds: 2)));
  
  final tInitialConversation = Conversation(id: tConversationId, title: "Test Chat", createdAt: DateTime.now(), updatedAt: DateTime.now());

  setUpAll(() {
    // Register fallback values for any() matchers if necessary for complex types
    // For ChatMessageModel, if it's used with any(), we might need it.
    // For now, we'll try to use specific matchers or instances.
    registerFallbackValue(ChatMessageModel(id: '', conversationId: '', text: '', sender: MessageSender.user, timestamp: DateTime.now()));
  });

  setUp(() {
    mockDatabaseHelper = MockDatabaseHelper();
    mockOpenAIApiService = MockOpenAIApiService();
    chatBloc = ChatBloc(
      conversationId: tConversationId,
      databaseHelper: mockDatabaseHelper,
      apiService: mockOpenAIApiService,
    );

    // Default stub for getConversation, used in LoadChat
    when(() => mockDatabaseHelper.getConversation(any())).thenAnswer((_) async => tInitialConversation);
  });

  tearDown(() {
    chatBloc.close();
  });

  test('initial state is correct', () {
    expect(chatBloc.state, const ChatState(conversationId: tConversationId, status: ChatStatus.initial));
  });

  group('LoadChat', () {
    final tMessagesList = [tUserMessage, tAiResponseMessage];
    blocTest<ChatBloc, ChatState>(
      'emits [loadingMessages, messagesLoaded] when messages are fetched successfully',
      setUp: () {
        when(() => mockDatabaseHelper.getMessagesForConversation(tConversationId))
            .thenAnswer((_) async => tMessagesList);
        when(() => mockDatabaseHelper.getConversation(tConversationId))
            .thenAnswer((_) async => tInitialConversation);
      },
      build: () => chatBloc,
      act: (bloc) => bloc.add(const LoadChat(conversationId: tConversationId)),
      expect: () => [
        ChatState(conversationId: tConversationId, status: ChatStatus.loadingMessages, currentConversation: null, errorMessage: null), // clearError = true
        ChatState(conversationId: tConversationId, status: ChatStatus.messagesLoaded, messages: tMessagesList, currentConversation: tInitialConversation),
      ],
      verify: (_) {
        verify(() => mockDatabaseHelper.getMessagesForConversation(tConversationId)).called(1);
        verify(() => mockDatabaseHelper.getConversation(tConversationId)).called(1);
      }
    );

    blocTest<ChatBloc, ChatState>(
      'emits [loadingMessages, error] when DatabaseHelper.getMessagesForConversation throws',
      setUp: () {
        when(() => mockDatabaseHelper.getMessagesForConversation(tConversationId))
            .thenThrow(Exception('DB Error'));
      },
      build: () => chatBloc,
      act: (bloc) => bloc.add(const LoadChat(conversationId: tConversationId)),
      expect: () => [
        ChatState(conversationId: tConversationId, status: ChatStatus.loadingMessages, currentConversation: null, errorMessage: null),
        ChatState(conversationId: tConversationId, status: ChatStatus.error, errorMessage: 'Exception: DB Error', currentConversation: tInitialConversation), // getConversation might still succeed or be called
      ],
    );
  });

  group('SendMessage', () {
    const tUserText = "Hello AI";
    // Uuid is internal, so we capture the argument to insertMessage
    final capturedMessages = <ChatMessageModel>[];

    setUp(() {
        // Capture ChatMessageModel passed to insertMessage
        when(() => mockDatabaseHelper.insertMessage(captureAny<ChatMessageModel>()))
            .thenAnswer((invocation) async {
                capturedMessages.add(invocation.positionalArguments.first as ChatMessageModel);
                return 1;
            });
        // Default for getting history, which will now include the captured user message
        when(() => mockDatabaseHelper.getMessagesForConversation(tConversationId))
            .thenAnswer((_) async => capturedMessages);
    });
    
    tearDown(() {
        capturedMessages.clear();
    });

    blocTest<ChatBloc, ChatState>(
      'emits [sendingMessage, messagesLoaded with AI response] on successful API call',
      setUp: () {
        when(() => mockOpenAIApiService.sendChatCompletion(any()))
            .thenAnswer((_) async => tAiResponseMessage); // API returns this
      },
      build: () => chatBloc,
      act: (bloc) => bloc.add(const SendMessage(text: tUserText)),
      expect: () => [
        // State after user message is added locally
        isA<ChatState>() 
          .having((s) => s.status, 'status', ChatStatus.sendingMessage)
          .having((s) => s.messages.length, 'messages.length', 1)
          .having((s) => s.messages.last.text, 'messages.last.text', tUserText)
          .having((s) => s.messages.last.sender, 'messages.last.sender', MessageSender.user),
        // State after AI response is received and saved
        isA<ChatState>()
          .having((s) => s.status, 'status', ChatStatus.messagesLoaded)
          .having((s) => s.messages.length, 'messages.length', 2)
          .having((s) => s.messages.last.text, 'messages.last.text', tAiResponseMessage.text)
          .having((s) => s.messages.last.sender, 'messages.last.sender', MessageSender.ai),
      ],
      verify: (_) {
        verify(() => mockDatabaseHelper.insertMessage(any(that: predicate<ChatMessageModel>((m) => m.text == tUserText && m.sender == MessageSender.user)))).called(1);
        verify(() => mockOpenAIApiService.sendChatCompletion(any(that: isA<List<ChatMessageModel>>().having((l) => l.isNotEmpty && l.first.text == tUserText)))).called(1);
        verify(() => mockDatabaseHelper.insertMessage(any(that: predicate<ChatMessageModel>((m) => m.text == tAiResponseMessage.text && m.sender == MessageSender.ai)))).called(1);
      }
    );

    blocTest<ChatBloc, ChatState>(
      'emits [sendingMessage, error with system message] on API exception',
      setUp: () {
        when(() => mockOpenAIApiService.sendChatCompletion(any()))
            .thenThrow(ApiException('API Error', statusCode: 500));
      },
      build: () => chatBloc,
      act: (bloc) => bloc.add(const SendMessage(text: tUserText)),
      expect: () => [
        // User message added locally
        isA<ChatState>()
          .having((s) => s.status, 'status', ChatStatus.sendingMessage)
          .having((s) => s.messages.length, 'messages.length', 1)
          .having((s) => s.messages.last.text, 'messages.last.text', tUserText),
        // Error state with system message
        isA<ChatState>()
          .having((s) => s.status, 'status', ChatStatus.error)
          .having((s) => s.errorMessage, 'errorMessage', startsWith('ApiException: API Error'))
          .having((s) => s.messages.length, 'messages.length', 2) // User msg + System error msg
          .having((s) => s.messages.last.sender, 'messages.last.sender', MessageSender.system)
          .having((s) => s.messages.last.text, 'messages.last.text', startsWith('ApiException: API Error')),
      ],
      verify: (_) {
        verify(() => mockDatabaseHelper.insertMessage(any(that: predicate<ChatMessageModel>((m) => m.text == tUserText && m.sender == MessageSender.user)))).called(1);
        verify(() => mockOpenAIApiService.sendChatCompletion(any())).called(1);
        verify(() => mockDatabaseHelper.insertMessage(any(that: predicate<ChatMessageModel>((m) => m.sender == MessageSender.system && m.text.contains('API Error'))))).called(1);
      }
    );
  });
  
  group('RegenerateResponse', () {
    final userMessage1 = ChatMessageModel(id: 'u1', conversationId: tConversationId, text: 'First user msg', sender: MessageSender.user, timestamp: DateTime.now());
    final aiMessageToRegen = ChatMessageModel(id: 'ai_old', conversationId: tConversationId, text: 'Old AI response', sender: MessageSender.ai, timestamp: DateTime.now().add(Duration(seconds:1)));
    final newAiMessage = ChatMessageModel(id: 'ai_new', conversationId: tConversationId, text: 'New AI response', sender: MessageSender.ai, timestamp: DateTime.now().add(Duration(seconds:2)));

    blocTest<ChatBloc, ChatState>(
      'emits [sendingMessage, messagesLoaded with new AI response] when successful',
      seed: () => ChatState(conversationId: tConversationId, messages: [userMessage1, aiMessageToRegen], status: ChatStatus.messagesLoaded),
      setUp: () {
        when(() => mockOpenAIApiService.sendChatCompletion(any(that: predicate<List<ChatMessageModel>>((history) {
          // Verify that the history sent to API does not contain aiMessageToRegen
          return history.length == 1 && history.first.id == userMessage1.id;
        })))).thenAnswer((_) async => newAiMessage);
        
        when(() => mockDatabaseHelper.insertMessage(any(that: predicate<ChatMessageModel>((m) => m.text == newAiMessage.text))))
            .thenAnswer((_) async => 1);
      },
      build: () => chatBloc,
      act: (bloc) => bloc.add(const RegenerateResponse()),
      expect: () => [
        ChatState(conversationId: tConversationId, messages: [userMessage1, aiMessageToRegen], status: ChatStatus.sendingMessage, clearError: true),
        ChatState(conversationId: tConversationId, messages: [userMessage1, newAiMessage], status: ChatStatus.messagesLoaded), // Old AI message replaced by new one
      ],
      verify: (_) {
        verify(() => mockOpenAIApiService.sendChatCompletion(any())).called(1);
        verify(() => mockDatabaseHelper.insertMessage(any(that: predicate<ChatMessageModel>((m) => m.text == newAiMessage.text)))).called(1);
      }
    );
    
    blocTest<ChatBloc, ChatState>(
      'emits [sendingMessage, error with system message] on API failure during regeneration',
      seed: () => ChatState(conversationId: tConversationId, messages: [userMessage1, aiMessageToRegen], status: ChatStatus.messagesLoaded),
      setUp: () {
        when(() => mockOpenAIApiService.sendChatCompletion(any()))
            .thenThrow(ApiException('Regen API Error'));
        when(() => mockDatabaseHelper.insertMessage(any(that: predicate<ChatMessageModel>((m) => m.sender == MessageSender.system))))
            .thenAnswer((_) async => 1);
      },
      build: () => chatBloc,
      act: (bloc) => bloc.add(const RegenerateResponse()),
      expect: () => [
        ChatState(conversationId: tConversationId, messages: [userMessage1, aiMessageToRegen], status: ChatStatus.sendingMessage, clearError: true),
        isA<ChatState>()
          .having((s) => s.status, 'status', ChatStatus.error)
          .having((s) => s.errorMessage, 'errorMessage', startsWith('ApiException: Regen API Error'))
          // Original messages + new system error message
          .having((s) => s.messages.length, 'messages.length', 3) 
          .having((s) => s.messages.last.sender, 'messages.last.sender', MessageSender.system)
          .having((s) => s.messages.last.text, 'messages.last.text', startsWith('ApiException: Regen API Error')),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'emits [messagesLoaded with error] if history is empty after trying to remove last AI message',
      // Seed with only an AI message. After removal, history is empty.
      seed: () => ChatState(conversationId: tConversationId, messages: [aiMessageToRegen], status: ChatStatus.messagesLoaded),
      build: () => chatBloc,
      act: (bloc) => bloc.add(const RegenerateResponse()),
      expect: () => [
        ChatState(conversationId: tConversationId, messages: [aiMessageToRegen], status: ChatStatus.sendingMessage, clearError: true),
        ChatState(conversationId: tConversationId, messages: [aiMessageToRegen], status: ChatStatus.messagesLoaded, errorMessage: "Cannot regenerate from an empty history."),
      ],
      // No API call should be made if history becomes empty
      verify: (_) {
        verifyNever(() => mockOpenAIApiService.sendChatCompletion(any()));
      }
    );
  });
}
