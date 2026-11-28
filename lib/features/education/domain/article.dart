import 'package:flutter/material.dart';

class ArticleSection {
  const ArticleSection({required this.heading, required this.body});

  final String heading;
  final String body;
}

class EducationArticle {
  const EducationArticle({
    required this.slug,
    required this.title,
    required this.summary,
    required this.icon,
    required this.sections,
  });

  final String slug;
  final String title;
  final String summary;
  final IconData icon;
  final List<ArticleSection> sections;
}
