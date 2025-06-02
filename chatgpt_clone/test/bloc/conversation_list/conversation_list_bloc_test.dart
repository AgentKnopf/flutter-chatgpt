import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:chatgpt_clone/bloc/conversation_list/conversation_list_bloc.dart'; // Ensure correct path
import 'package:chatgpt_clone/core/models/conversation_model.dart';
import 'package:chatgpt_clone/core/services/database_helper.dart';
// import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // For mock DB behavior if needed, or use a proper mock
import 'package:mocktail/mocktail.dart'; // Using mocktail for mocking
import 'package:uuid/uuid.dart';

// Mock DatabaseHelper
class MockDatabaseHelper extends Mock implements DatabaseHelper {}

// Mock Uuid
class MockUuid extends Mock implements Uuid {}

void main() {
  // Initialize FFI for sqflite if testing with actual DB calls (less ideal for unit tests)
  // sqfliteFfiInit();
  // databaseFactory = databaseFactoryFfi; // Use this if you were to use a real in-memory DB

  late ConversationListBloc conversationListBloc;
  late MockDatabaseHelper mockDatabaseHelper;
  late MockUuid mockUuid;

  // Sample conversations
  final tConversation1 = Conversation(id: '1', title: 'Test 1', createdAt: DateTime.now(), updatedAt: DateTime.now());
  final tConversation2 = Conversation(id: '2', title: 'Test 2', createdAt: DateTime.now(), updatedAt: DateTime.now().add(const Duration(hours: 1)));
  final List<Conversation> tConversationsList = [tConversation2, tConversation1]; // Assuming DESC order from DB

  setUp(() {
    mockDatabaseHelper = MockDatabaseHelper();
    mockUuid = MockUuid();
    // NOTE: ConversationListBloc uses its own Uuid instance internally.
    // To make Uuid mockable for testing ID generation, it would need to be injected.
    // The current tests for CreateNewConversationAndSelect work around this.
    conversationListBloc = ConversationListBloc(databaseHelper: mockDatabaseHelper);

    // This mockUuid instance is not used by the BLoC itself, but can be used in test setups
    // if we needed to predict an ID for verification purposes (e.g., if Uuid was injected).
    when(() => mockUuid.v4()).thenReturn('new_conv_id_from_mock');
  });

  tearDown(() {
    conversationListBloc.close();
  });

  test('initial state is correct', () {
    expect(conversationListBloc.state, const ConversationListState());
  });

  group('LoadConversations', () {
    blocTest<ConversationListBloc, ConversationListState>(
      'emits [loading, success] when DatabaseHelper.getAllConversations returns data',
      setUp: () {
        when(() => mockDatabaseHelper.getAllConversations())
            .thenAnswer((_) async => tConversationsList);
      },
      build: () => conversationListBloc,
      act: (bloc) => bloc.add(LoadConversations()),
      expect: () => [
        const ConversationListState(status: ConversationListStatus.loading),
        ConversationListState(status: ConversationListStatus.success, conversations: tConversationsList),
      ],
      verify: (_) {
        verify(() => mockDatabaseHelper.getAllConversations()).called(1);
      }
    );

    blocTest<ConversationListBloc, ConversationListState>(
      'emits [loading, success with empty list] when DatabaseHelper.getAllConversations returns empty',
      setUp: () {
        when(() => mockDatabaseHelper.getAllConversations())
            .thenAnswer((_) async => []);
      },
      build: () => conversationListBloc,
      act: (bloc) => bloc.add(LoadConversations()),
      expect: () => [
        const ConversationListState(status: ConversationListStatus.loading),
        const ConversationListState(status: ConversationListStatus.success, conversations: []),
      ],
    );

    blocTest<ConversationListBloc, ConversationListState>(
      'emits [loading, failure] when DatabaseHelper.getAllConversations throws an exception',
      setUp: () {
        when(() => mockDatabaseHelper.getAllConversations())
            .thenThrow(Exception('DB Error'));
      },
      build: () => conversationListBloc,
      act: (bloc) => bloc.add(LoadConversations()),
      expect: () => [
        const ConversationListState(status: ConversationListStatus.loading),
        const ConversationListState(status: ConversationListStatus.failure, errorMessage: 'Exception: DB Error'),
      ],
    );
  });

  group('CreateNewConversationAndSelect', () {
    // Since Uuid is internal to the Bloc, we can't easily mock its direct output for ID.
    // We test the interaction and the resulting state based on successful DB operations.
    const tInitialMessage = "Hello there";
    final tExpectedTitle = (tInitialMessage.length > 30 ? tInitialMessage.substring(0, 30) : tInitialMessage) + '...';

    // A conversation object that would be returned by getAllConversations after insert.
    // The ID is unknown here as it's generated inside the Bloc.
    final tNewlyCreatedConversation = Conversation(id: 'some_generated_id', title: tExpectedTitle, createdAt: DateTime.now(), updatedAt: DateTime.now());


    blocTest<ConversationListBloc, ConversationListState>(
      'emits [loading, success with new conv] and calls DB insert/getAll',
      setUp: () {
        when(() => mockDatabaseHelper.insertConversation(any(that: isA<Conversation>())))
            .thenAnswer((_) async => 1);
        when(() => mockDatabaseHelper.getAllConversations())
            .thenAnswer((_) async => [
              // Simulate the newly created conversation is now part of the list
              // For a robust test, we'd need to ensure this matches what was inserted,
              // but without ID prediction, we simulate a successful fetch.
              tNewlyCreatedConversation,
              ...tConversationsList
            ]);
      },
      build: () => conversationListBloc,
      act: (bloc) => bloc.add(const CreateNewConversationAndSelect(initialMessage: tInitialMessage)),
      expect: () => [
        const ConversationListState(status: ConversationListStatus.loading, clearSelectedConversationId: true),
        isA<ConversationListState>()
          .having((state) => state.status, 'status', ConversationListStatus.success)
          .having((state) => state.selectedConversationIdOnCreation, 'selectedConversationIdOnCreation', isNotNull)
          .having((state) => state.conversations.length, 'conversations length', tConversationsList.length + 1)
          .having((state) => state.conversations.first.title, 'first conversation title', tExpectedTitle) // Assuming new conv is first
      ],
      verify: (_) {
        // Verify insertConversation was called with a Conversation object matching the expected title.
        verify(() => mockDatabaseHelper.insertConversation(
          any(that: isA<Conversation>().having((c) => c.title, 'title', tExpectedTitle))
        )).called(1);
        verify(() => mockDatabaseHelper.getAllConversations()).called(1);
      }
    );

    blocTest<ConversationListBloc, ConversationListState>(
      'emits [loading, failure] if DB insert throws',
      setUp: () {
        when(() => mockDatabaseHelper.insertConversation(any(that: isA<Conversation>())))
            .thenThrow(Exception('DB Insert Error'));
      },
      build: () => conversationListBloc,
      act: (bloc) => bloc.add(const CreateNewConversationAndSelect(initialMessage: "test")),
      expect: () => [
        const ConversationListState(status: ConversationListStatus.loading, clearSelectedConversationId: true),
        const ConversationListState(status: ConversationListStatus.failure, errorMessage: 'Exception: DB Insert Error'),
      ],
    );
  });

  group('DeleteConversation', () {
    const tConversationIdToDelete = '1';
    blocTest<ConversationListBloc, ConversationListState>(
      'emits [loading, success with updated list] after deleting',
      setUp: () {
        when(() => mockDatabaseHelper.deleteConversation(tConversationIdToDelete))
            .thenAnswer((_) async => 1);
        when(() => mockDatabaseHelper.getAllConversations())
            .thenAnswer((_) async => [tConversation2]); // tConversation1 is deleted
      },
      build: () => conversationListBloc,
      act: (bloc) => bloc.add(const DeleteConversation(conversationId: tConversationIdToDelete)),
      expect: () => [
        const ConversationListState(status: ConversationListStatus.loading),
        const ConversationListState(status: ConversationListStatus.loading),
        ConversationListState(status: ConversationListStatus.success, conversations: [tConversation2]),
      ],
       verify: (_) {
        verify(() => mockDatabaseHelper.deleteConversation(tConversationIdToDelete)).called(1);
        verify(() => mockDatabaseHelper.getAllConversations()).called(1);
      }
    );

    blocTest<ConversationListBloc, ConversationListState>(
      'emits [loading, failure] if DB delete throws',
      setUp: () {
        when(() => mockDatabaseHelper.deleteConversation(any()))
            .thenThrow(Exception('DB Delete Error'));
      },
      build: () => conversationListBloc,
      act: (bloc) => bloc.add(const DeleteConversation(conversationId: '1')),
      expect: () => [
        const ConversationListState(status: ConversationListStatus.loading),
        const ConversationListState(status: ConversationListStatus.failure, errorMessage: 'Exception: DB Delete Error'),
      ],
    );
  });

  group('UpdateConversationTitle', () {
    const tConversationIdToUpdate = '1';
    const tNewTitle = "Updated Title";
    final tOriginalConversation = Conversation(id: tConversationIdToUpdate, title: "Original Title", createdAt: DateTime.now(), updatedAt: DateTime.now());
    // Create a new instance for the expected updated conversation to avoid issues with object mutation in tests.
    final tUpdatedConversationAfterDb = Conversation(id: tConversationIdToUpdate, title: tNewTitle, createdAt: tOriginalConversation.createdAt, updatedAt: DateTime.now());

    blocTest<ConversationListBloc, ConversationListState>(
      'emits [success with updated list] after updating title',
      setUp: () {
        when(() => mockDatabaseHelper.getConversation(tConversationIdToUpdate))
            .thenAnswer((_) async => tOriginalConversation);
        // Matcher for the updated conversation. Ensure updatedAt is also considered if relevant.
        when(() => mockDatabaseHelper.updateConversation(any(that: isA<Conversation>()
            .having((c) => c.id, 'id', tConversationIdToUpdate)
            .having((c) => c.title, 'title', tNewTitle))))
            .thenAnswer((_) async => 1);
        when(() => mockDatabaseHelper.getAllConversations())
            // Simulate the list containing the updated conversation
            .thenAnswer((_) async => [tUpdatedConversationAfterDb, tConversation2]);
      },
      build: () => conversationListBloc,
      act: (bloc) => bloc.add(const UpdateConversationTitle(conversationId: tConversationIdToUpdate, newTitle: tNewTitle)),
      expect: () => [
        const ConversationListState(status: ConversationListStatus.loading),
        ConversationListState(status: ConversationListStatus.success, conversations: [tUpdatedConversationAfterDb, tConversation2]),
      ],
      verify: (_) {
        verify(() => mockDatabaseHelper.getConversation(tConversationIdToUpdate)).called(1);
        verify(() => mockDatabaseHelper.updateConversation(any(that: isA<Conversation>()
            .having((c) => c.id, 'id', tConversationIdToUpdate)
            .having((c) => c.title, 'title', tNewTitle)))).called(1);
        verify(() => mockDatabaseHelper.getAllConversations()).called(1);
      }
    );

    blocTest<ConversationListBloc, ConversationListState>(
      'emits [failure] if conversation to update is not found',
      setUp: () {
        when(() => mockDatabaseHelper.getConversation(any())).thenAnswer((_) async => null);
      },
      build: () => conversationListBloc,
      act: (bloc) => bloc.add(const UpdateConversationTitle(conversationId: "unknown", newTitle: "test")),
      expect: () => [
        const ConversationListState(status: ConversationListStatus.failure, errorMessage: "Conversation not found for update."),
      ],
    );

    blocTest<ConversationListBloc, ConversationListState>(
      'emits [failure] if DB update throws',
      setUp: () {
         when(() => mockDatabaseHelper.getConversation(tConversationIdToUpdate))
            .thenAnswer((_) async => tOriginalConversation);
        when(() => mockDatabaseHelper.updateConversation(any(that: isA<Conversation>())))
            .thenThrow(Exception('DB Update Error'));
      },
      build: () => conversationListBloc,
      act: (bloc) => bloc.add(const UpdateConversationTitle(conversationId: tConversationIdToUpdate, newTitle: tNewTitle)),
      expect: () => [
        const ConversationListState(status: ConversationListStatus.failure, errorMessage: 'Exception: DB Update Error'),
      ],
    );
  });
}
