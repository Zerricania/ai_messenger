import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/auth_screen.dart';
import '../features/characters/characters_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/favorites/favorites_screen.dart';
import '../features/admin/admin_screen.dart';
import '../providers/app_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/auth',
    redirect: (context, state) {
      final isLoggedIn = authState.asData?.value != null;
      final isLoading = authState.isLoading;
      final isOnAuth = state.matchedLocation == '/auth';

      if (isLoading) return null;
      if (!isLoggedIn && !isOnAuth) return '/auth';
      if (isLoggedIn && isOnAuth) return '/characters';

      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (ctx, st) => const AuthScreen()),
      GoRoute(path: '/characters', builder: (ctx, st) => const CharactersScreen()),
      GoRoute(
        path: '/chat/:characterId',
        builder: (ctx, st) => ChatScreen(
          characterId: st.pathParameters['characterId']!,
        ),
      ),
      GoRoute(path: '/profile', builder: (ctx, st) => const ProfileScreen()),
      GoRoute(path: '/settings', builder: (ctx, st) => const SettingsScreen()),
      GoRoute(path: '/favorites', builder: (ctx, st) => const FavoritesScreen()),
      GoRoute(path: '/admin', builder: (ctx, st) => const AdminScreen()),
    ],
  );
});
