import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/news/domain/models.dart';
import '../../features/news/domain/category_queries.dart';

class NewsApiRepository {
  NewsApiRepository({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  final String apiKey = const String.fromEnvironment('NEWS_API_KEY');

  Future<List<NewsArticle>> search(
    String query, {
    int page = 1,
    String? sources,
    String language = 'en',
  }) async {
    if (apiKey.isEmpty) return _mock(query, page: page);
    final uri = Uri.https('newsapi.org', '/v2/everything', {
      'q': query,
      'language': language,
      'page': '$page',
      'pageSize': '20',
      'sortBy': 'publishedAt',
      if (sources != null && sources.isNotEmpty) 'sources': sources,
      'apiKey': apiKey,
    });
    final response = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw NewsApiException(response.statusCode);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ((data['articles'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>().map(NewsArticle.fromJson).toList();
  }

  Future<List<NewsSource>> getSources({String? category, String language = 'en'}) async {
    if (apiKey.isEmpty) return _mockSources;
    final uri = Uri.https('newsapi.org', '/v2/top-headlines/sources', {
      'language': language,
      if (category != null) 'category': category,
      'apiKey': apiKey,
    });
    final response = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) throw NewsApiException(response.statusCode);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ((data['sources'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(NewsSource.fromJson)
        .toList();
  }

  Future<List<NewsArticle>> category(String category, {int page = 1}) =>
      search(SeshCategoryQueryMapper.queryFor(category), page: page);

  List<NewsArticle> _mock(String query, {int page = 1}) {
    if (page > 1) return const [];
    return [
    NewsArticle(title: 'A new chapter in the story of Ancient Egypt', source: 'SESH Archive',
      description: 'Discover the people, places and ideas connected to $query.', category: 'Discovery'),
    const NewsArticle(title: 'What archaeology reveals about life along the Nile',
      source: 'National Geographic', description: 'Context for the discoveries making headlines today.'),
    const NewsArticle(title: 'The builders, scribes and rulers behind a living legacy',
      source: 'The Archive', description: 'A guided story through time.'),
    ];
  }

  static const _mockSources = [
    NewsSource(id: 'sesh-archive', name: 'SESH Archive', description: 'Context for the stories behind the headlines.'),
    NewsSource(id: 'national-geographic', name: 'National Geographic', description: 'Exploration, science and archaeology.'),
  ];
}

class NewsApiException implements Exception {
  const NewsApiException(this.statusCode);
  final int statusCode;

  String get message => switch (statusCode) {
        401 => 'The archive key is not configured.',
        403 => 'The archive access was denied.',
        429 => 'The archive is busy. Try again shortly.',
        _ => 'The archive is temporarily offline.',
      };

  @override
  String toString() => message;
}
