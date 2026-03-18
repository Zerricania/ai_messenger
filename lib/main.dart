import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'core/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Файл .env не найден — AI функции недоступны');
  }

  await Firebase.initializeApp();

  // Инициализируем FCM после Firebase
  await FcmService.initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeSettings = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'AI Messenger',
      theme: buildTheme(themeSettings),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
