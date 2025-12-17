import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/characters/characters_screen.dart';
import 'features/chat/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

// Проверка доступен ли API, если нет запускаем программу без него.
  try {
    await dotenv.load(fileName: ".env");
    debugPrint(".env успешно загружен");
  } catch (e) {
    debugPrint(".env не найден или ошибка — продолжаем без API (для теста)");
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AI Messenger',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: GoRouter(
        initialLocation: '/auth',
        routes: [
          GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
          GoRoute(path: '/characters', builder: (_, __) => const CharactersScreen()),
          GoRoute(
            path: '/chat/:characterId',
            builder: (context, state) => ChatScreen(
              characterId: state.pathParameters['characterId']!,
            ),
          ),
        ],
      ),
    );
  }
}