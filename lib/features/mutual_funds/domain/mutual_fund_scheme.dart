class PerformanceMetric {
  const PerformanceMetric({
    required this.period,
    required this.status,
    required this.methodology,
    required this.distributionsIncluded,
    this.value,
    this.startDate,
    this.endDate,
    this.asOfDate,
    this.dataSource,
  });

  final String period;
  final double? value;
  final String status;
  final String methodology;
  final String? startDate;
  final String? endDate;
  final String? asOfDate;
  final bool distributionsIncluded;
  final String? dataSource;

  factory PerformanceMetric.fromJson(Map<String, dynamic> json) =>
      PerformanceMetric(
        period: json['period'] as String,
        value: (json['value'] as num?)?.toDouble(),
        status: json['status'] as String? ?? 'UNAVAILABLE',
        methodology: json['methodology'] as String? ?? 'NAV_BASED',
        startDate: json['startDate'] as String?,
        endDate: json['endDate'] as String?,
        asOfDate: json['asOfDate'] as String?,
        distributionsIncluded: json['distributionsIncluded'] as bool? ?? false,
        dataSource: json['dataSource'] as String?,
      );
}

class MutualFundScheme {
  const MutualFundScheme({
    required this.id,
    required this.schemeCode,
    this.isinDivPayoutOrGrowth,
    this.isinDivReinvestment,
    required this.schemeName,
    required this.amcName,
    required this.category,
    required this.categoryCode,
    required this.assetClass,
    required this.planType,
    required this.optionType,
    required this.schemeStatus,
    required this.mockData,
    this.isin,
    this.subCategory,
    this.riskometer,
    this.latestNav,
    this.latestNavDate,
    this.expenseRatio,
    this.oneYearReturn,
    this.schemeType,
    this.benchmarkName,
    this.inceptionDate,
    this.aum,
    this.exitLoad,
    this.minimumLumpsum,
    this.minimumSip,
    this.investmentObjective,
    this.description,
    this.fundManager,
    this.sourceUpdatedAt,
    this.performance = const [],
    this.dataSource,
  });

  final String id;
  final String schemeCode;
  final String? isin;
  final String? isinDivPayoutOrGrowth;
  final String? isinDivReinvestment;
  final String schemeName;
  final String amcName;
  final String category;
  final String categoryCode;
  final String assetClass;
  final String? subCategory;
  final String planType;
  final String optionType;
  final String? riskometer;
  final String schemeStatus;
  final double? latestNav;
  final String? latestNavDate;
  final double? expenseRatio;
  final PerformanceMetric? oneYearReturn;
  final bool mockData;
  final String? dataSource;
  final String? schemeType;
  final String? benchmarkName;
  final String? inceptionDate;
  final double? aum;
  final String? exitLoad;
  final double? minimumLumpsum;
  final double? minimumSip;
  final String? investmentObjective;
  final String? description;
  final String? fundManager;
  final String? sourceUpdatedAt;
  final List<PerformanceMetric> performance;

  factory MutualFundScheme.fromJson(Map<String, dynamic> json) {
    final metric = json['oneYearReturn'];
    return MutualFundScheme(
      id: json['id'] as String,
      schemeCode: json['schemeCode'] as String? ?? '',
      isin: json['isin'] as String?,
      isinDivPayoutOrGrowth: json['isinDivPayoutOrGrowth'] as String?,
      isinDivReinvestment: json['isinDivReinvestment'] as String?,
      schemeName: json['schemeName'] as String? ?? 'Scheme',
      amcName: json['amcName'] as String? ?? 'AMC unavailable',
      category: json['category'] as String? ?? 'Other',
      categoryCode: json['categoryCode'] as String? ?? '',
      assetClass: json['assetClass'] as String? ?? 'Other',
      subCategory: json['subCategory'] as String?,
      planType: json['planType'] as String? ?? 'REGULAR',
      optionType: json['optionType'] as String? ?? 'UNKNOWN',
      riskometer: json['riskometer'] as String?,
      schemeStatus: json['schemeStatus'] as String? ?? 'UNKNOWN',
      latestNav: (json['latestNav'] as num?)?.toDouble(),
      latestNavDate: json['latestNavDate'] as String?,
      expenseRatio: (json['expenseRatio'] as num?)?.toDouble(),
      oneYearReturn: metric is Map<String, dynamic>
          ? PerformanceMetric.fromJson(metric)
          : null,
      mockData: json['mockData'] as bool? ?? false,
      dataSource:
          json['dataSource'] as String? ?? json['providerCode'] as String?,
      schemeType: json['schemeType'] as String?,
      benchmarkName: json['benchmarkName'] as String?,
      inceptionDate: json['inceptionDate'] as String?,
      aum: (json['aum'] as num?)?.toDouble(),
      exitLoad: json['exitLoad'] as String?,
      minimumLumpsum: (json['minimumLumpsum'] as num?)?.toDouble(),
      minimumSip: (json['minimumSip'] as num?)?.toDouble(),
      investmentObjective: json['investmentObjective'] as String?,
      description: json['description'] as String?,
      fundManager: json['fundManager'] as String?,
      sourceUpdatedAt: json['sourceUpdatedAt'] as String?,
      performance: (json['performance'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PerformanceMetric.fromJson)
          .toList(),
    );
  }
}

class SchemePage {
  const SchemePage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.totalElements,
  });

  final List<MutualFundScheme> items;
  final int page;
  final int totalPages;
  final int totalElements;

  factory SchemePage.fromJson(Map<String, dynamic> json) => SchemePage(
    items: (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(MutualFundScheme.fromJson)
        .toList(),
    page: json['page'] as int? ?? 0,
    totalPages: json['totalPages'] as int? ?? 0,
    totalElements: json['totalElements'] as int? ?? 0,
  );
}

class NavHistory {
  const NavHistory({
    required this.points,
    required this.mockData,
    required this.dataSource,
    this.navDate,
    this.importedAt,
  });
  final List<NavPoint> points;
  final bool mockData;
  final String dataSource;
  final String? navDate;
  final String? importedAt;

  factory NavHistory.fromJson(Map<String, dynamic> json) => NavHistory(
    points: (json['points'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(NavPoint.fromJson)
        .toList(),
    mockData: json['mockData'] as bool? ?? false,
    dataSource: json['dataSource'] as String? ?? 'Unknown source',
    navDate: json['navDate'] as String?,
    importedAt: json['importedAt'] as String?,
  );
}

class NavPoint {
  const NavPoint({required this.date, required this.nav});
  final DateTime date;
  final double nav;

  factory NavPoint.fromJson(Map<String, dynamic> json) => NavPoint(
    date: DateTime.parse(json['date'] as String),
    nav: (json['nav'] as num).toDouble(),
  );
}

class MutualFundFilterOption {
  const MutualFundFilterOption({
    required this.code,
    required this.name,
    this.assetClass,
  });

  final String code;
  final String name;
  final String? assetClass;

  factory MutualFundFilterOption.fromJson(Map<String, dynamic> json) =>
      MutualFundFilterOption(
        code: json['code'] as String,
        name: json['name'] as String,
        assetClass: json['assetClass'] as String?,
      );
}
