import '../domain/amfi_scheme_classification.dart';
import '../domain/mutual_fund_scheme.dart';
import 'mutual_fund_repository.dart';

class MockMutualFundRepository implements MutualFundRepository {
  MockMutualFundRepository() {
    final today = DateTime.now();
    _schemes = [
      _scheme(
        id: '00000000-0000-4000-8000-000000000001',
        code: 'DEMO-EQ-G',
        name: '[DEMO DATA] Illustrative Equity Growth Fund',
        category: 'Demo Equity',
        categoryCode: 'DEMO-EQUITY',
        assetClass: 'Equity',
        option: 'GROWTH',
        risk: 'HIGH',
        nav: 22.63,
        expense: 1.25,
        date: today,
      ),
      _scheme(
        id: '00000000-0000-4000-8000-000000000002',
        code: 'DEMO-DEBT-G',
        name: '[DEMO DATA] Illustrative Short Duration Fund',
        category: 'Demo Debt',
        categoryCode: 'DEMO-DEBT',
        assetClass: 'Debt',
        option: 'GROWTH',
        risk: 'MODERATE',
        nav: 12.63,
        expense: 0.65,
        date: today,
      ),
      _scheme(
        id: '00000000-0000-4000-8000-000000000003',
        code: 'DEMO-HYBRID-IDCW',
        name: '[DEMO DATA] Illustrative Hybrid IDCW Fund',
        category: 'Demo Hybrid',
        categoryCode: 'DEMO-HYBRID',
        assetClass: 'Hybrid',
        option: 'IDCW',
        risk: 'MODERATELY_HIGH',
        nav: 14.63,
        expense: null,
        date: today,
      ),
    ];
  }

  late final List<MutualFundScheme> _schemes;
  final Set<String> _watchlist = {};

  @override
  Future<List<MutualFundFilterOption>> categories() async => [
    for (final scheme in _schemes.toSet())
      MutualFundFilterOption(
        code: scheme.categoryCode,
        name: scheme.category,
        assetClass: scheme.assetClass,
      ),
  ];

  @override
  Future<List<MutualFundFilterOption>> amcs() async => const [
    MutualFundFilterOption(
      code: 'DEMO-AMC',
      name: '[DEMO DATA] Demo Asset Management Company',
    ),
  ];

  MutualFundScheme _scheme({
    required String id,
    required String code,
    required String name,
    required String category,
    required String categoryCode,
    required String assetClass,
    required String option,
    required String risk,
    required double nav,
    required double? expense,
    required DateTime date,
  }) => MutualFundScheme(
    id: id,
    schemeCode: code,
    schemeName: name,
    amcName: '[DEMO DATA] Demo Asset Management Company',
    category: category,
    categoryCode: categoryCode,
    assetClass: assetClass,
    subCategory: category,
    planType: 'REGULAR',
    optionType: option,
    riskometer: risk,
    schemeStatus: 'ACTIVE',
    latestNav: nav,
    latestNavDate: _date(date),
    expenseRatio: expense,
    mockData: true,
    dataSource: 'MOCK_DEMO',
    schemeType: 'Open Ended',
    benchmarkName: 'Illustrative benchmark (demo only)',
    inceptionDate: _date(DateTime(date.year - 3, date.month, date.day)),
    aum: null,
    exitLoad: 'Demo only - not an actual scheme',
    minimumLumpsum: null,
    minimumSip: null,
    investmentObjective:
        'Illustrative purpose only. Not an actual investment scheme.',
    description: 'Synthetic test fixture; not a real mutual fund.',
    performance: _metrics(id, nav, option),
  );

  @override
  Future<SchemePage> search({
    String? query,
    String? category,
    String? amc,
    List<String>? amcIds,
    String? schemeClass,
    String? marketCap,
    String? risk,
    String? subCategory,
    String? planType,
    String? optionType,
    double? minExpenseRatio,
    double? maxExpenseRatio,
    int page = 0,
    String sortBy = 'schemeName',
    String sortDirection = 'ASC',
  }) async {
    var filtered = _schemes.where((scheme) {
      final normalized = query?.trim().toLowerCase() ?? '';
      return (normalized.isEmpty ||
              scheme.schemeName.toLowerCase().contains(normalized) ||
              scheme.schemeCode.toLowerCase().contains(normalized) ||
              scheme.amcName.toLowerCase().contains(normalized) ||
              scheme.category.toLowerCase().contains(normalized)) &&
          (category == null || scheme.categoryCode == category) &&
          (risk == null || scheme.riskometer == risk) &&
          (amc == null || amc == 'DEMO-AMC') &&
          (amcIds == null || amcIds.isEmpty || amcIds.contains('DEMO-AMC')) &&
          (schemeClass == null ||
              AmfiSchemeClassification.schemeClass(scheme.category) ==
                  schemeClass) &&
          (marketCap == null ||
              AmfiSchemeClassification.marketCap(scheme.category) ==
                  marketCap) &&
          (subCategory == null || scheme.subCategory == subCategory) &&
          (planType == null || scheme.planType == planType) &&
          (optionType == null || scheme.optionType == optionType) &&
          (minExpenseRatio == null ||
              (scheme.expenseRatio != null &&
                  scheme.expenseRatio! >= minExpenseRatio)) &&
          (maxExpenseRatio == null ||
              (scheme.expenseRatio != null &&
                  scheme.expenseRatio! <= maxExpenseRatio));
    }).toList();
    filtered.sort((a, b) {
      final comparison = switch (sortBy) {
        'latestNavDate' => (a.latestNavDate ?? '').compareTo(
          b.latestNavDate ?? '',
        ),
        'expenseRatio' => (a.expenseRatio ?? double.infinity).compareTo(
          b.expenseRatio ?? double.infinity,
        ),
        'aum' => (a.aum ?? 0).compareTo(b.aum ?? 0),
        _ => a.schemeName.compareTo(b.schemeName),
      };
      return sortDirection == 'DESC' ? -comparison : comparison;
    });
    return SchemePage(
      items: filtered,
      page: 0,
      totalPages: filtered.isEmpty ? 0 : 1,
      totalElements: filtered.length,
    );
  }

  @override
  Future<MutualFundScheme> details(String id) async => _find(id);

  @override
  Future<NavHistory> navHistory(String id, {required String range}) async {
    final scheme = _find(id);
    final months = switch (range) {
      '1M' => 1,
      '3M' => 3,
      '6M' => 6,
      '1Y' => 12,
      '3Y' => 36,
      '5Y' => 60,
      '10Y' => 120,
      _ => 120,
    };
    final today = DateTime.now();
    final points = <NavPoint>[];
    for (var month = months; month >= 0; month--) {
      final date = DateTime(today.year, today.month - month, 1);
      final base = scheme.assetClass == 'Debt' ? 10.0 : 20.0;
      points.add(
        NavPoint(
          date: date,
          nav:
              base +
              (months - month) * (scheme.optionType == 'IDCW' ? .045 : .0731),
        ),
      );
    }
    return NavHistory(
      points: points,
      mockData: true,
      dataSource: 'MOCK_DEMO (synthetic test data)',
      navDate: points.last.date.toIso8601String(),
      importedAt: today.toUtc().toIso8601String(),
    );
  }

  @override
  Future<List<PerformanceMetric>> performance(String id) async =>
      _find(id).performance;

  @override
  Future<List<MutualFundScheme>> compare(List<String> ids) async =>
      ids.map(_find).toList();

  @override
  Future<List<MutualFundScheme>> watchlist() async =>
      _schemes.where((scheme) => _watchlist.contains(scheme.id)).toList();

  @override
  Future<void> addToWatchlist(String id) async {
    _find(id);
    _watchlist.add(id);
  }

  @override
  Future<void> removeFromWatchlist(String id) async => _watchlist.remove(id);

  MutualFundScheme _find(String id) => _schemes.firstWhere(
    (scheme) => scheme.id == id,
    orElse: () => throw StateError('Scheme not found'),
  );

  List<PerformanceMetric> _metrics(String id, double latest, String option) {
    final values = <PerformanceMetric>[];
    for (final period in ['1M', '3M', '6M', '1Y', '3Y', '5Y', '10Y']) {
      final years = switch (period) {
        '1M' => 1 / 12,
        '3M' => .25,
        '6M' => .5,
        '1Y' => 1.0,
        '3Y' => 3.0,
        '5Y' => 5.0,
        _ => null,
      };
      final available = years != null;
      final ratio = available ? 1 + .10 * years : 1.0;
      values.add(
        PerformanceMetric(
          period: period,
          value: available ? ((ratio - 1) * 100) : null,
          status: available ? 'AVAILABLE' : 'UNAVAILABLE',
          methodology: years != null && years > 1
              ? 'NAV_BASED_CAGR'
              : 'NAV_BASED_ABSOLUTE',
          startDate: null,
          endDate: null,
          asOfDate: _date(DateTime.now()),
          distributionsIncluded: false,
          dataSource: 'MOCK_DEMO',
        ),
      );
    }
    return values;
  }

  String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
