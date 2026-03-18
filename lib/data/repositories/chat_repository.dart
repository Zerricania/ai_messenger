import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/saved_message_model.dart';
import '../../core/constants.dart';

class ChatRepository {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _messagesRef(
    String uid,
    String characterId,
  ) =>
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(AppConstants.chatsCollection)
          .doc(characterId)
          .collection(AppConstants.messagesCollection);

  /// Сохранить сообщение
  Future<void> saveMessage(
    String uid,
    String characterId,
    MessageModel message,
  ) async {
    await _messagesRef(uid, characterId).doc(message.id).set(message.toMap());
  }

  /// Загрузить историю чата.
  Future<List<MessageModel>> getHistory(
    String uid,
    String characterId, {
    bool includeDeleted = false,
  }) async {
    final snapshot = await _messagesRef(uid, characterId)
        .orderBy('timestamp', descending: false)
        .get();

    final all = snapshot.docs
        .map((doc) => MessageModel.fromMap(doc.data()))
        .toList();

    if (includeDeleted) return all;
    return all.where((m) => !m.isDeleted).toList();
  }

  /// Мягкое удаление одного сообщения
  Future<void> deleteMessage(
    String uid,
    String characterId,
    String messageId,
  ) async {
    await _messagesRef(uid, characterId)
        .doc(messageId)
        .update({'isDeleted': true});
  }

  /// Поставить реакцию (1 = лайк, -1 = дизлайк)
  Future<void> setReaction(
    String uid,
    String characterId,
    String messageId,
    int reaction,
  ) async {
    await _messagesRef(uid, characterId)
        .doc(messageId)
        .update({'reaction': reaction});
  }

  /// Очистить историю (мягкое удаление всех сообщений)
  Future<void> clearHistory(String uid, String characterId) async {
    final snapshot = await _messagesRef(uid, characterId).get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isDeleted': true});
    }
    await batch.commit();
  }

  // ─── Все чаты пользователя (для админки) ──────────────────────────────────

  /// Список всех characterId.
  /// Firestore не возвращает пустые документы-контейнеры через .get(),
  /// поэтому ищем через первое сообщение в каждом известном чате.
  /// Путь: users/{uid}/chats/{characterId}/messages — читаем сообщения
  /// и извлекаем уникальные characterId из пути документа.
  Future<List<String>> getChatIds(String uid) async {
    final Set<String> characterIds = {};

    // Получаем все сообщения пользователя через collectionGroup
    // Путь: users/{uid}/chats/{characterId}/messages/{msgId}
    final snapshot = await _firestore
        .collectionGroup(AppConstants.messagesCollection)
        .limit(500)
        .get();

    for (final doc in snapshot.docs) {
      // Полный путь: users/{uid}/chats/{characterId}/messages/{msgId}
      final segments = doc.reference.path.split('/');
      // segments[0]=users, [1]=uid, [2]=chats, [3]=characterId, [4]=messages, [5]=msgId
      if (segments.length == 6 &&
          segments[0] == AppConstants.usersCollection &&
          segments[1] == uid &&
          segments[2] == AppConstants.chatsCollection) {
        characterIds.add(segments[3]);
      }
    }

    return characterIds.toList();
  }

  // ─── Избранные сообщения ───────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _savedRef(String uid) =>
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(AppConstants.savedMessagesCollection);

  Future<void> saveToFavorites(String uid, SavedMessageModel saved) async {
    await _savedRef(uid).doc(saved.id).set(saved.toMap());
  }

  Future<void> removeFromFavorites(String uid, String savedId) async {
    await _savedRef(uid).doc(savedId).delete();
  }

  Future<List<SavedMessageModel>> getSavedMessages(String uid) async {
    final snapshot = await _savedRef(uid)
        .orderBy('savedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => SavedMessageModel.fromMap(doc.data()))
        .toList();
  }
}
