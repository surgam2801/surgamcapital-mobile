import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';
import 'calculator_tool_catalog.dart';

class CalculatorLandingScreen extends StatelessWidget {
  const CalculatorLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      body: AppAdaptiveBody(
        selectedIndex: 2,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 14 : 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.navy, Color(0xFF1F5365)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PLAN WITH CLARITY',
                          style: TextStyle(
                            color: Color(0xFFA8DED0),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Plan Your Investments',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 22 : 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Explore your financial goals and understand how your investments could grow.',
                          style: TextStyle(
                            color: Color(0xFFE0EAF0),
                            height: isMobile ? 1.35 : 1.45,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const _FreeAccessBadge(),
                      ],
                    ),
                  ),
                  SizedBox(height: isMobile ? 16 : 20),
                  _section(
                    context,
                    title: 'Goal planning',
                    subtitle:
                        'Start with a milestone. Each goal uses the same editable projection engine.',
                    items: goalCalculatorTools,
                  ),
                  SizedBox(height: isMobile ? 16 : 20),
                  _section(
                    context,
                    title: 'Investment calculators',
                    subtitle:
                        'Compare regular contributions and one-time investing.',
                    items: investmentCalculatorTools,
                  ),
                  SizedBox(height: isMobile ? 12 : 16),
                  const _IllustrationDisclaimer(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<CalculatorToolOption> items,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.headlineSmall),
      SizedBox(
        height: AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width)
            ? 3
            : 4,
      ),
      Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      SizedBox(
        height: AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width)
            ? 8
            : 10,
      ),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? 3
              : constraints.maxWidth >= 300
              ? 3
              : constraints.maxWidth >= 220
              ? 2
              : 1;
          final compact = constraints.maxWidth < 900;
          final gap = AppTheme.isMobileWidth(constraints.maxWidth)
              ? 10.0
              : 12.0;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final item in items)
                SizedBox(
                  key: ValueKey('calculator-${item.id}'),
                  width: width,
                  child: _CalculatorTile(
                    data: item,
                    compact: compact,
                    onTap: () =>
                        context.push('${AppRoutes.calculator}/${item.id}'),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}

class _CalculatorTile extends StatelessWidget {
  const _CalculatorTile({
    required this.data,
    required this.onTap,
    this.compact = false,
  });

  final CalculatorToolOption data;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(
          compact
              ? AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width)
                    ? 10
                    : 12
              : 18,
        ),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(data.icon, color: AppColors.blue, size: 20),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.blue,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha: .11),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(data.icon, color: AppColors.blue, size: 25),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          data.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        const Row(
                          children: [
                            Text(
                              'Calculate',
                              style: TextStyle(
                                color: AppColors.blue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: AppColors.blue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}

class _FreeAccessBadge extends StatelessWidget {
  const _FreeAccessBadge();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(99),
    ),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        children: [
          Icon(Icons.lock_open_rounded, color: Color(0xFFA8DED0), size: 16),
          Text(
            'Free to use · No account required',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

class _IllustrationDisclaimer extends StatelessWidget {
  const _IllustrationDisclaimer();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: const Text(
      'Calculators provide illustrative estimates only. Mutual fund returns are market-linked and are not guaranteed.',
      style: TextStyle(height: 1.4),
    ),
  );
}
