import 'package:flutter_test/flutter_test.dart';
import 'package:sesh/features/news/domain/models.dart';

void main() {
  test('NewsArticle safely parses missing NewsAPI fields', () {
    final article = NewsArticle.fromJson({'title': 'A discovery', 'source': <String, dynamic>{}});
    expect(article.title, 'A discovery');
    expect(article.source, 'Unknown source');
    expect(article.description, isNull);
  });
}
