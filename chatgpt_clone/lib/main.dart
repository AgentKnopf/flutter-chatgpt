import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chatgpt_clone/bloc/conversation_list/conversation_list_bloc.dart';
import 'package:chatgpt_clone/core/services/auth_service.dart';
import 'package:chatgpt_clone/core/services/database_helper.dart';
import 'package:chatgpt_clone/core/services/openai_api_service.dart';
import 'package:chatgpt_clone/presentation/screens/conversations_screen.dart';
import 'package:chatgpt_clone/presentation/screens/login_screen.dart';
// ChatBloc is not provided globally here, but its dependencies are.

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // No need to create instances here if provided by RepositoryProvider directly
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define services at a level where they can be provided to BLoCs
    // These will be singletons for the app's lifecycle if MyApp is the root.
    final authService = AuthService();
    final databaseHelper = DatabaseHelper.instance;
    // Ensure OpenAIApiService gets the authService instance
    final openAIApiService = OpenAIApiService(authService: authService); 

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
              // Read DatabaseHelper from RepositoryProvider
              databaseHelper: context.read<DatabaseHelper>(), 
            )..add(LoadConversations()),
          ),
          // ChatBloc is provided per-instance in ConversationsScreen._navigateToChat
        ],
        child: MaterialApp(
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
            // FutureBuilder now uses context.read<AuthService>()
            // to access the AuthService instance provided by MultiRepositoryProvider.
            future: context.read<AuthService>().getCurrentUser().then((user) => user != null && user.accessToken.isNotEmpty),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasData && snapshot.data == true) {
                // No need for dummy login here anymore, actual auth state is checked.
                return const ConversationsScreen();
              }
              return const LoginScreen();
            },
          ),
        ),
      ),
    );
  }
}
