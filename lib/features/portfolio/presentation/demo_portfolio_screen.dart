import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_financial_widgets.dart';
import '../../../core/widgets/app_shell.dart';
import '../data/demo_portfolio_repository.dart';
import '../domain/demo_portfolio.dart';

const _repository = DemoPortfolioRepository();
const _chartColors = [
  AppColors.blue,
  AppColors.navy,
  Color(0xFF5EB49B),
  Color(0xFF8A6FAF),
  Color(0xFFE0A448),
  Color(0xFF5B91B8),
];

class DemoPortfolioScreen extends StatefulWidget {
  const DemoPortfolioScreen({super.key});

  @override
  State<DemoPortfolioScreen> createState() => _DemoPortfolioScreenState();
}

class _DemoPortfolioScreenState extends State<DemoPortfolioScreen> {
  String _range = 'ALL';
  String _holdingFilter = 'All';
  String _sort = 'Value';
  String _allocationBy = 'Asset class';
  String _section = 'Overview';
  bool _showXirr = true;

  bool get _isMobile =>
      AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile;
    final summary = _repository.summary;
    final holdings = _repository.holdings.where((holding) {
      return _holdingFilter == 'All' ||
          holding.assetClass == _holdingFilter ||
          holding.category == _holdingFilter;
    }).toList();
    holdings.sort(
      (first, second) => _sort == 'Return'
          ? second.returnPercent.compareTo(first.returnPercent)
          : second.currentValue.compareTo(first.currentValue),
    );
    final allocationGroup = switch (_allocationBy) {
      'Category' => 'Category',
      'AMC' => 'AMC',
      'Scheme' => 'Scheme',
      _ => 'Asset class',
    };
    final allocation = _repository.allocation(allocationGroup);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        actions: const [_DemoHeaderBadge(), SizedBox(width: 12)],
      ),
      body: AppAdaptiveBody(
        selectedIndex: 1,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _investorGreeting(),
                  _summaryPanel(summary, _repository.monthlySipCommitment),
                  SizedBox(height: isMobile ? 10 : 12),
                  _advisorCard(),
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
                      subtitle: 'Illustrative sample value over time.',
                    ),
                    _performanceChart(_range),
                  ] else if (_section == 'Holdings') ...[
                    AppSectionHeading(
                      title: 'My holdings',
                      subtitle: 'Six fictional schemes with reconciled totals.',
                      trailing: PopupMenuButton<String>(
                        tooltip: 'Sort holdings',
                        onSelected: (value) => setState(() => _sort = value),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'Value',
                            child: Text('Sort by value'),
                          ),
                          PopupMenuItem(
                            value: 'Return',
                            child: Text('Sort by return'),
                          ),
                        ],
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sort_rounded),
                            SizedBox(width: 4),
                            Text('Sort'),
                          ],
                        ),
                      ),
                    ),
                    _holdingFilters(),
                    const SizedBox(height: 8),
                    for (final holding in holdings)
                      _HoldingTile(
                        holding: holding,
                        onTap: () => context.push(
                          '${AppRoutes.portfolioHolding}/${holding.id}',
                        ),
                      ),
                  ] else if (_section == 'Allocation') ...[
                    AppSectionHeading(
                      title: 'Portfolio allocation',
                      subtitle: 'Computed from the sample holdings.',
                    ),
                    _allocationPanel(allocation, _allocationBy),
                  ] else if (_section == 'SIPs') ...[
                    _recordsPanel(
                      title: 'Demo SIP schedules',
                      rows: [
                        for (final sip in _repository.sips)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(sip.schemeName),
                            subtitle: Text(
                              '${_money(sip.monthlyAmount)} monthly · next ${sip.nextInstallment}',
                            ),
                            trailing: Text(sip.status),
                          ),
                      ],
                      onViewAll: () => context.push(AppRoutes.portfolioSips),
                    ),
                  ] else if (_section == 'Orders') ...[
                    _recordsPanel(
                      title: 'Order examples · separate from holdings',
                      rows: [
                        for (final order in _repository.orders)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${order.type} · ${order.schemeName}'),
                            subtitle: Text('${order.date} · ${order.status}'),
                            trailing: Text(_money(order.amount)),
                          ),
                      ],
                      onViewAll: () => context.push(AppRoutes.portfolioOrders),
                    ),
                  ] else ...[
                    _recordsPanel(
                      title: 'Confirmed demo transactions',
                      rows: [
                        for (final transaction in _repository.transactions)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${transaction.type} · ${transaction.schemeName}',
                            ),
                            subtitle: Text(
                              '${transaction.date} · ${transaction.status}',
                            ),
                            trailing: Text(_money(transaction.amount)),
                          ),
                      ],
                      onViewAll: () =>
                          context.push(AppRoutes.portfolioTransactions),
                    ),
                  ],
                  if (_section == 'Overview') ...[
                    const SizedBox(height: 14),
                    _quickAccess(context),
                  ],
                  const SizedBox(height: 14),
                  const _DemoDisclaimer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _recordsPanel({
    required String title,
    required List<Widget> rows,
    required VoidCallback onViewAll,
  }) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              TextButton(onPressed: onViewAll, child: const Text('Details')),
            ],
          ),
          ...rows,
        ],
      ),
    ),
  );

  Widget _investorGreeting() => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.secondaryText),
              ),
              Text(
                'Priya Nair',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const _DemoHeaderBadge(),
      ],
    ),
  );

  Widget _summaryPanel(
    DemoPortfolioSummary summary,
    double monthlySipCommitment,
  ) => Container(
    key: const ValueKey('portfolio-summary-panel'),
    padding: EdgeInsets.all(_isMobile ? 16 : 20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF08796F), Color(0xFF066B63)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current value · SAMPLE DATA',
                    style: TextStyle(
                      color: Color(0xFFDCEDEA),
                      fontSize: _isMobile ? 12 : 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _money(summary.currentValue),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _isMobile ? 30 : 34,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _returnToggle(summary),
          ],
        ),
        SizedBox(height: _isMobile ? 12 : 16),
        Row(
          children: [
            Expanded(
              child: _summaryMetric('Invested', _money(summary.invested)),
            ),
            const SizedBox(width: 8),
            Expanded(child: _summaryMetric('Gain', _money(summary.gain))),
            const SizedBox(width: 8),
            Expanded(
              child: _summaryMetric(
                'Monthly SIP',
                _money(monthlySipCommitment),
              ),
            ),
          ],
        ),
        SizedBox(height: _isMobile ? 8 : 10),
        Text(
          'Updated ${summary.lastUpdated.day.toString().padLeft(2, '0')} '
          '${_month(summary.lastUpdated.month)} ${summary.lastUpdated.year}. '
          '*XIRR is an illustrative demo assumption, not computed performance.',
          style: const TextStyle(color: Color(0xFFDCE5EF), fontSize: 11),
        ),
      ],
    ),
  );

  Widget _summaryMetric(String label, String value) => Container(
    padding: EdgeInsets.all(_isMobile ? 8 : 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFFDCEDEA), fontSize: 11),
        ),
        SizedBox(height: _isMobile ? 3 : 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: _isMobile ? 15 : 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _returnToggle(DemoPortfolioSummary summary) {
    final label = _showXirr ? 'XIRR' : 'ABSOLUTE';
    final value = _showXirr
        ? summary.xirr.toStringAsFixed(1)
        : summary.absoluteReturn.toStringAsFixed(2);
    return Tooltip(
      message: 'Tap to switch to ${_showXirr ? 'absolute return' : 'XIRR'}',
      child: Material(
        color: Colors.white.withValues(alpha: .2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(99),
          side: BorderSide(color: Colors.white.withValues(alpha: .35)),
        ),
        child: InkWell(
          key: const ValueKey('portfolio-return-toggle'),
          borderRadius: BorderRadius.circular(99),
          mouseCursor: SystemMouseCursors.click,
          onTap: () => setState(() => _showXirr = !_showXirr),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$label $value%',
                  semanticsLabel:
                      '${_showXirr ? 'XIRR' : 'Absolute return'} $value percent. '
                      'Tap to switch return type.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.swap_horiz_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _advisorCard() => Container(
    padding: EdgeInsets.all(_isMobile ? 12 : 14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.surfaceRaised,
              foregroundColor: AppColors.blue,
              child: Text('RK', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            SizedBox(width: _isMobile ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your advisor',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Rahul Kumar',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const _DemoHeaderBadge(),
          ],
        ),
        SizedBox(height: _isMobile ? 10 : 12),
        const Divider(height: 1),
        SizedBox(height: _isMobile ? 8 : 10),
        _advisorDetail(Icons.phone_outlined, '+91 ••••• ••210'),
        SizedBox(height: _isMobile ? 6 : 8),
        _advisorDetail(Icons.email_outlined, 'rahul.kumar@example.invalid'),
        const SizedBox(height: 8),
        const Text(
          'Fictional sample contact details; not a real advisor.',
          style: TextStyle(color: AppColors.secondaryText, fontSize: 11),
        ),
      ],
    ),
  );

  Widget _advisorDetail(IconData icon, String value) => Row(
    children: [
      Icon(icon, size: 18, color: AppColors.blue),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    ],
  );

  Widget _performanceChart(String selectedRange) {
    final points = _repository.performance(range: selectedRange);
    return Container(
      padding: EdgeInsets.all(_isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 6,
              children: [
                for (final range in const ['1M', '3M', '6M', '1Y', '3Y', 'ALL'])
                  ChoiceChip(
                    label: Text(range),
                    selected: _range == range,
                    onSelected: (_) => setState(() => _range = range),
                  ),
              ],
            ),
          ),
          SizedBox(height: _isMobile ? 6 : 8),
          SizedBox(
            height: 220,
            width: double.infinity,
            child: CustomPaint(painter: _PortfolioLinePainter(points)),
          ),
          SizedBox(height: _isMobile ? 8 : 10),
          const Wrap(
            spacing: 18,
            children: [
              _Legend(color: AppColors.navy, label: 'Invested'),
              _Legend(color: AppColors.blue, label: 'Portfolio value'),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Demo chart values are interpolated to match the sample summary.',
            style: TextStyle(color: AppColors.secondaryText, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _holdingFilters() => Wrap(
    spacing: 8,
    children: [
      for (final filter in const ['All', 'Equity', 'Debt', 'Hybrid'])
        ChoiceChip(
          label: Text(filter),
          selected: _holdingFilter == filter,
          onSelected: (_) => setState(() => _holdingFilter = filter),
        ),
    ],
  );

  Widget _allocationPanel(List<DemoAllocation> allocation, String selected) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: [
                  for (final mode in const [
                    'Asset class',
                    'Category',
                    'AMC',
                    'Scheme',
                  ])
                    ChoiceChip(
                      label: Text(mode),
                      selected: selected == mode,
                      onSelected: (_) => setState(() => _allocationBy = mode),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 600;
                final chart = SizedBox(
                  height: 200,
                  width: wide ? 250 : double.infinity,
                  child: CustomPaint(
                    painter: _DonutPainter(
                      values: [for (final item in allocation) item.value],
                      colors: [
                        for (final item in allocation)
                          _chartColors[item.colorIndex % _chartColors.length],
                      ],
                    ),
                  ),
                );
                final legend = Column(
                  children: [
                    for (final item in allocation)
                      _AllocationRow(
                        item: item,
                        total: _repository.summary.currentValue,
                      ),
                  ],
                );
                return wide
                    ? Row(
                        children: [
                          chart,
                          const SizedBox(width: 18),
                          Expanded(child: legend),
                        ],
                      )
                    : Column(children: [chart, legend]);
              },
            ),
          ],
        ),
      );

  Widget _quickAccess(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 850
          ? 4
          : constraints.maxWidth >= 500
          ? 2
          : 1;
      final gap = 10.0;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      final destinations = [
        (
          'My SIPs',
          'Four schedules and their current status',
          Icons.autorenew_rounded,
          AppRoutes.portfolioSips,
        ),
        (
          'Transactions',
          'Confirmed sample activity',
          Icons.swap_horiz_rounded,
          AppRoutes.portfolioTransactions,
        ),
        (
          'Order history',
          'Separate order lifecycle examples',
          Icons.receipt_long_rounded,
          AppRoutes.portfolioOrders,
        ),
        (
          'Allocation',
          'Asset class, category, AMC and scheme',
          Icons.donut_large_rounded,
          AppRoutes.portfolioAllocation,
        ),
      ];
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final entry in destinations)
            SizedBox(
              width: width,
              child: Card(
                child: ListTile(
                  leading: Icon(entry.$3, color: AppColors.blue),
                  title: Text(entry.$1),
                  subtitle: Text(entry.$2),
                  trailing: const Icon(Icons.arrow_forward_rounded),
                  onTap: () => context.push(entry.$4),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class DemoPortfolioFeatureScreen extends StatefulWidget {
  const DemoPortfolioFeatureScreen({
    super.key,
    required this.title,
    this.schemeId,
  });

  final String title;
  final String? schemeId;

  @override
  State<DemoPortfolioFeatureScreen> createState() =>
      _DemoPortfolioFeatureScreenState();
}

class _DemoPortfolioFeatureScreenState
    extends State<DemoPortfolioFeatureScreen> {
  String _allocationBy = 'Asset class';
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final holding = _repository.holding(widget.schemeId ?? '');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: const [_DemoHeaderBadge(), SizedBox(width: 12)],
      ),
      body: AppAdaptiveBody(
        selectedIndex: 1,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppPageHeader(
                    eyebrow: 'Demo data',
                    title: widget.title,
                    subtitle:
                        'Fictional records only. No real investor data or orders.',
                    trailing: const _DemoHeaderBadge(),
                  ),
                  if (widget.title == 'Holding details')
                    _holdingDetails(context, holding)
                  else if (widget.title == 'My SIPs')
                    _sipList(context)
                  else if (widget.title == 'Transaction history')
                    _transactionList()
                  else if (widget.title == 'Order history')
                    _orderList()
                  else
                    _allocationDetails(),
                  const SizedBox(height: 20),
                  const _DemoDisclaimer(),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
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

  Widget _holdingDetails(BuildContext context, DemoHolding? holding) {
    if (holding == null) {
      return const _DemoPanel(child: Text('This demo holding is unavailable.'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DemoPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _DemoHeaderBadge(),
              const SizedBox(height: 12),
              Text(
                holding.schemeName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text('${holding.amcName} · ${holding.category}'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _smallMetric('Current value', _money(holding.currentValue)),
                  _smallMetric('Invested', _money(holding.invested)),
                  _smallMetric('Gain', _money(holding.gain)),
                  _smallMetric(
                    'Return',
                    '${holding.returnPercent.toStringAsFixed(2)}%',
                  ),
                  _smallMetric('Units', holding.units.toStringAsFixed(3)),
                  _smallMetric(
                    'Average purchase NAV',
                    _money(holding.averagePurchaseNav),
                  ),
                  _smallMetric('Latest NAV', _money(holding.latestNav)),
                  _smallMetric('XIRR*', '${holding.xirr.toStringAsFixed(1)}%'),
                  _smallMetric('Folio', holding.folio),
                  _smallMetric(
                    'Plan / option',
                    '${holding.plan} · ${holding.option}',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Sample NAV date: ${holding.navDate}'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _DemoPanel(
          title: 'Investment history',
          child: Column(
            children: [
              _TransactionRow(
                title: 'Initial investment (demo)',
                subtitle: '2022-04-15 · Confirmed sample record',
                amount: 'Illustrative cash flow',
              ),
              SizedBox(
                height: 190,
                width: double.infinity,
                child: CustomPaint(
                  painter: _PortfolioLinePainter([
                    for (var index = 0; index <= 12; index++)
                      DemoPerformancePoint(
                        date: DateTime(2025, index + 1, 1),
                        invested: holding.invested * (.2 + .8 * index / 12),
                        value: holding.currentValue * (.18 + .82 * index / 12),
                      ),
                  ]),
                ),
              ),
              _TransactionRow(
                title: 'Recurring investment (demo)',
                subtitle: 'Monthly installments · Sample history',
                amount: 'Illustrative cash flow',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () => _showDemoNotice(context, 'Invest more'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Invest more · demo'),
            ),
            OutlinedButton.icon(
              onPressed: () => _showDemoNotice(context, 'Redeem'),
              icon: const Icon(Icons.south_west_rounded),
              label: const Text('Redeem · demo'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          '*Holding XIRR values are illustrative placeholders, not actual cash-flow calculations.',
          style: TextStyle(color: AppColors.secondaryText, fontSize: 11),
        ),
      ],
    );
  }

  Widget _sipList(BuildContext context) {
    final sips = _repository.sips.where(
      (sip) => _statusFilter == 'All' || sip.status == _statusFilter,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DemoPanel(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _smallMetric(
                'Scheduled monthly amount',
                _money(_repository.monthlySipCommitment),
              ),
              _smallMetric(
                'Scheduled SIP plans',
                '${_repository.scheduledSipCount}',
              ),
              _smallMetric(
                'All demo SIP records',
                '${_repository.sips.length}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          children: [
            for (final status in const [
              'All',
              'Active',
              'Upcoming',
              'Paused',
              'Completed',
            ])
              ChoiceChip(
                label: Text(status),
                selected: _statusFilter == status,
                onSelected: (_) => setState(() => _statusFilter = status),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (final sip in sips)
          _DemoPanel(
            child: InkWell(
              onTap: () => _showSipDetails(context, sip),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sip.schemeName,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        _StatusChip(sip.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_money(sip.monthlyAmount)} monthly · ${sip.sipDay}th of month',
                    ),
                    Text(
                      'Started ${sip.startDate} · Next: ${sip.nextInstallment}',
                    ),
                    Text(
                      '${sip.successfulInstallments}/${sip.installments} installments · ${sip.mandateStatus}',
                    ),
                    TextButton(
                      onPressed: () => _showDemoNotice(context, 'Manage SIP'),
                      child: const Text('Manage · demo only'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _transactionList() => _DemoPanel(
    title: 'Confirmed transaction examples',
    child: Column(
      children: [
        for (final transaction in _repository.transactions)
          _TransactionRow(
            title: '${transaction.type} · ${transaction.schemeName}',
            subtitle:
                '${transaction.date} · ${transaction.units.toStringAsFixed(2)} units · ${transaction.status}',
            amount: _money(transaction.amount),
          ),
      ],
    ),
  );

  Widget _orderList() => _DemoPanel(
    title: 'Order examples · kept separate from holdings',
    child: Column(
      children: [
        for (final order in _repository.orders)
          _TransactionRow(
            title: '${order.type} · ${order.schemeName}',
            subtitle: '${order.date} · ${order.status}',
            amount: _money(order.amount),
          ),
      ],
    ),
  );

  Widget _allocationDetails() {
    final group = switch (_allocationBy) {
      'Category' => 'Category',
      'AMC' => 'AMC',
      'Scheme' => 'Scheme',
      _ => 'Asset class',
    };
    final items = _repository.allocation(group);
    return Column(
      children: [
        _DemoPanel(
          child: Wrap(
            spacing: 8,
            children: [
              for (final mode in const [
                'Asset class',
                'Category',
                'AMC',
                'Scheme',
              ])
                ChoiceChip(
                  label: Text(mode),
                  selected: _allocationBy == mode,
                  onSelected: (_) => setState(() => _allocationBy = mode),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _DemoPanel(
          title: 'Allocation by $group',
          child: Column(
            children: [
              SizedBox(
                height: 230,
                child: CustomPaint(
                  painter: _DonutPainter(
                    values: [for (final item in items) item.value],
                    colors: [
                      for (final item in items)
                        _chartColors[item.colorIndex % _chartColors.length],
                    ],
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              for (final item in items)
                _AllocationRow(
                  item: item,
                  total: _repository.summary.currentValue,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showSipDetails(
    BuildContext context,
    DemoSip sip,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sip.schemeName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              '${_money(sip.monthlyAmount)} every month on the ${sip.sipDay}th',
            ),
            Text('Start date: ${sip.startDate}'),
            Text('Next installment: ${sip.nextInstallment}'),
            Text('Status: ${sip.status}'),
            Text('Mandate: ${sip.mandateStatus}'),
            const SizedBox(height: 12),
            const _DemoDisclaimer(),
          ],
        ),
      ),
    ),
  );

  Widget _smallMetric(String label, String value) => SizedBox(
    width: 170,
    child: AppMetricTile(label: label, value: value),
  );
}

class _HoldingTile extends StatelessWidget {
  const _HoldingTile({required this.holding, required this.onTap});

  final DemoHolding holding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.blue.withValues(alpha: .1),
        child: Text(
          holding.assetClass.substring(0, 1),
          style: const TextStyle(color: AppColors.blue),
        ),
      ),
      title: Text(holding.schemeName),
      subtitle: Text('${holding.category} · ${holding.amcName}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _money(holding.currentValue),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Text(
            '${holding.returnPercent.toStringAsFixed(2)}% · ${_money(holding.gain)}',
            style: TextStyle(
              color: holding.gain >= 0 ? AppColors.success : AppColors.error,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}

class _DemoPanel extends StatelessWidget {
  const _DemoPanel({required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: isMobile ? 10 : 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _DemoHeaderBadge extends StatelessWidget {
  const _DemoHeaderBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1D6),
      borderRadius: BorderRadius.circular(99),
    ),
    child: const Text(
      'DEMO DATA',
      style: TextStyle(
        color: Color(0xFF805400),
        fontWeight: FontWeight.w800,
        fontSize: 11,
      ),
    ),
  );
}

class _DemoDisclaimer extends StatelessWidget {
  const _DemoDisclaimer();

  @override
  Widget build(BuildContext context) {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        border: Border.all(color: const Color(0xFFF0D89C)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'DEMO DATA ONLY. All scheme names, folios, units, transactions, NAVs and returns shown here are fictional examples. Values are not connected to investor records or live market data. Demo actions never submit real investment orders.',
        style: TextStyle(fontSize: 12, height: isMobile ? 1.35 : 1.4),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);
  final String status;

  @override
  Widget build(BuildContext context) => Chip(
    visualDensity: VisualDensity.compact,
    label: Text(status),
    backgroundColor: status == 'Active' || status == 'Upcoming'
        ? AppColors.surfaceRaised
        : const Color(0xFFF1F2F4),
  );
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  final String title;
  final String subtitle;
  final String amount;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
    subtitle: Text(subtitle),
    trailing: Text(amount, style: const TextStyle(fontWeight: FontWeight.w700)),
  );
}

class _AllocationRow extends StatelessWidget {
  const _AllocationRow({required this.item, required this.total});

  final DemoAllocation item;
  final double total;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : item.value / total * 100;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _chartColors[item.colorIndex % _chartColors.length],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(_money(item.value)),
          const SizedBox(width: 10),
          SizedBox(
            width: 52,
            child: Text(
              '${percent.toStringAsFixed(1)}%',
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _PortfolioLinePainter extends CustomPainter {
  const _PortfolioLinePainter(this.points);
  final List<DemoPerformancePoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const pad = 12.0;
    final maxValue = points.fold<double>(
      0,
      (value, point) => math.max(value, point.value),
    );
    if (maxValue <= 0) return;
    final chartHeight = size.height - pad * 2;
    final chartWidth = size.width - pad * 2;
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var index = 0; index <= 3; index++) {
      final y = pad + chartHeight * index / 3;
      canvas.drawLine(Offset(pad, y), Offset(size.width - pad, y), grid);
    }
    List<Offset> linePoints(double Function(DemoPerformancePoint) select) => [
      for (var index = 0; index < points.length; index++)
        Offset(
          pad +
              (points.length <= 1
                  ? chartWidth
                  : chartWidth * index / (points.length - 1)),
          pad + chartHeight * (1 - select(points[index]) / maxValue),
        ),
    ];
    void draw(List<Offset> values, Color color) {
      final path = Path()..moveTo(values.first.dx, values.first.dy);
      for (final point in values.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    draw(linePoints((point) => point.invested), AppColors.navy);
    draw(linePoints((point) => point.value), AppColors.blue);
  }

  @override
  bool shouldRepaint(covariant _PortfolioLinePainter oldDelegate) =>
      oldDelegate.points != points;
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.values, required this.colors});
  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final total = values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) return;
    final side = math.min(size.width, size.height) * .78;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: side,
      height: side,
    );
    var start = -math.pi / 2;
    for (var index = 0; index < values.length; index++) {
      final sweep = values[index] / total * math.pi * 2;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = colors[index % colors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = side * .19,
      );
      start += sweep;
    }
    final text = TextPainter(
      text: const TextSpan(
        text: 'DEMO',
        style: TextStyle(
          color: AppColors.navy,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(
      canvas,
      Offset(
        size.width / 2 - text.width / 2,
        size.height / 2 - text.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.colors != colors;
}

void _showDemoNotice(BuildContext context, String action) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '$action is a demo interaction. No real order was submitted.',
      ),
    ),
  );
}

String _money(double amount) {
  final text = amount.round().toString();
  final lastThree = text.length > 3 ? text.substring(text.length - 3) : text;
  final prefix = text.length > 3 ? text.substring(0, text.length - 3) : '';
  final grouped = prefix.isEmpty
      ? lastThree
      : '${prefix.replaceAllMapped(RegExp(r'\B(?=(\d{2})+(?!\d))'), (_) => ',')},$lastThree';
  return '₹$grouped';
}

String _month(int number) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][number - 1];
