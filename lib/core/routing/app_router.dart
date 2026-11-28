import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/forgot_password_screen.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/otp_screen.dart';
import '../../features/authentication/presentation/reset_password_screen.dart';
import '../../features/authentication/application/auth_state.dart';
import '../../features/authentication/data/authentication_repository.dart';
import '../../features/authentication/data/token_storage.dart';
import '../../features/education/presentation/article_detail_screen.dart';
import '../../features/education/presentation/education_listing_screen.dart';
import '../../features/calculators/presentation/calculator_landing_screen.dart';
import '../../features/calculators/presentation/calculator_tool_screen.dart';
import '../../features/landing/presentation/landing_screen.dart';
import '../../features/mutual_funds/presentation/scheme_detail_screen.dart';
import '../../features/mutual_funds/presentation/scheme_discovery_screen.dart';
import '../../features/mutual_funds/presentation/scheme_comparison_screen.dart';
import '../../features/mutual_funds/presentation/watchlist_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/portfolio/presentation/portfolio_screen.dart';
import '../../features/profile/presentation/info_screen.dart';
import '../../features/registration/presentation/registration_screen.dart';
import '../../features/profile/presentation/investor_dashboard_screen.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.landing,
    redirect: (context, state) async {
      final path = state.uri.path;
      final isLanding = path == AppRoutes.landing;
      final protected =
          path == AppRoutes.dashboard ||
          path == AppRoutes.onboarding ||
          path == AppRoutes.watchlist ||
          path.startsWith(AppRoutes.portfolio);
      if (isLanding && ref.read(authenticatedProvider)) {
        return AppRoutes.portfolio;
      }
      if (isLanding && !ref.read(authenticatedProvider)) {
        try {
          final hasTokens = await ref.read(tokenStorageProvider).hasTokens();
          if (hasTokens) {
            ref.read(authenticatedProvider.notifier).authenticated();
            return AppRoutes.portfolio;
          }
        } catch (_) {
          return null;
        }
      }
      if (protected && !ref.read(authenticatedProvider)) {
        try {
          final hasTokens = await ref.read(tokenStorageProvider).hasTokens();
          if (hasTokens) {
            ref.read(authenticatedProvider.notifier).authenticated();
            return null;
          }
        } catch (_) {
          return AppRoutes.login;
        }
        return AppRoutes.login;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.landing,
        name: 'landing',
        builder: (_, _) => const LandingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        name: 'otp',
        builder: (_, state) => OtpScreen(
          challenge: state.extra is AuthChallenge
              ? state.extra! as AuthChallenge
              : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'reset-password',
        builder: (_, state) => ResetPasswordScreen(
          challenge: state.extra is AuthChallenge
              ? state.extra! as AuthChallenge
              : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.registration,
        name: 'register',
        builder: (_, _) => const RegistrationScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'investor-dashboard',
        builder: (_, _) => const InvestorDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'investor-onboarding',
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.portfolio,
        name: 'investor-portfolio',
        builder: (_, _) => const PortfolioScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.portfolioHolding}/:schemeId',
        name: 'portfolio-holding',
        builder: (_, state) => PortfolioFeatureScreen(
          title: 'Holding details',
          description:
              'Current units, confirmed allotments, purchase history and returns will appear here when the portfolio service is connected. Invest-more and redemption actions are not enabled until their order APIs and investor eligibility checks are available.',
          icon: Icons.receipt_long_outlined,
          contextLabel: 'Scheme reference: ${state.pathParameters['schemeId']}',
          fields: const [
            'Scheme and AMC',
            'Category',
            'Invested amount',
            'Current value',
            'Units held',
            'Latest NAV and NAV date',
            'Absolute return',
            'XIRR',
            'Purchase history',
            'Transaction history',
          ],
          schemeId: state.pathParameters['schemeId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.portfolioSips,
        name: 'investor-sips',
        builder: (_, _) => const PortfolioFeatureScreen(
          title: 'My SIPs',
          description:
              'SIP schedules and mandate status are not available until verified SIP records are synchronized.',
          icon: Icons.autorenew_rounded,
          contextLabel: 'No SIP data has been synchronized.',
          sections: [
            'Active SIPs',
            'Upcoming instalments',
            'Completed SIPs',
            'Paused SIPs',
            'Failed instalments',
            'Cancelled SIPs',
          ],
          fields: [
            'Scheme',
            'Instalment amount',
            'Frequency',
            'Next instalment date',
            'Mandate status',
          ],
        ),
      ),
      GoRoute(
        path: AppRoutes.portfolioTransactions,
        name: 'portfolio-transactions',
        builder: (_, _) => const PortfolioFeatureScreen(
          title: 'Transaction history',
          description:
              'Purchases, redemptions, switches and other confirmed transactions will appear after RTA or exchange records are integrated.',
          icon: Icons.swap_horiz_rounded,
          contextLabel: 'No confirmed transactions are available.',
          sections: [
            'Purchases',
            'Redemptions',
            'Switches',
            'Dividends',
            'Other transactions',
          ],
          fields: ['Transaction date', 'Scheme', 'Amount', 'Units', 'Status'],
        ),
      ),
      GoRoute(
        path: AppRoutes.portfolioOrders,
        name: 'portfolio-orders',
        builder: (_, _) => const PortfolioFeatureScreen(
          title: 'Order history',
          description:
              'Order status requires the order lifecycle from the transaction platform. An acknowledgement alone does not confirm allotment.',
          icon: Icons.receipt_long_outlined,
          contextLabel: 'No order records are available.',
          sections: ['Pending', 'Processing', 'Successful', 'Failed'],
          fields: ['Order date', 'Scheme', 'Amount', 'Units', 'Order status'],
        ),
      ),
      GoRoute(
        path: AppRoutes.portfolioAllocation,
        name: 'portfolio-allocation',
        builder: (_, _) => const PortfolioFeatureScreen(
          title: 'Portfolio allocation',
          description:
              'Category allocation will be calculated from synchronized holdings and current units. No allocation is shown until those records are available.',
          icon: Icons.donut_large_rounded,
          contextLabel: 'Allocation data is not synchronized.',
          sections: ['Equity', 'Debt', 'Hybrid', 'Solution-oriented', 'Other'],
          fields: ['Category', 'Current value', 'Portfolio percentage'],
        ),
      ),
      GoRoute(
        path: AppRoutes.schemeDiscovery,
        name: 'scheme-discovery',
        builder: (_, _) => const SchemeDiscoveryScreen(),
      ),
      GoRoute(
        path: AppRoutes.calculators,
        name: 'calculators',
        builder: (_, _) => const CalculatorLandingScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.calculator}/:calculatorId',
        name: 'calculator-tool',
        builder: (_, state) => CalculatorToolScreen(
          calculatorId: state.pathParameters['calculatorId']!,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.schemeDetail}/:schemeId',
        name: 'scheme-detail',
        builder: (_, state) =>
            SchemeDetailScreen(schemeId: state.pathParameters['schemeId']!),
      ),
      GoRoute(
        path: AppRoutes.watchlist,
        name: 'scheme-watchlist',
        builder: (_, _) => const WatchlistScreen(),
      ),
      GoRoute(
        path: AppRoutes.compareFunds,
        name: 'scheme-comparison',
        builder: (_, _) => const SchemeComparisonScreen(),
      ),
      GoRoute(
        path: AppRoutes.education,
        name: 'education',
        builder: (_, _) => const EducationListingScreen(),
      ),
      GoRoute(
        path: AppRoutes.article,
        name: 'article',
        builder: (_, state) =>
            ArticleDetailScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: AppRoutes.about,
        name: 'about',
        builder: (_, _) => const InfoScreen(
          title: 'About Us',
          content:
              'Surgam Capital is designed to help investors learn about mutual funds and navigate digital investment services with clarity.',
        ),
      ),
      GoRoute(
        path: AppRoutes.contact,
        name: 'contact',
        builder: (_, _) => const InfoScreen(
          title: 'Contact Us',
          content: 'Contact information will be added before public launch.',
        ),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        name: 'privacy',
        builder: (_, _) => const InfoScreen(
          title: 'Privacy Policy',
          content:
              'This placeholder describes where the privacy policy will appear. Production release requires a reviewed policy covering data collection, retention and user rights.',
        ),
      ),
      GoRoute(
        path: AppRoutes.terms,
        name: 'terms',
        builder: (_, _) => const InfoScreen(
          title: 'Terms and Conditions',
          content:
              'This placeholder describes the terms of use for Surgam Capital. Final terms should be reviewed before public release.',
        ),
      ),
      GoRoute(
        path: AppRoutes.risk,
        name: 'risk',
        builder: (_, _) => const InfoScreen(
          title: 'Risk Disclosure',
          content:
              'Mutual fund investments are subject to market risks. Read all scheme-related documents carefully before investing.',
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('The requested page could not be found.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.landing),
              child: const Text('Back to home'),
            ),
          ],
        ),
      ),
    ),
  );
  ref.listen(authenticatedProvider, (previous, next) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});
