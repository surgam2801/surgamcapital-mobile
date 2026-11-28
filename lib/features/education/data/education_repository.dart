import '../domain/article.dart';

abstract class EducationRepository {
  Future<List<EducationArticle>> getArticles();
  Future<EducationArticle?> getArticle(String slug);
}
