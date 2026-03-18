/// Все константы приложения в одном месте
class AppConstants {
  AppConstants._();

  // AI API — легко сменить провайдера, меняя только эти строки
  static const String aiBaseUrl = 'https://api.groq.com/openai/v1';
  static const String aiModel = 'llama-3.3-70b-versatile';
  static const String aiEnvKey = 'GROQ_API_KEY';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String charactersCollection = 'characters';
  static const String savedMessagesCollection = 'saved_messages';

  // Storage paths
  static const String avatarsPath = 'avatars';
  static const String bannersPath = 'banners';
  static const String characterAvatarsPath = 'character_avatars';

  // Admin
  static const String adminEmail = 'aztoon.lab@gmail.com';
}
