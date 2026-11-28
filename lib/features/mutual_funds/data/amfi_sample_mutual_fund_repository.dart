import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/amfi_scheme_classification.dart';
import '../domain/mutual_fund_scheme.dart';
import 'mutual_fund_repository.dart';

class AmfiSampleMutualFundRepository implements MutualFundRepository {
  Future<List<MutualFundScheme>>? _schemesFuture;
  final Set<String> _watchlist = {};

  Future<List<MutualFundScheme>> get _schemes =>
      _schemesFuture ??= _loadSchemes();

  Future<List<MutualFundScheme>> _loadSchemes() async {
    final contents = await rootBundle.loadString(
      'assets/data/amfi_nav_sample.json',
    );
    final snapshot = jsonDecode(contents) as Map<String, dynamic>;
    final records = snapshot['schemes'] as List<dynamic>;
    final fetchedAt = snapshot['fetchedAt'] as String;
    return records
        .map((value) {
          final record = value as Map<String, dynamic>;
          final category = record['category'] as String;
          final schemeType = record['schemeType'] as String;
          final plan = record['plan'] as String;
          final option = record['option'] as String;
          final primaryIsin = record['isinDivPayoutOrGrowth'] as String?;
          final reinvestmentIsin = record['isinDivReinvestment'] as String?;
          return MutualFundScheme(
            id: record['schemeCode'] as String,
            schemeCode: record['schemeCode'] as String,
            isin: primaryIsin ?? reinvestmentIsin,
            isinDivPayoutOrGrowth: primaryIsin,
            isinDivReinvestment: reinvestmentIsin,
            schemeName: record['schemeName'] as String,
            amcName: record['amcName'] as String,
            category: category,
            categoryCode:
                '${schemeType.toUpperCase().replaceAll(' ', '_')}:$category',
            assetClass: AmfiSchemeClassification.schemeClass(category),
            planType: plan.toLowerCase().contains('direct')
                ? 'DIRECT'
                : plan.toLowerCase().contains('regular')
                ? 'REGULAR'
                : 'UNKNOWN',
            optionType: option.toLowerCase().contains('growth')
                ? 'GROWTH'
                : option.toLowerCase().contains('idcw') ||
                      option.toLowerCase().contains('dividend')
                ? 'IDCW'
                : 'UNKNOWN',
            schemeStatus: 'UNKNOWN',
            mockData: false,
            dataSource: 'AMFI (captured sample)',
            schemeType: schemeType,
            latestNav: (record['nav'] as num).toDouble(),
            latestNavDate: record['navDate'] as String,
            sourceUpdatedAt: fetchedAt,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<MutualFundFilterOption>> categories() async {
    final schemes = await _schemes;
    final categories = <String, MutualFundFilterOption>{};
    for (final scheme in schemes) {
      categories[scheme.categoryCode] = MutualFundFilterOption(
        code: scheme.categoryCode,
        name: scheme.category,
        assetClass: scheme.assetClass,
      );
    }
    return categories.values.toList(growable: false);
  }

  @override
  Future<List<MutualFundFilterOption>> amcs() async {
    final schemes = await _schemes;
    final values = <String, MutualFundFilterOption>{};
    for (final scheme in schemes) {
      values[scheme.amcName] = MutualFundFilterOption(
        code: scheme.amcName,
        name: scheme.amcName,
      );
    }
    return values.values.toList(growable: false);
  }

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
    final normalizedQuery = query?.trim().toLowerCase() ?? '';
    final results = (await _schemes).where((scheme) {
      final matchesQuery =
          normalizedQuery.isEmpty ||
          scheme.schemeName.toLowerCase().contains(normalizedQuery) ||
          scheme.schemeCode.toLowerCase().contains(normalizedQuery) ||
          (scheme.isin?.toLowerCase().contains(normalizedQuery) ?? false) ||
          scheme.amcName.toLowerCase().contains(normalizedQuery) ||
          scheme.category.toLowerCase().contains(normalizedQuery);
      return matchesQuery &&
          (category == null || scheme.categoryCode == category) &&
          (amc == null || scheme.amcName == amc) &&
          (amcIds == null ||
              amcIds.isEmpty ||
              amcIds.contains(scheme.amcName)) &&
          (schemeClass == null ||
              AmfiSchemeClassification.schemeClass(scheme.category) ==
                  schemeClass) &&
          (marketCap == null ||
              AmfiSchemeClassification.marketCap(scheme.category) ==
                  marketCap) &&
          (risk == null || scheme.riskometer == risk) &&
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
    results.sort((first, second) {
      final comparison = switch (sortBy) {
        'latestNavDate' => (first.latestNavDate ?? '').compareTo(
          second.latestNavDate ?? '',
        ),
        'expenseRatio' => (first.expenseRatio ?? double.infinity).compareTo(
          second.expenseRatio ?? double.infinity,
        ),
        'aum' => (first.aum ?? 0).compareTo(second.aum ?? 0),
        _ => first.schemeName.compareTo(second.schemeName),
      };
      return sortDirection == 'DESC' ? -comparison : comparison;
    });
    return SchemePage(
      items: results,
      page: 0,
      totalPages: results.isEmpty ? 0 : 1,
      totalElements: results.length,
    );
  }

  @override
  Future<MutualFundScheme> details(String id) async =>
      _find(await _schemes, id);

  @override
  Future<NavHistory> navHistory(String id, {required String range}) async {
    final scheme = _find(await _schemes, id);
    return NavHistory(
      points: const [],
      mockData: false,
      dataSource: 'AMFI (captured latest-NAV sample; history not included)',
      navDate: scheme.latestNavDate,
      importedAt: scheme.sourceUpdatedAt,
    );
  }

  @override
  Future<List<PerformanceMetric>> performance(String id) async => const [];

  @override
  Future<List<MutualFundScheme>> compare(List<String> ids) async {
    final schemes = await _schemes;
    return ids.map((id) => _find(schemes, id)).toList(growable: false);
  }

  @override
  Future<List<MutualFundScheme>> watchlist() async {
    final schemes = await _schemes;
    return schemes
        .where((scheme) => _watchlist.contains(scheme.id))
        .toList(growable: false);
  }

  @override
  Future<void> addToWatchlist(String id) async {
    _find(await _schemes, id);
    _watchlist.add(id);
  }

  @override
  Future<void> removeFromWatchlist(String id) async {
    _watchlist.remove(id);
  }

  MutualFundScheme _find(List<MutualFundScheme> schemes, String id) =>
      schemes.firstWhere(
        (scheme) => scheme.id == id,
        orElse: () => throw StateError('Scheme not found in AMFI sample.'),
      );
}
