import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/constants.dart';

/// Абстрактный AI сервис.
/// Чтобы сменить провайдера — меняй только константы в AppConstants
/// и при необходимости формат запроса в _buildRequest().
class AiService {
  AiService._();

  static final _dio = Dio();

  /// Отправляет историю сообщений и возвращает полный ответ AI.
  static Future<String> sendMessage({
    required String systemPrompt,
    required List<Map<String, String>> history,
  }) async {
    final apiKey = dotenv.env[AppConstants.aiEnvKey]?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API ключ не найден. Проверь файл .env');
    }

    try {
      final response = await _dio.post(
        '${AppConstants.aiBaseUrl}/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: _buildRequest(systemPrompt, history),
      );

      final text = response.data['choices']?[0]?['message']?['content']
          as String?;
      return text?.trim() ?? '[Пустой ответ]';
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Неверный API ключ');
      } else if (e.response?.statusCode == 429) {
        throw Exception('Превышен лимит запросов. Попробуй позже');
      }
      throw Exception('Ошибка сети: ${e.message}');
    }
  }

  static Map<String, dynamic> _buildRequest(
    String systemPrompt,
    List<Map<String, String>> history,
  ) {
    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ...history.where((m) => m['content']?.trim().isNotEmpty ?? false),
    ];

    return {
      'model': AppConstants.aiModel,
      'messages': messages,
      'temperature': 0.8,
      'max_tokens': 1024,
    };
  }
}
