class NewsArticle {
  const NewsArticle({
    required this.title,
    required this.source,
    this.description,
    this.imageUrl,
    this.url,
    this.publishedAt,
    this.category = 'Archaeology',
  });
  final String title;
  final String source;
  final String? description;
  final String? imageUrl;
  final String? url;
  final DateTime? publishedAt;
  final String category;

  factory NewsArticle.fromJson(Map<String, dynamic> json) => NewsArticle(
    title: (json['title'] as String?) ?? 'Untitled discovery',
    source: ((json['source'] as Map?)?['name'] as String?) ?? 'Unknown source',
    description: json['description'] as String?,
    imageUrl: json['urlToImage'] as String?,
    url: json['url'] as String?,
    publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? ''),
  );
}

class NewsSource {
  const NewsSource({
    required this.id,
    required this.name,
    this.description,
    this.url,
    this.category,
    this.language,
    this.country,
  });

  final String id;
  final String name;
  final String? description;
  final String? url;
  final String? category;
  final String? language;
  final String? country;

  factory NewsSource.fromJson(Map<String, dynamic> json) => NewsSource(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? 'Unknown source',
        description: json['description'] as String?,
        url: json['url'] as String?,
        category: json['category'] as String?,
        language: json['language'] as String?,
        country: json['country'] as String?,
      );
}

class HistoricalPeriod {
  const HistoricalPeriod(this.name, this.years, this.color);
  final String name;
  final String years;
  final int color;
}

class Discovery {
  const Discovery(this.title, this.subtitle, this.icon);
  final String title;
  final String subtitle;
  final String icon;
}
