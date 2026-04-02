import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

class AiAssistantService {
  AiAssistantService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<String> sendMessage(String message) async {
    if (!kEnableAiAssistant) {
      throw StateError(
        'AI ассистент отключён. Он в данный момент находиться в разработке и может быть включён в будущих версиях. Следите за обновлениями.',
      );
    }
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      throw StateError('Пустое сообщение нельзя отправить.');
    }

    final endpoint = kAiAssistantEndpoint.trim();
    if (endpoint.isEmpty) {
      throw StateError(
        'AI ассистент отключён. Он в данный момент находиться в разработке и может быть включён в будущих версиях. Следите за обновлениями.',
      );
    }

    final uri = Uri.parse(endpoint);
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };

    http.Response res;
    try {
      res = await _httpClient
          .post(uri, headers: headers, body: jsonEncode({'message': trimmed}))
          .timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw StateError('Сервер не ответил вовремя. Повторите попытку.');
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final body = res.body.trim();
      final details = body.isEmpty ? 'empty body' : body;
      throw StateError('Ошибка сервера (${res.statusCode}): $details');
    }

    final body = res.body.trim();
    if (body.isEmpty) {
      throw StateError('Сервер вернул пустой ответ.');
    }

    try {
      final decoded = jsonDecode(body);
      final text = _extractText(decoded);
      if (text != null && text.isNotEmpty) {
        return text;
      }
      return body;
    } catch (_) {
      return body;
    }
  }

  String? _extractText(dynamic data) {
    if (data == null) return null;
    if (data is String) return data.trim();

    if (data is Map) {
      const keys = <String>[
        'reply',
        'response',
        'message',
        'text',
        'answer',
        'content',
      ];

      for (final key in keys) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }

      final nestedData = data['data'];
      final nestedText = _extractText(nestedData);
      if (nestedText != null && nestedText.isNotEmpty) {
        return nestedText;
      }

      final choices = data['choices'];
      if (choices is List && choices.isNotEmpty) {
        final first = choices.first;
        final choiceText = _extractText(first);
        if (choiceText != null && choiceText.isNotEmpty) {
          return choiceText;
        }
      }
    }

    if (data is List && data.isNotEmpty) {
      final firstText = _extractText(data.first);
      if (firstText != null && firstText.isNotEmpty) {
        return firstText;
      }
    }

    return null;
  }

  void dispose() {
    _httpClient.close();
  }
}
