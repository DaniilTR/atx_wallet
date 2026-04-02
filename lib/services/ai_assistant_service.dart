import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import 'config.dart';

Uri _normalizeAiEndpoint(Uri base) {
  // Нормализуем endpoint так, чтобы не было редиректов на слэшах.
  // Preflight (OPTIONS) в браузере НЕ может следовать редиректам.
  final p = base.path;

  // Если задан только origin — используем дефолтный путь.
  if (p.isEmpty || p == '/') {
    return base.replace(path: '/api/ai/v1/chat');
  }

  // Если указали прокси-корень, добавляем v1/chat.
  if (p == '/api/ai' || p == '/api/ai/') {
    return base.replace(path: '/api/ai/v1/chat');
  }

  // Если указали только /v1, добавляем /chat.
  if (p.endsWith('/v1') || p.endsWith('/v1/')) {
    final normalized = p.endsWith('/') ? p.substring(0, p.length - 1) : p;
    return base.replace(path: '$normalized/chat');
  }

  // Если указали /chat/ — убираем хвостовой слэш.
  if (p.endsWith('/chat/')) {
    return base.replace(path: p.substring(0, p.length - 1));
  }

  // Иначе считаем, что путь уже полный.
  return base;
}

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

    final parsed = Uri.tryParse(endpoint);
    if (parsed == null || !parsed.hasScheme) {
      throw StateError('Некорректный AI endpoint: $endpoint');
    }

    final uri = _normalizeAiEndpoint(parsed);
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };

    final token = kAiAssistantBearerToken.trim();
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    http.Response res;
    try {
      res = await _httpClient
          .post(uri, headers: headers, body: jsonEncode({'message': trimmed}))
          .timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw StateError('Сервер не ответил вовремя. Повторите попытку.');
    } on http.ClientException catch (e) {
      // На Flutter Web типовая причина — CORS (браузер блокирует запрос).
      if (kIsWeb) {
        throw StateError(
          'AI недоступен в Web из-за CORS браузера. '
          'Откройте приложение с того же домена, что и API, '
          'или настройте CORS на API. Детали: ${e.message}',
        );
      }
      rethrow;
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw StateError(
        'AI сервер требует авторизацию. '
        'Задайте `AI_ASSISTANT_BEARER_TOKEN` через --dart-define или отключите AI.',
      );
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
