import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../core/constants.dart';
import '../../core/services/fcm_service.dart';

class AuthRepository {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  static const _timeout = Duration(seconds: 15);

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Вход через Google
  Future<UserModel> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
    final googleUser = await googleSignIn.signIn().timeout(
      _timeout,
      onTimeout: () =>
          throw Exception('Превышено время ожидания. Проверь подключение'),
    );
    if (googleUser == null) throw Exception('Вход через Google отменён');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential).timeout(
      _timeout,
      onTimeout: () =>
          throw Exception('Превышено время ожидания. Проверь подключение'),
    );

    final userModel = await _saveUserToFirestore(userCredential.user!);
    await FcmService.onUserLoggedIn(); // сохраняем FCM-токен
    return userModel;
  }

  /// Регистрация по email
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final userCredential = await _auth
        .createUserWithEmailAndPassword(email: email, password: password)
        .timeout(
      _timeout,
      onTimeout: () =>
          throw Exception('Превышено время ожидания. Проверь подключение'),
    );
    await userCredential.user!.updateDisplayName(displayName);
    final userModel = await _saveUserToFirestore(userCredential.user!,
        displayName: displayName);
    await FcmService.onUserLoggedIn(); // сохраняем FCM-токен
    return userModel;
  }

  /// Вход по email
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth
        .signInWithEmailAndPassword(email: email, password: password)
        .timeout(
      _timeout,
      onTimeout: () =>
          throw Exception('Превышено время ожидания. Проверь подключение'),
    );
    final userModel = await _getOrCreateUser(userCredential.user!);
    await FcmService.onUserLoggedIn(); // сохраняем FCM-токен
    return userModel;
  }

  /// Сброс пароля
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email).timeout(
      _timeout,
      onTimeout: () =>
          throw Exception('Превышено время ожидания. Проверь подключение'),
    );
  }

  /// Выход
  Future<void> signOut() async {
    await FcmService.onUserLoggedOut(); // удаляем FCM-токен перед выходом
    await GoogleSignIn(scopes: ['email', 'profile']).signOut();
    await _auth.signOut();
  }

  /// Получить данные пользователя из Firestore
  Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user == null) return null;

    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get()
        .timeout(
      _timeout,
      onTimeout: () =>
          throw Exception('Не удалось загрузить данные. Проверь подключение'),
    );

    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Future<UserModel> _saveUserToFirestore(User user,
      {String? displayName}) async {
    final ref = _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid);

    final doc = await ref.get();
    if (doc.exists) return UserModel.fromMap(doc.data()!);

    final isAdmin = user.email == AppConstants.adminEmail;
    final userModel = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: displayName ?? user.displayName ?? 'Пользователь',
      avatarUrl: user.photoURL,
      isAdmin: isAdmin,
      createdAt: DateTime.now(),
    );

    await ref.set(userModel.toMap());
    return userModel;
  }

  Future<UserModel> _getOrCreateUser(User user) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();

    if (doc.exists) return UserModel.fromMap(doc.data()!);
    return _saveUserToFirestore(user);
  }
}
