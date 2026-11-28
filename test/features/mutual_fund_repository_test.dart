import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:surgam_capital/features/mutual_funds/data/amfi_sample_mutual_fund_repository.dart';
import 'package:surgam_capital/features/mutual_funds/data/mock_mutual_fund_repository.dart';
import 'package:surgam_capital/features/mutual_funds/data/mutual_fund_providers.dart';
import 'package:surgam_capital/features/mutual_funds/domain/amfi_scheme_classification.dart';
import 'package:surgam_capital/features/mutual_funds/domain/mutual_fund_scheme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Explore uses the bundled AMFI snapshot by default', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(isAmfiSampleMode, isTrue);
    expect(
      container.read(mutualFundRepositoryProvider),
      isA<AmfiSampleMutualFundRepository>(),
    );
  });

  group('AmfiSampleMutualFundRepository', () {
    late AmfiSampleMutualFundRepository repository;

    setUp(() {
      repository = AmfiSampleMutualFundRepository();
    });

    test(
      'loads only captured AMFI schemes and preserves NAV provenance',
      () async {
        final result = await repository.search();
        final scheme = await repository.details('119769');

        expect(result.items, hasLength(103));
        expect(scheme.schemeName, 'Kotak Contra Fund');
        expect(scheme.schemeCode, '119769');
        expect(scheme.latestNav, 188.505);
        expect(scheme.latestNavDate, '2026-11-20');
        expect(scheme.dataSource, 'AMFI (captured sample)');
        expect(scheme.mockData, isFalse);
        expect(scheme.expenseRatio, isNull);
      },
    );

    test('every AMFI category has one selectable captured scheme', () async {
      final categories = await repository.categories();
      final contraCategory = categories.singleWhere(
        (option) => option.name == 'Equity Scheme - Contra Fund',
      );
      final result = await repository.search(
        category: contraCategory.code,
        planType: 'DIRECT',
      );

      expect(categories, hasLength(103));
      expect(categories.map((option) => option.code).toSet(), hasLength(103));
      expect(result.items, hasLength(1));
      expect(result.items.single.category, "Equity Scheme - Contra Fund");
      expect(result.items.single.categoryCode, contraCategory.code);
      expect(result.items.single.planType, 'DIRECT');
    });

    test('scheme-class and market-cap filters use category labels', () async {
      final equity = await repository.search(schemeClass: 'Equity');
      final largeCap = await repository.search(marketCap: 'Large Cap');

      expect(equity.items, isNotEmpty);
      expect(
        equity.items.every(
          (scheme) =>
              AmfiSchemeClassification.schemeClass(scheme.category) == 'Equity',
        ),
        isTrue,
      );
      expect(largeCap.items, isNotEmpty);
      expect(
        largeCap.items.every(
          (scheme) =>
              AmfiSchemeClassification.marketCap(scheme.category) ==
              'Large Cap',
        ),
        isTrue,
      );
    });

    test('multiple AMC selections are combined as OR filters', () async {
      final amcs = await repository.amcs();
      final selected = amcs.take(2).map((amc) => amc.code).toList();
      final result = await repository.search(amcIds: selected);

      expect(selected, hasLength(2));
      expect(result.items, isNotEmpty);
      expect(
        result.items.every((scheme) => selected.contains(scheme.amcName)),
        isTrue,
      );
    });

    test('does not present a captured latest NAV as historical data', () async {
      final history = await repository.navHistory('119769', range: '1Y');

      expect(history.points, isEmpty);
      expect(history.dataSource, contains('history not included'));
    });
  });

  group('AmfiSchemeClassification', () {
    test('classifies AMFI scheme categories into requested groups', () {
      expect(
        AmfiSchemeClassification.schemeClass('Equity Scheme - ELSS'),
        'ELSS',
      );
      expect(
        AmfiSchemeClassification.schemeClass('Overseas Fund'),
        'International',
      );
      expect(AmfiSchemeClassification.schemeClass('Gold ETF'), 'Gold/Silver');
      expect(AmfiSchemeClassification.schemeClass('Index Fund'), 'Index');
      expect(AmfiSchemeClassification.schemeClass('Hybrid ETF'), 'Hybrid');
      expect(AmfiSchemeClassification.schemeClass('Debt ETF'), 'Index');
      expect(
        AmfiSchemeClassification.schemeClass('Equity Scheme - Large Cap'),
        'Equity',
      );
      expect(
        AmfiSchemeClassification.schemeClass('Debt Scheme - Gilt'),
        'Debt',
      );
      expect(
        AmfiSchemeClassification.schemeClass('Hybrid Scheme - Balanced'),
        'Hybrid',
      );
      expect(AmfiSchemeClassification.schemeClass('Other Scheme'), 'Other');
    });

    test('only exposes market-cap styles present in the category name', () {
      expect(
        AmfiSchemeClassification.marketCap('Equity Scheme - Large Cap Fund'),
        'Large Cap',
      );
      expect(
        AmfiSchemeClassification.marketCap(
          'Equity Scheme - Large & Mid Cap Fund',
        ),
        'Large & Mid Cap',
      );
      expect(
        AmfiSchemeClassification.marketCap('Debt Scheme - Liquid Fund'),
        isNull,
      );
    });
  });

  group('MockMutualFundRepository', () {
    late MockMutualFundRepository repository;

    setUp(() {
      repository = MockMutualFundRepository();
    });

    test('search applies query, category and risk filters', () async {
      final result = await repository.search(
        query: 'equity',
        category: 'DEMO-EQUITY',
        risk: 'HIGH',
        page: 0,
        sortBy: 'schemeName',
      );

      expect(result.items, hasLength(1));
      expect(result.items.single.mockData, isTrue);
      expect(result.items.single.schemeName, contains('Equity'));
    });

    test('search applies plan, option and expense range filters', () async {
      final result = await repository.search(
        planType: 'REGULAR',
        optionType: 'GROWTH',
        minExpenseRatio: 1.2,
        maxExpenseRatio: 1.3,
      );

      expect(result.items, hasLength(1));
      expect(result.items.single.categoryCode, 'DEMO-EQUITY');
      expect(result.items.single.expenseRatio, 1.25);
    });

    test('watchlist saves are idempotent and removable', () async {
      const schemeId = '00000000-0000-4000-8000-000000000001';

      await repository.addToWatchlist(schemeId);
      await repository.addToWatchlist(schemeId);
      expect(await repository.watchlist(), hasLength(1));

      await repository.removeFromWatchlist(schemeId);
      expect(await repository.watchlist(), isEmpty);
    });

    test('demo NAV and performance stay explicitly marked', () async {
      const schemeId = '00000000-0000-4000-8000-000000000001';

      final history = await repository.navHistory(schemeId, range: '1Y');
      final metrics = await repository.performance(schemeId);

      expect(history.mockData, isTrue);
      expect(history.points, isNotEmpty);
      expect(metrics.first.dataSource, 'MOCK_DEMO');
      expect(
        metrics.singleWhere((metric) => metric.period == '10Y').status,
        'UNAVAILABLE',
      );
    });
  });

  test('comparison selection never exceeds four schemes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final selection = container.read(comparisonSelectionProvider.notifier);

    for (var index = 0; index < 5; index++) {
      selection.toggle(_scheme('$index'));
    }

    expect(container.read(comparisonSelectionProvider), hasLength(4));
    selection.toggle(_scheme('0'));
    expect(container.read(comparisonSelectionProvider), hasLength(3));
  });
}

MutualFundScheme _scheme(String id) => MutualFundScheme(
  id: id,
  schemeCode: id,
  schemeName: 'Test scheme $id',
  amcName: 'Test AMC',
  category: 'Test',
  categoryCode: 'TEST',
  assetClass: 'Equity',
  planType: 'REGULAR',
  optionType: 'GROWTH',
  schemeStatus: 'ACTIVE',
  mockData: true,
);
