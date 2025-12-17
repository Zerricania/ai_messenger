import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqService {
  static final _dio = Dio();

  static Future<Stream<String>> chatStream({
    required String systemPrompt,
    required List<Map<String, String>> history,
  }) async {
    final apiKey = dotenv.env['GROQ_API_KEY finded']?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GROQ_API_KEY не найден');
    }

    final cleanHistory = history
        .where((m) => m['content']?.trim().isNotEmpty ?? false)
        .toList();

    final messages = [
      {"role": "system", "content": systemPrompt},
      ...cleanHistory,
    ];

    final response = await _dio.post(
      'https://api.groq.com/openai/v1/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.stream,
      ),
      data: {
        "model": "llama-3.3-70b-versatile",
        "messages": messages,
        "stream": true,
        "temperature": 0.8,
        "max_tokens": 1024,
      },
    );

    final ResponseBody responseBody = response.data;

    // Декодируем байты в строки корректно
    final utf8Stream = utf8.decoder.bind(responseBody.stream);

    final controller = StreamController<String>();

    // Парсим SSE-стрим: ищем строки, начинающиеся с "data: "
    utf8Stream.listen((chunk) {
      // chunk может содержать несколько строк
      final lines = chunk.split('\n');

      for (final line in lines) {
        if (!line.startsWith('data: ')) continue;
        final payload = line.substring(6).trim();
        if (payload == '[DONE]') {
          controller.close();
          return;
        }
        if (payload.isEmpty) continue;

        try {
          final data = jsonDecode(payload);
          final text = data['choices']?[0]?['delta']?['content'];
          if (text is String && text.isNotEmpty) {
            controller.add(text);
          }
        } catch (e) {
          // Игнорируем ошибки парсинга отдельных chunk'ов
        }
      }
    }, onError: (e) {
      if (!controller.isClosed) controller.addError(e);
    }, onDone: () {
      if (!controller.isClosed) controller.close();
    });

    return controller.stream;
  }

  static Future<String> chatNoStream({
    required String systemPrompt,
    required List<Map<String, String>> history,
  }) async {
    final apiKey = dotenv.env['GROQ_API_KEY']?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GROQ_API_KEY не найден');
    }

    final response = await _dio.post(
      'https://api.groq.com/openai/v1/chat/completions',
      options: Options(headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      }),
      data: {
        "model": "llama-3.3-70b-versatile",
        "messages": [
          {"role": "system", "content": systemPrompt},
          ...history,
        ],
        "temperature": 0.8,
        "max_tokens": 1024,
      },
    );

    final text = response.data['choices']?[0]?['message']?['content'] as String?;
    return text?.trim() ?? '[пустой ответ]';
  }
}