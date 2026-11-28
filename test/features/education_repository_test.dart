import 'package:flutter_test/flutter_test.dart';
import 'package:surgam_capital/features/education/data/mock_education_repository.dart';

void main() {
  test('mock education repository returns six articles', () async {
    final repository = MockEducationRepository();
    final articles = await repository.getArticles();
    expect(articles, hasLength(6));
  });

  test('mock education repository retrieves an article by slug', () async {
    final repository = MockEducationRepository();
    final article = await repository.getArticle('understanding-sip');
    expect(article?.title, 'Understanding SIP');
  });
}
