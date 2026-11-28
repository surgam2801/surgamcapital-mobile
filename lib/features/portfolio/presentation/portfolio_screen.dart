import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_financial_widgets.dart';
import '../../../core/widgets/app_shell.dart';
import '../data/demo_portfolio_repository.dart';
import 'demo_portfolio_screen.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  String _section = 'Overview';

  @override
  Widget build(BuildContext context) {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    if (portfolioDemoMode) return const DemoPortfolioScreen();
    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio')),
      body: AppAdaptiveBody(
        selectedIndex: 1,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppPageHeader(
                    eyebrow: 'Investor home',
                    title: 'Investor profile',
                    subtitle:
                        'Your name and advisor details will appear when profile data is connected.',
                  ),
                  const _PortfolioSummary(),
                  SizedBox(height: isMobile ? 10 : 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'Overview',
                          label: Text('Overview'),
                        ),
                        ButtonSegment(
                          value: 'Holdings',
                          label: Text('Holdings'),
                        ),
                        ButtonSegment(value: 'SIPs', label: Text('SIPs')),
                        ButtonSegment(value: 'Orders', label: Text('Orders')),
                        ButtonSegment(
                          value: 'Transactions',
                          label: Text('Transactions'),
                        ),
                        ButtonSegment(
                          value: 'Allocation',
                          label: Text('Allocation'),
                        ),
                      ],
                      selected: {_section},
                      showSelectedIcon: false,
                      onSelectionChanged: (selected) =>
                          setState(() => _section = selected.first),
                    ),
                  ),
                  SizedBox(height: isMobile ? 11 : 14),
                  if (_section == 'Overview') ...[
                    const AppSectionHeading(
                      title: 'Portfolio performance',
                      subtitle:
                          'Dated cash flows and valuations are required for returns.',
                    ),
                    const _UnavailablePanel(
                      icon: Icons.show_chart_rounded,
                      title: 'Performance history is not available yet',
                      description:
                          'No confirmed portfolio cash flows or holding valuations are synchronized, so there is no chart or return figure to display.',
                      child: _PerformanceRanges(),
                    ),
                    SizedBox(height: isMobile ? 11 : 14),
                    const AppSectionHeading(
                      title: 'Portfolio status',
                      subtitle: 'No verified investor holdings are available.',
                    ),
                    const _UnavailablePanel(
                      icon: Icons.inventory_2_outlined,
                      title: 'No synchronized holdings',
                      description:
                          'Only confirmed allotments and applicable current NAVs can be shown here.',
                    ),
                  ] else if (_section == 'Holdings') ...[
                    const AppSectionHeading(title: 'My holdings'),
                    const _UnavailablePanel(
                      icon: Icons.inventory_2_outlined,
                      title: 'No synchronized holdings',
                      description:
                          'Holdings require confirmed folio/allotment records, adjusted units and current applicable NAVs.',
                    ),
                  ] else if (_section == 'Allocation') ...[
                    const AppSectionHeading(title: 'Portfolio allocation'),
                    const _UnavailablePanel(
                      icon: Icons.donut_large_rounded,
                      title:
                          'Allocation will appear when holdings are synchronized',
                      description:
                          'Equity, debt, hybrid and other values and percentages are currently unavailable.',
                    ),
                  ] else ...[
                    AppSectionHeading(
                      title: switch (_section) {
                        'SIPs' => 'My SIPs',
                        'Orders' => 'Order history',
                        _ => 'Transactions',
                      },
                      subtitle: switch (_section) {
                        'SIPs' => 'Recurring schedules and instalments.',
                        'Orders' =>
                          'Order acknowledgements are not allotments.',
                        _ => 'Confirmed investment activity.',
                      },
                    ),
                    _PortfolioShortcut(
                      icon: _section == 'SIPs'
                          ? Icons.autorenew_rounded
                          : _section == 'Orders'
                          ? Icons.receipt_long_outlined
                          : Icons.swap_horiz_rounded,
                      title: switch (_section) {
                        'SIPs' => 'No synchronized SIP records',
                        'Orders' => 'No order records available',
                        _ => 'No confirmed transactions available',
                      },
                      subtitle:
                          'Portfolio records are unavailable until verified data is synchronized.',
                      onTap: () => context.push(
                        _section == 'SIPs'
                            ? AppRoutes.portfolioSips
                            : _section == 'Orders'
                            ? AppRoutes.portfolioOrders
                            : AppRoutes.portfolioTransactions,
                      ),
                    ),
                  ],
                  if (_section == 'Overview')
                    SizedBox(height: isMobile ? 11 : 14),
                  if (_section == 'Overview')
                    AppSectionHeading(
                      title: 'Quick access',
                      subtitle: 'Portfolio activity and recurring plans.',
                    ),
                  if (_section == 'Overview')
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 1000
                            ? 4
                            : constraints.maxWidth >= 440
                            ? 2
                            : 1;
                        return GridView.count(
                          crossAxisCount: columns,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: columns == 1 ? 2.2 : 1.65,
                          children: [
                            _PortfolioShortcut(
                              icon: Icons.autorenew_rounded,
                              title: 'My SIPs',
                              subtitle: 'Schedules and instalments',
                              onTap: () =>
                                  context.push(AppRoutes.portfolioSips),
                            ),
                            _PortfolioShortcut(
                              icon: Icons.swap_horiz_rounded,
                              title: 'Transactions',
                              subtitle: 'Confirmed activity',
                              onTap: () =>
                                  context.push(AppRoutes.portfolioTransactions),
                            ),
                            _PortfolioShortcut(
                              icon: Icons.receipt_long_outlined,
                              title: 'Order history',
                              subtitle: 'Order lifecycle status',
                              onTap: () =>
                                  context.push(AppRoutes.portfolioOrders),
                            ),
                            _PortfolioShortcut(
                              icon: Icons.donut_large_rounded,
                              title: 'Allocation',
                              subtitle: 'Category breakdown',
                              onTap: () =>
                                  context.push(AppRoutes.portfolioAllocation),
                            ),
                          ],
                        );
                      },
                    ),
                  SizedBox(height: isMobile ? 10 : 12),
                  const AppSourceNote(
                    source: 'Data status',
                    caption:
                        'Portfolio APIs and BSE/RTA allotment synchronization are not configured in this application yet.',
                    tone: AppStatusTone.warning,
                  ),
                  SizedBox(height: isMobile ? 10 : 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PortfolioFeatureScreen extends StatelessWidget {
  const PortfolioFeatureScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.contextLabel,
    this.sections = const [],
    this.fields = const [],
    this.schemeId,
  });

  final String title;
  final String description;
  final IconData icon;
  final String contextLabel;
  final List<String> sections;
  final List<String> fields;
  final String? schemeId;

  @override
  Widget build(BuildContext context) {
    if (portfolioDemoMode) {
      return DemoPortfolioFeatureScreen(title: title, schemeId: schemeId);
    }
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AppAdaptiveBody(
        selectedIndex: 1,
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width)
                  ? 14
                  : 16,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppPageHeader(
                    eyebrow: 'Portfolio',
                    title: title,
                    subtitle: contextLabel,
                  ),
                  _UnavailablePanel(
                    icon: icon,
                    title: 'Portfolio service is not connected',
                    description: description,
                  ),
                  if (sections.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    AppSectionHeading(
                      title: _sectionTitle,
                      subtitle: 'No synchronized records in any section.',
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final section in sections)
                          AppStatusBadge(
                            label: section,
                            icon: Icons.remove_circle_outline_rounded,
                          ),
                      ],
                    ),
                  ],
                  if (fields.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const AppSectionHeading(
                      title: 'Information shown when available',
                      subtitle:
                          'Values remain unavailable until verified data is synchronized.',
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 600 ? 2 : 1;
                        final gap = 12.0;
                        final width =
                            (constraints.maxWidth - gap * (columns - 1)) /
                            columns;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final field in fields)
                              SizedBox(
                                width: width,
                                child: AppMetricTile(
                                  label: field,
                                  value: '—',
                                  caption: 'Unavailable',
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  const AppSourceNote(
                    source: 'No sample records shown',
                    caption:
                        'This screen will only display verified investor-specific records after the corresponding API and data source are integrated.',
                    tone: AppStatusTone.warning,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.portfolio),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back to portfolio'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _sectionTitle => switch (title) {
    'My SIPs' => 'SIP status',
    'Transaction history' => 'Transaction types',
    'Order history' => 'Order status',
    'Portfolio allocation' => 'Allocation categories',
    _ => 'Sections',
  };
}

class _PortfolioSummary extends StatelessWidget {
  const _PortfolioSummary();

  static const _metrics = [
    (
      'Current value',
      'Requires confirmed units × latest NAV',
      Icons.account_balance_wallet_outlined,
    ),
    (
      'Total invested',
      'Requires reconciled transaction history',
      Icons.savings_outlined,
    ),
    (
      'Total returns',
      'Current value less current cost basis',
      Icons.trending_up_rounded,
    ),
    (
      'Absolute return',
      'Unavailable until cost basis is verified',
      Icons.percent_rounded,
    ),
    (
      'Portfolio XIRR',
      'Requires dated investor cash flows',
      Icons.show_chart_rounded,
    ),
    ('Last updated', 'No portfolio sync has completed', Icons.sync_outlined),
  ];

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(
      AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width) ? 16 : 20,
    ),
    decoration: BoxDecoration(
      color: AppColors.navy,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFF29435B)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14142B45),
          blurRadius: 22,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'PORTFOLIO SUMMARY',
                style: TextStyle(
                  color: Color(0xFFB5D9CE),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const AppStatusBadge(
              label: 'NOT SYNCED',
              icon: Icons.sync_problem_rounded,
              tone: AppStatusTone.warning,
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final metric in _metrics)
                Container(
                  width: 188,
                  margin: const EdgeInsets.only(right: 8),
                  child: AppMetricTile(
                    label: metric.$1,
                    value: '—',
                    caption: metric.$2,
                    icon: metric.$3,
                    accent: metric.$1 == 'Current value',
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PerformanceRanges extends StatelessWidget {
  const _PerformanceRanges();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final range in const ['1M', '6M', '1Y', '3Y', '5Y', 'ALL'])
        ChoiceChip(label: Text(range), selected: false, onSelected: null),
    ],
  );
}

class _UnavailablePanel extends StatelessWidget {
  const _UnavailablePanel({
    required this.icon,
    required this.title,
    required this.description,
    this.child,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(
      AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width) ? 14 : 18,
    ),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: AppColors.blue),
            ),
            SizedBox(
              width: AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width)
                  ? 8
                  : 12,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(
                    height:
                        AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width)
                        ? 4
                        : 5,
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (child != null) ...[
          SizedBox(
            height: AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width)
                ? 12
                : 16,
          ),
          child!,
        ],
      ],
    ),
  );
}

class _PortfolioShortcut extends StatelessWidget {
  const _PortfolioShortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.all(
          AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width) ? 14 : 16,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.blue, size: 24),
            SizedBox(
              width: AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width)
                  ? 10
                  : 12,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.secondaryText,
            ),
          ],
        ),
      ),
    ),
  );
}
