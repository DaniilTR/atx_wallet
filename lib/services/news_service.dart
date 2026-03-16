import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

class NewsFeed {
  const NewsFeed({
    required this.source,
    required this.fetchedAt,
    required this.items,
  });

  final String source;
  final DateTime fetchedAt;
  final List<NewsItem> items;

  factory NewsFeed.fromJson(Map<String, dynamic> json) {
    final source = (json['source'] as String?) ?? 'unknown';
    final fetchedAtIso = json['fetchedAtIso'];
    final fetchedAt =
        DateTime.tryParse('$fetchedAtIso') ?? DateTime.now().toUtc();

    final rawItems = json['items'];
    final items = <NewsItem>[];
    if (rawItems is List) {
      for (final raw in rawItems) {
        if (raw is Map<String, dynamic>) {
          items.add(NewsItem.fromJson(raw));
        }
      }
    }

    return NewsFeed(source: source, fetchedAt: fetchedAt, items: items);
  }
}

class NewsItem {
  const NewsItem({
    required this.id,
    required this.title,
    required this.url,
    required this.publishedAt,
    required this.summary,
  });

  final String id;
  final String title;
  final String url;
  final DateTime? publishedAt;
  final String summary;

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?) ?? '';
    final title = (json['title'] as String?) ?? '';
    final url = (json['url'] as String?) ?? '';
    final publishedAtIso = json['publishedAtIso'];
    final publishedAt = publishedAtIso == null
        ? null
        : DateTime.tryParse('$publishedAtIso');
    final summary = (json['summary'] as String?) ?? '';

    return NewsItem(
      id: id,
      title: title,
      url: url,
      publishedAt: publishedAt,
      summary: summary,
    );
  }
}

class NewsService {
  NewsService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<NewsFeed> fetchCointelegraph({int limit = 15}) async {
    final base = Uri.parse(kCoinGeckoBaseUrl);
    final uri = base.replace(
      path: '/api/news/cointelegraph',
      queryParameters: <String, String>{'limit': '$limit'},
    );

    final res = await _httpClient.get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'User-Agent': 'atx_wallet/1.0',
      },
    );

    if (res.statusCode != 200) {
      throw StateError('Ошибка API новостей (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Неожиданный формат ответа API новостей');
    }

    return NewsFeed.fromJson(decoded);
  }

  void dispose() {
    _httpClient.close();
  }
}
