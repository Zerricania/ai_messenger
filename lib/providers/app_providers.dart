import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/chat_repository.dart';
import '../data/models/user_model.dart';
import '../data/models/character_model.dart';

// ─── Репозитории ───────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(),
);

// ─── Стрим авторизации ─────────────────────────────────────────────────────────

final authStateProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

// ─── Данные пользователя из Firestore ─────────────────────────────────────────

final currentUserProvider = StreamProvider<UserModel?>((ref) async* {
  await for (final user in FirebaseAuth.instance.authStateChanges()) {
    if (user == null) {
      yield null;
    } else {
      final userModel = await ref
          .read(authRepositoryProvider)
          .getCurrentUserModel();
      yield userModel;
    }
  }
});

// ─── Персонажи пользователя ────────────────────────────────────────────────────

final userCharactersProvider =
    FutureProvider.autoDispose<List<CharacterModel>>((ref) async {
  final user = ref.watch(currentUserProvider).asData?.value;
  if (user == null) return <CharacterModel>[];
  return ref.read(userRepositoryProvider).getUserCharacters(user.uid);
});
