import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/app_shell.dart';
import '../data/mock_education_repository.dart';

class EducationListingScreen extends ConsumerWidget {
  const EducationListingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(educationRepositoryProvider);
    return AppShell(
      selectedNavigationIndex: -1,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppPageHeader(
            eyebrow: 'Investor learning',
            title: 'Mutual fund education',
            subtitle:
                'Build your understanding before making investment decisions.',
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.schemeDiscovery),
              icon: const Icon(Icons.search),
              label: const Text('Explore mutual fund schemes'),
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder(
            future: repository.getArticles(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final articles = snapshot.data ?? [];
              if (articles.isEmpty) {
                return const Center(
                  child: Text('No educational articles available.'),
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 800
                      ? 3
                      : constraints.maxWidth > 480
                      ? 2
                      : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: columns == 1 ? 1.65 : 1.3,
                    ),
                    itemCount: articles.length,
                    itemBuilder: (_, index) {
                      final article = articles[index];
                      return Card(
                        child: InkWell(
                          onTap: () =>
                              context.push('/education/${article.slug}'),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(article.icon, color: AppColors.blue),
                                const SizedBox(height: 8),
                                Text(
                                  article.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Expanded(
                                  child: Text(
                                    article.summary,
                                    style: const TextStyle(
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ),
                                const Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Text(
                                    'Read More',
                                    style: TextStyle(
                                      color: AppColors.blue,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
