import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';
import '../data/mutual_fund_providers.dart';
import '../domain/mutual_fund_scheme.dart';

class SchemeComparisonScreen extends ConsumerWidget {
  const SchemeComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    final selected = ref.watch(comparisonSelectionProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare schemes'),
        actions: [
          if (selected.isNotEmpty)
            TextButton(
              onPressed: () =>
                  ref.read(comparisonSelectionProvider.notifier).clear(),
              child: const Text('Clear'),
            ),
        ],
      ),
      body: AppAdaptiveBody(
        selectedIndex: 0,
        child: selected.isEmpty
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Select up to four schemes to compare.'),
                      SizedBox(height: isMobile ? 10 : 12),
                      FilledButton(
                        onPressed: () => context.go(AppRoutes.schemeDiscovery),
                        child: const Text('Explore schemes'),
                      ),
                    ],
                  ),
                ),
              )
            : FutureBuilder<List<MutualFundScheme>>(
                future: ref
                    .read(mutualFundRepositoryProvider)
                    .compare(selected.map((scheme) => scheme.id).toList()),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        child: Text(
                          'Unable to compare schemes: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return _comparisonTable(context, snapshot.data ?? const []);
                },
              ),
      ),
    );
  }

  Widget _comparisonTable(
    BuildContext context,
    List<MutualFundScheme> schemes,
  ) {
    final optionTypes = schemes.map((scheme) => scheme.optionType).toSet();
    final categories = schemes.map((scheme) => scheme.categoryCode).toSet();
    return ListView(
      padding: EdgeInsets.all(
        AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width) ? 12 : 16,
      ),
      children: [
        if (schemes.any((scheme) => scheme.mockData))
          const Card(
            color: Color(0xFFFFF4DF),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'DEMO DATA ONLY — synthetic test data; not actual schemes or market performance.',
              ),
            ),
          ),
        if (optionTypes.length > 1 || categories.length > 1)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'These schemes have different options or categories. Returns and risk may not be directly comparable.',
              ),
            ),
          ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              const DataColumn(label: Text('Characteristic')),
              for (final scheme in schemes)
                DataColumn(
                  label: SizedBox(
                    width: 190,
                    child: Text(
                      scheme.schemeName,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
            rows: [
              _row('AMC', schemes.map((scheme) => scheme.amcName).toList()),
              _row(
                'Category',
                schemes.map((scheme) => scheme.category).toList(),
              ),
              _row(
                'Plan / option',
                schemes
                    .map(
                      (scheme) => '${scheme.planType} / ${scheme.optionType}',
                    )
                    .toList(),
              ),
              _row(
                'Riskometer',
                schemes
                    .map((scheme) => scheme.riskometer ?? 'Unavailable')
                    .toList(),
              ),
              _row(
                'Latest NAV',
                schemes
                    .map(
                      (scheme) =>
                          scheme.latestNav?.toStringAsFixed(4) ?? 'Unavailable',
                    )
                    .toList(),
              ),
              _row(
                'NAV date',
                schemes
                    .map((scheme) => scheme.latestNavDate ?? 'Unavailable')
                    .toList(),
              ),
              _row(
                'Expense ratio',
                schemes
                    .map(
                      (scheme) => scheme.expenseRatio == null
                          ? 'Unavailable'
                          : '${scheme.expenseRatio!.toStringAsFixed(3)}%',
                    )
                    .toList(),
              ),
              _row(
                'Benchmark',
                schemes
                    .map((scheme) => scheme.benchmarkName ?? 'Unavailable')
                    .toList(),
              ),
              for (final period in const ['1Y', '3Y', '5Y', '10Y'])
                _row(
                  '$period NAV return',
                  schemes.map((scheme) {
                    final periodMetrics = scheme.performance.where(
                      (item) => item.period == period,
                    );
                    final metric = periodMetrics.isEmpty
                        ? null
                        : periodMetrics.first;
                    if (metric == null ||
                        metric.status != 'AVAILABLE' ||
                        metric.value == null) {
                      return 'Unavailable';
                    }
                    return '${metric.value!.toStringAsFixed(2)}%';
                  }).toList(),
                ),
            ],
          ),
        ),
        SizedBox(
          height: AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width)
              ? 12
              : 16,
        ),
        const Text(
          'NAV-based performance excludes distributions and is not a prediction. Past performance is not indicative of future returns. This comparison is informational, not personalized investment advice.',
        ),
        SizedBox(
          height: AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width)
              ? 6
              : 8,
        ),
        for (final scheme in schemes)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () =>
                  context.push('${AppRoutes.schemeDetail}/${scheme.id}'),
              child: Text('View ${scheme.schemeName}'),
            ),
          ),
      ],
    );
  }

  DataRow _row(String label, List<String> values) => DataRow(
    cells: [
      DataCell(Text(label)),
      for (final value in values) DataCell(Text(value)),
    ],
  );
}
