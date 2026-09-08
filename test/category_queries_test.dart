import 'package:flutter_test/flutter_test.dart';
import 'package:sesh/features/news/domain/category_queries.dart';
import 'package:sesh/core/network/news_api.dart';

void main() {
  test('maps product categories to NewsAPI queries', () {
    expect(SeshCategoryQueryMapper.queryFor('Archaeology'), 'archaeology AND Egypt');
    expect(SeshCategoryQueryMapper.queryFor('Unknown'), 'ancient Egypt');
  });

  test('offline repository stops after its local first page', () async {
    final repository = NewsApiRepository();
    expect((await repository.search('ancient Egypt', page: 1)).isNotEmpty, isTrue);
    expect(await repository.search('ancient Egypt', page: 2), isEmpty);
  });
}
