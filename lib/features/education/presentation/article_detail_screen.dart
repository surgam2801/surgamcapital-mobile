import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';
import '../data/mock_education_repository.dart';

class ArticleDetailScreen extends ConsumerWidget {
  const ArticleDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    final repository = ref.watch(educationRepositoryProvider);
    return AppShell(
      selectedNavigationIndex: -1,
      body: FutureBuilder(
        future: repository.getArticle(slug),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final article = snapshot.data;
          if (article == null) {
            return Column(
              children: [
                const Text('Article not found'),
                TextButton(
                  onPressed: () => context.go('/education'),
                  child: const Text('Back to education'),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
              SizedBox(height: isMobile ? 16 : 20),
              Icon(article.icon, size: 44, color: AppColors.blue),
              SizedBox(height: isMobile ? 10 : 12),
              Text(
                article.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: isMobile ? 6 : 8),
              Text(
                article.summary,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              SizedBox(height: isMobile ? 18 : 24),
              for (final section in article.sections) ...[
                Text(
                  section.heading,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: isMobile ? 6 : 8),
                Text(
                  section.body,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(height: isMobile ? 16 : 20),
              ],
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE7C98C)),
                ),
                child: const Text(
                  'This article is educational only and does not provide personalized investment advice.',
                  style: TextStyle(color: AppColors.warning),
                ),
              ),
              SizedBox(height: isMobile ? 16 : 20),
              TextButton(
                onPressed: () => context.go('/education'),
                child: const Text('View related articles'),
              ),
            ],
          );
        },
      ),
    );
  }
}
