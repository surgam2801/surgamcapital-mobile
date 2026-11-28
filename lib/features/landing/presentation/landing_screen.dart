import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_brand.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_shell.dart';
import '../../education/data/mock_education_repository.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    final repository = ref.watch(educationRepositoryProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const AppBrand(compact: true),
        actions: [
          if (MediaQuery.sizeOf(context).width >= 640) ...[
            TextButton(
              onPressed: () => context.push(AppRoutes.education),
              child: const Text('Learn'),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.schemeDiscovery),
              child: const Text('Explore funds'),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.calculators),
              child: const Text('Goals'),
            ),
          ],
          TextButton(
            onPressed: () => context.push(AppRoutes.login),
            child: const Text('Login'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeroSection(),
                SizedBox(height: isMobile ? 10 : 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20),
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    children: [
                      _TrustPoint(
                        icon: Icons.search_rounded,
                        label: 'Explore without an account',
                      ),
                      _TrustPoint(
                        icon: Icons.event_note_outlined,
                        label: 'See the NAV date and source',
                      ),
                      _TrustPoint(
                        icon: Icons.school_outlined,
                        label: 'Learn at your own pace',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isMobile ? 18 : 24),
                _Section(
                  title: 'Learn Before You Invest',
                  child: FutureBuilder(
                    future: repository.getArticles(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final articles = snapshot.data ?? const [];
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
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisSpacing: isMobile ? 10 : 12,
                                  crossAxisSpacing: isMobile ? 10 : 12,
                                  childAspectRatio: columns == 1 ? 1.5 : 1.3,
                                ),
                            itemCount: articles.length,
                            itemBuilder: (_, index) {
                              final article = articles[index];
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        article.icon,
                                        color: AppColors.blue,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        article.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
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
                                      TextButton(
                                        onPressed: () => context.push(
                                          '/education/${article.slug}',
                                        ),
                                        child: const Text('Read More'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                const _Section(
                  title: 'Why Surgam Capital',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _InfoCard(
                        icon: Icons.person_outline,
                        title: 'Investor-focused',
                        body:
                            'Clear paths designed around investor understanding.',
                      ),
                      _InfoCard(
                        icon: Icons.visibility_outlined,
                        title: 'Transparent information',
                        body:
                            'Educational content that distinguishes guidance from execution.',
                      ),
                      _InfoCard(
                        icon: Icons.devices_outlined,
                        title: 'Simple digital experience',
                        body:
                            'A focused interface for learning and account access.',
                      ),
                      _InfoCard(
                        icon: Icons.menu_book_outlined,
                        title: 'Educational resources',
                        body:
                            'Plain-language articles for first-time mutual fund investors.',
                      ),
                    ],
                  ),
                ),
                _RiskFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    return Container(
      margin: EdgeInsets.fromLTRB(
        isMobile ? 16 : 20,
        isMobile ? 16 : 20,
        isMobile ? 16 : 20,
        0,
      ),
      padding: EdgeInsets.all(isMobile ? 20 : 36),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Invest with Clarity.\nGrow with Confidence.',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontSize: isMobile
                      ? 26
                      : isWide
                      ? 36
                      : 28,
                  height: isMobile ? 1.1 : 1.15,
                ),
              ),
              SizedBox(height: isMobile ? 10 : 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550),
                child: Text(
                  'Explore mutual funds, understand your options and take informed steps towards your financial goals with Surgam Capital.',
                  style: TextStyle(
                    color: Color(0xFFDCE5EF),
                    fontSize: isMobile ? 15 : 16,
                    height: isMobile ? 1.4 : 1.6,
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 16 : 22),
              Wrap(
                spacing: isMobile ? 8 : 12,
                runSpacing: isMobile ? 8 : 12,
                children: [
                  SizedBox(
                    width: isWide ? 180 : 190,
                    child: PrimaryButton(
                      label: 'Get Started',
                      onPressed: () => context.push(AppRoutes.registration),
                    ),
                  ),
                  SizedBox(
                    width: isWide ? 210 : 230,
                    child: OutlinedButton(
                      onPressed: () => context.push(AppRoutes.schemeDiscovery),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                      ),
                      child: const Text('Explore Mutual Funds'),
                    ),
                  ),
                  SizedBox(
                    width: isWide ? 180 : 190,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(AppRoutes.calculators),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFB5D9CE)),
                      ),
                      icon: const Icon(Icons.calculate_outlined),
                      label: const Text('Goals'),
                    ),
                  ),
                ],
              ),
            ],
          );
          if (isWide) {
            return Row(
              children: [
                Expanded(child: content),
                const SizedBox(width: 28),
                Expanded(
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D3A54),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          right: 24,
                          top: 24,
                          child: Icon(
                            Icons.auto_graph_rounded,
                            color: AppColors.teal.withValues(alpha: .24),
                            size: 150,
                          ),
                        ),
                        const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.account_balance_rounded,
                              size: 42,
                              color: AppColors.teal,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Research. Learn. Decide.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Clear information for every step.',
                              style: TextStyle(
                                color: Color(0xFFDCE5EF),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return content;
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 20,
        isMobile ? 24 : 36,
        isMobile ? 16 : 20,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeading(title: title),
          child,
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.teal, size: 30),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              body,
              style: const TextStyle(
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    return Container(
      margin: EdgeInsets.only(top: isMobile ? 24 : 36),
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 20,
        isMobile ? 18 : 24,
        isMobile ? 16 : 20,
        isMobile ? 16 : 20,
      ),
      color: AppColors.navy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mutual fund investments are subject to market risks. Read all scheme-related documents carefully before investing.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Wrap(
            spacing: isMobile ? 12 : 16,
            runSpacing: isMobile ? 6 : 8,
            children: [
              _FooterLink(label: 'About Us', route: AppRoutes.about),
              _FooterLink(label: 'Contact Us', route: AppRoutes.contact),
              _FooterLink(label: 'Privacy Policy', route: AppRoutes.privacy),
              _FooterLink(
                label: 'Terms and Conditions',
                route: AppRoutes.terms,
              ),
              _FooterLink(label: 'Risk Disclosure', route: AppRoutes.risk),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          const Text(
            '© 2026 Surgam Capital',
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.route});

  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.push(route),
      style: TextButton.styleFrom(foregroundColor: Colors.white),
      child: Text(label),
    );
  }
}

class _TrustPoint extends StatelessWidget {
  const _TrustPoint({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: AppColors.blue),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}
