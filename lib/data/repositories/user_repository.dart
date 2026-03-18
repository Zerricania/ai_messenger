import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../models/character_model.dart';
import '../../core/constants.dart';

class UserRepository {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  /// Получить данные пользователя
  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  /// Обновить отображаемое имя
  Future<void> updateDisplayName(String uid, String displayName) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'displayName': displayName});
  }

  /// Загрузить аватарку и сохранить ссылку
  Future<String> uploadAvatar(String uid, File file) async {
    final ref = _storage.ref('${AppConstants.avatarsPath}/$uid.jpg');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'avatarUrl': url});
    return url;
  }

  /// Загрузить баннер и сохранить ссылку
  Future<String> uploadBanner(String uid, File file) async {
    final ref = _storage.ref('${AppConstants.bannersPath}/$uid.jpg');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'bannerUrl': url});
    return url;
  }

  // ─── Персонажи пользователя ─────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _charactersRef(String uid) =>
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(AppConstants.charactersCollection);

  /// Сохранить нового персонажа
  Future<void> saveCharacter(String uid, CharacterModel character) async {
    await _charactersRef(uid).doc(character.id).set(character.toMap());
  }

  /// Загрузить персонажей пользователя
  Future<List<CharacterModel>> getUserCharacters(String uid) async {
    final snapshot = await _charactersRef(uid).get();
    return snapshot.docs
        .map((doc) => CharacterModel.fromMap(doc.data()))
        .toList();
  }

  /// Удалить персонажа
  Future<void> deleteCharacter(String uid, String characterId) async {
    await _charactersRef(uid).doc(characterId).delete();
  }

  /// Загрузить аватарку персонажа
  Future<String> uploadCharacterAvatar(
    String uid,
    String characterId,
    File file,
  ) async {
    final ref = _storage
        .ref('${AppConstants.characterAvatarsPath}/$uid/$characterId.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // ─── Для админа — все пользователи ─────────────────────────────────────────

  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .toList();
  }
}
