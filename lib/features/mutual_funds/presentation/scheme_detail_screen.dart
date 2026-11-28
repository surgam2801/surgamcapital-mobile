import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_financial_widgets.dart';
import '../../../core/widgets/app_shell.dart';
import '../data/mutual_fund_providers.dart';
import '../domain/mutual_fund_scheme.dart';

class SchemeDetailScreen extends ConsumerStatefulWidget {
  const SchemeDetailScreen({super.key, required this.schemeId});
  final String schemeId;

  @override
  ConsumerState<SchemeDetailScreen> createState() => _SchemeDetailScreenState();
}

class _SchemeDetailScreenState extends ConsumerState<SchemeDetailScreen> {
  String _range = '1Y';
  late Future<MutualFundScheme> _details;
  late Future<NavHistory> _history;
  int? _selectedPoint;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final repository = ref.read(mutualFundRepositoryProvider);
    _details = repository.details(widget.schemeId);
    _history = repository.navHistory(widget.schemeId, range: _range);
  }

  void _setRange(String value) {
    setState(() {
      _range = value;
      _selectedPoint = null;
      _history = ref
          .read(mutualFundRepositoryProvider)
          .navHistory(widget.schemeId, range: value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedForComparison = ref
        .watch(comparisonSelectionProvider)
        .any((scheme) => scheme.id == widget.schemeId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheme details'),
        actions: [
          if (!isAmfiSampleMode)
            IconButton(
              tooltip: 'Add to watchlist',
              onPressed: () async {
                try {
                  await ref
                      .read(mutualFundRepositoryProvider)
                      .addToWatchlist(widget.schemeId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Added to watchlist')),
                    );
                  }
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error.toString())));
                  }
                }
              },
              icon: const Icon(Icons.bookmark_add_outlined),
            ),
          IconButton(
            tooltip: selectedForComparison
                ? 'Remove from comparison'
                : 'Add to comparison',
            onPressed: () async {
              try {
                final scheme = await _details;
                final selection = ref.read(comparisonSelectionProvider);
                if (selection.length >= 4 &&
                    !selection.any((item) => item.id == scheme.id)) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Compare up to four schemes.'),
                      ),
                    );
                  }
                  return;
                }
                ref.read(comparisonSelectionProvider.notifier).toggle(scheme);
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error.toString())));
                }
              }
            },
            icon: Icon(
              selectedForComparison ? Icons.check_box : Icons.compare_arrows,
            ),
          ),
        ],
      ),
      body: AppAdaptiveBody(
        selectedIndex: 0,
        child: FutureBuilder<MutualFundScheme>(
          future: _details,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return _error(snapshot.error);
            }
            return _body(snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _body(MutualFundScheme scheme) {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1050),
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 20,
                  isMobile ? 10 : 12,
                  isMobile ? 16 : 20,
                  4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scheme.schemeName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: isMobile ? 4 : 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _metadataTag(scheme.amcName),
                        _metadataTag(scheme.category),
                        _metadataTag(
                          '${scheme.planType} · ${scheme.optionType}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Performance'),
                  Tab(text: 'Fund details & risk'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _overviewTab(scheme),
                    _performanceTab(scheme),
                    _fundDetailsTab(scheme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  EdgeInsets _tabPadding() {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    return EdgeInsets.fromLTRB(
      isMobile ? 16 : 20,
      isMobile ? 10 : 12,
      isMobile ? 16 : 20,
      isMobile ? 18 : 24,
    );
  }

  Widget _overviewTab(MutualFundScheme scheme) => ListView(
    padding: _tabPadding(),
    children: [
      if (scheme.mockData) const _MockDataDisclosure(),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 680 ? 2 : 1;
          final gap = 8.0;
          final itemWidth =
              (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              SizedBox(
                width: itemWidth,
                child: AppMetricTile(
                  label: 'Latest NAV',
                  value: scheme.latestNav?.toStringAsFixed(4) ?? 'N/A',
                  caption: 'As of ${scheme.latestNavDate ?? 'unavailable'}',
                  accent: true,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: AppMetricTile(
                  label: 'Scheme code',
                  value: scheme.schemeCode,
                  caption: 'AMFI scheme identifier',
                  icon: Icons.tag_rounded,
                ),
              ),
            ],
          );
        },
      ),
      SizedBox(
        height: AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width)
            ? 8
            : 10,
      ),
      AppSourceNote(
        source: scheme.dataSource ?? 'Source unavailable',
        caption:
            'NAV dated ${scheme.latestNavDate ?? 'unavailable'} · values are not real-time.',
        tone: isAmfiSampleMode ? AppStatusTone.warning : AppStatusTone.info,
      ),
      SizedBox(
        height: AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width)
            ? 8
            : 10,
      ),
      const Text(
        'Mutual Fund investments are subject to market risks. Please read all scheme related documents carefully.',
        style: TextStyle(color: AppColors.secondaryText),
      ),
      SizedBox(
        height: AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width)
            ? 3
            : 4,
      ),
      const Text(
        'This research is informational and is not personalised investment advice. No purchase or SIP transaction is available.',
        style: TextStyle(color: AppColors.secondaryText),
      ),
    ],
  );

  Widget _performanceTab(MutualFundScheme scheme) => ListView(
    padding: _tabPadding(),
    children: [
      AppSectionHeading(
        title: 'Historical NAV',
        subtitle: isAmfiSampleMode
            ? 'Historical NAV is not included in this saved sample.'
            : 'Explore NAV movement across available periods.',
      ),
      if (!isAmfiSampleMode) ...[
        Wrap(
          spacing: 6,
          children: [
            for (final range in const [
              '1M',
              '3M',
              '6M',
              '1Y',
              '3Y',
              '5Y',
              '10Y',
            ])
              ChoiceChip(
                label: Text(range),
                selected: range == _range,
                onSelected: (_) => _setRange(range),
              ),
          ],
        ),
        const SizedBox(height: 10),
        FutureBuilder<NavHistory>(
          future: _history,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return SizedBox(
                height: 180,
                child: Center(
                  child: TextButton(
                    onPressed: () => _setRange(_range),
                    child: const Text('NAV history unavailable · Retry'),
                  ),
                ),
              );
            }
            final history = snapshot.data;
            if (history == null || history.points.isEmpty) {
              return const SizedBox(
                height: 160,
                child: Center(child: Text('No NAV history available.')),
              );
            }
            final selected = _selectedPoint == null
                ? history.points.last
                : history.points[_selectedPoint!
                      .clamp(0, history.points.length - 1)
                      .toInt()];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (history.mockData) const _MockDataDisclosure(),
                LayoutBuilder(
                  builder: (context, constraints) => SizedBox(
                    height: 190,
                    width: double.infinity,
                    child: GestureDetector(
                      onTapDown: (details) {
                        if (history.points.length < 2 ||
                            constraints.maxWidth <= 0) {
                          return;
                        }
                        setState(
                          () => _selectedPoint =
                              ((details.localPosition.dx /
                                          constraints.maxWidth) *
                                      history.points.length)
                                  .floor()
                                  .clamp(0, history.points.length - 1)
                                  .toInt(),
                        );
                      },
                      child: CustomPaint(
                        painter: _NavChartPainter(history.points),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
                Text(
                  '${_date(selected.date)} · NAV ${selected.nav.toStringAsFixed(4)}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  'Source: ${history.dataSource} · Latest NAV: ${history.navDate ?? 'N/A'}',
                ),
              ],
            );
          },
        ),
      ],
      if (!isAmfiSampleMode) ...[
        const SizedBox(height: 14),
        const Text('Historical performance'),
        const SizedBox(height: 4),
        const Text(
          'Past performance is not indicative of future returns. NAV-based; distributions excluded.',
        ),
        for (final metric in scheme.performance)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(metric.period),
            subtitle: Text(
              '${metric.methodology.replaceAll('_', ' ')} · as of ${metric.asOfDate ?? 'N/A'}',
            ),
            trailing: Text(
              metric.status != 'AVAILABLE' || metric.value == null
                  ? 'N/A'
                  : '${metric.value!.toStringAsFixed(2)}%',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
      ],
    ],
  );

  Widget _fundDetailsTab(MutualFundScheme scheme) => ListView(
    padding: _tabPadding(),
    children: [
      if (scheme.mockData) const _MockDataDisclosure(),
      if (!isAmfiSampleMode)
        AppMetricTile(
          label: 'Riskometer',
          value: scheme.riskometer ?? 'Unavailable',
          caption: 'Scheme risk indicator',
          icon: Icons.shield_outlined,
        ),
      Text(
        'Scheme characteristics',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      if (isAmfiSampleMode) ...[
        _detail('Scheme type', scheme.schemeType),
        _detail('Scheme code', scheme.schemeCode),
        _detail('ISIN payout/growth', scheme.isinDivPayoutOrGrowth),
        _detail('ISIN reinvestment', scheme.isinDivReinvestment),
        _detail('Data source', scheme.dataSource),
      ],
      if (!isAmfiSampleMode) ...[
        _detail('Benchmark', scheme.benchmarkName),
        _detail(
          'Expense ratio',
          scheme.expenseRatio == null
              ? null
              : '${scheme.expenseRatio!.toStringAsFixed(3)}%',
        ),
        _detail(
          'AUM',
          scheme.aum == null ? null : '₹${scheme.aum!.toStringAsFixed(0)}',
        ),
        _detail('Exit load', scheme.exitLoad),
        _detail('Minimum lump sum', scheme.minimumLumpsum?.toStringAsFixed(0)),
        _detail('Minimum SIP', scheme.minimumSip?.toStringAsFixed(0)),
        _detail('Inception date', scheme.inceptionDate),
        _detail('Fund manager', scheme.fundManager),
        _detail('Scheme code', scheme.schemeCode),
        _detail('ISIN', scheme.isin),
        _detail('Scheme status', scheme.schemeStatus),
        _detail('Objective', scheme.investmentObjective),
      ],
    ],
  );

  Widget _metadataTag(String label) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.blue.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width)
            ? 5
            : 7,
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: AppColors.navy),
      ),
    ),
  );

  Widget _detail(String label, String? value) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(value == null || value.isEmpty ? 'Unavailable' : value),
  );

  Widget _error(Object? error) => Center(
    child: Padding(
      padding: EdgeInsets.all(
        AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width) ? 18 : 24,
      ),
      child: Text(
        error is AppException ? error.message : 'Unable to load this scheme.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class _MockDataDisclosure extends StatelessWidget {
  const _MockDataDisclosure();
  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.warning.withValues(alpha: .12),
    child: const Padding(
      padding: EdgeInsets.all(12),
      child: Text(
        'DEMO DATA ONLY — synthetic test data; not actual schemes or market performance.',
      ),
    ),
  );
}

class _NavChartPainter extends CustomPainter {
  _NavChartPainter(this.points);
  final List<NavPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || size.isEmpty) return;
    const horizontalInset = 12.0;
    const verticalInset = 14.0;
    final values = points.map((point) => point.nav);
    final minimum = values.reduce((a, b) => a < b ? a : b);
    final maximum = values.reduce((a, b) => a > b ? a : b);
    final spread = maximum - minimum;
    final paint = Paint()
      ..color = AppColors.blue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    for (var index = 0; index < points.length; index++) {
      final x =
          horizontalInset +
          (size.width - horizontalInset * 2) * index / (points.length - 1);
      final normalized = spread == 0
          ? .5
          : (points[index].nav - minimum) / spread;
      final y =
          size.height -
          verticalInset -
          (size.height - verticalInset * 2) * normalized;
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
    final baseline = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      baseline,
    );
  }

  @override
  bool shouldRepaint(covariant _NavChartPainter oldDelegate) =>
      !identical(points, oldDelegate.points);
}

String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
