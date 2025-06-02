import 'package:chatgpt_clone/bloc/conversation_list/conversation_list_bloc.dart';
import 'package:chatgpt_clone/core/services/auth_service.dart';
import 'package:chatgpt_clone/core/services/database_helper.dart';
import 'package:chatgpt_clone/core/services/in_memory_database_helper.dart';
import 'package:chatgpt_clone/core/services/openai_api_service.dart';
import 'package:chatgpt_clone/presentation/screens/conversations_screen.dart';
import 'package:chatgpt_clone/presentation/screens/login_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Services are initialized here and passed to AppWrapper or directly to providers
  final authService = AuthService();
  final databaseHelper = getDatabaseHelper();
  final openAIApiService = OpenAIApiService(authService: authService);

  runApp(AppWrapper(
    authService: authService,
    databaseHelper: databaseHelper,
    openAIApiService: openAIApiService,
  ));
}

/**
 * Create a DatabaseHelper instance based on the platform.
 */
DatabaseHelper getDatabaseHelper() {
  return kIsWeb ? InMemoryDatabaseHelper() : DatabaseHelper.instance;
}

// New wrapper widget to host providers above MaterialApp
class AppWrapper extends StatelessWidget {
  final AuthService authService;
  final DatabaseHelper databaseHelper;
  final OpenAIApiService openAIApiService;

  const AppWrapper({
    super.key,
    required this.authService,
    required this.databaseHelper,
    required this.openAIApiService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthService>.value(value: authService),
        RepositoryProvider<DatabaseHelper>.value(value: databaseHelper),
        RepositoryProvider<OpenAIApiService>.value(value: openAIApiService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ConversationListBloc>(
            create: (context) => ConversationListBloc(
              databaseHelper: context.read<DatabaseHelper>(),
            )..add(LoadConversations()),
          ),
          // ChatBloc is provided per-instance in ConversationsScreen._navigateToChat
        ],
        child: const MyApp(), // MyApp is now a child of the providers
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // _checkLoginStatus can now safely use context.read<AuthService>()
  // as AuthService will be above it in the widget tree.
  Future<bool> _checkLoginStatus(BuildContext context) async {
    // Access AuthService using context.read because AppWrapper is above MyApp
    final authService = context.read<AuthService>();
    final user = await authService.getCurrentUser();
    // This is a conceptual login check for the API key.
    // In a real OAuth flow, token presence and validity would be checked.
    if (user != null && user.accessToken.isNotEmpty) {
        // Potentially, here you could also re-validate the key/token if it can expire
        // For now, just checking if it exists.
        return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_gpt',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: FutureBuilder<bool>(
        // Pass context to _checkLoginStatus
        future: _checkLoginStatus(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData && snapshot.data == true) {
            return const ConversationsScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
