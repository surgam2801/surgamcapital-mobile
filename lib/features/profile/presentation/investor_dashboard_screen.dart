import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_financial_widgets.dart';
import '../../authentication/application/auth_state.dart';
import '../../authentication/data/authentication_providers.dart';

class InvestorDashboardScreen extends ConsumerStatefulWidget {
  const InvestorDashboardScreen({super.key});

  @override
  ConsumerState<InvestorDashboardScreen> createState() =>
      _InvestorDashboardScreenState();
}

class _InvestorDashboardScreenState
    extends ConsumerState<InvestorDashboardScreen> {
  bool _loggingOut = false;

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    String? message;
    try {
      await ref.read(authenticationRepositoryProvider).logout();
    } on AppException catch (error) {
      message = error.message;
    } catch (_) {
      message = 'You have been signed out on this device.';
    } finally {
      await ref.read(authenticatedProvider.notifier).clear();
      if (mounted) {
        context.go(AppRoutes.landing);
        setState(() => _loggingOut = false);
        if (message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investor home'),
        actions: [
          TextButton(
            onPressed: _loggingOut ? null : _logout,
            child: Text(_loggingOut ? 'Signing out…' : 'Sign out'),
          ),
        ],
      ),
      body: AppAdaptiveBody(
        selectedIndex: 3,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppPageHeader(
                    eyebrow: 'Investor workspace',
                    title: 'Welcome to your investor home',
                    subtitle:
                        'A clear place to continue onboarding, explore schemes and revisit your research.',
                  ),
                  AppSpotlightPanel(
                    compact: true,
                    eyebrow: 'Your next step',
                    title: 'Build your investor profile',
                    description:
                        'Complete guided onboarding at your pace. Your progress is saved as you go.',
                    icon: Icons.account_balance_wallet_outlined,
                    trailing: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: () => context.push(AppRoutes.onboarding),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Start investor onboarding'),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFB5D9CE)),
                          ),
                          onPressed: () =>
                              context.push(AppRoutes.schemeDiscovery),
                          icon: const Icon(Icons.search_rounded),
                          label: const Text('Explore mutual funds'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 16),
                  const AppSectionHeading(
                    title: 'Explore your platform',
                    subtitle:
                        'Research and learning are available before investing services are enabled.',
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 760
                          ? 3
                          : constraints.maxWidth >= 420
                          ? 2
                          : 1;
                      return GridView.count(
                        crossAxisCount: columns,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: isMobile ? 12 : 16,
                        crossAxisSpacing: isMobile ? 12 : 16,
                        childAspectRatio: columns == 1 ? 2.5 : 1.3,
                        children: [
                          _DashboardAction(
                            icon: Icons.bookmark_border_rounded,
                            title: 'Your watchlist',
                            description:
                                'Return to the schemes you have saved for research.',
                            onTap: () => context.push(AppRoutes.watchlist),
                          ),
                          _DashboardAction(
                            icon: Icons.calculate_outlined,
                            title: 'Plan an investment',
                            description:
                                'Use free calculators to explore goal and SIP projections.',
                            onTap: () => context.push(AppRoutes.calculators),
                          ),
                          _DashboardAction(
                            icon: Icons.menu_book_outlined,
                            title: 'Learn the basics',
                            description:
                                'Build your understanding with plain-language education.',
                            onTap: () => context.push(AppRoutes.education),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: isMobile ? 16 : 20),
                  const Text(
                    'Research information is not personalised investment advice. KYC and account activation require authorised verification.',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardAction extends StatelessWidget {
  const _DashboardAction({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.blue, size: 26),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.blue,
              size: 20,
            ),
          ],
        ),
      ),
    ),
  );
}
