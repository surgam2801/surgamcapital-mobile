import '../domain/demo_portfolio.dart';

const portfolioDemoMode = bool.fromEnvironment(
  'PORTFOLIO_DEMO_MODE',
  defaultValue: false,
);

class DemoPortfolioRepository {
  const DemoPortfolioRepository();

  final holdings = const <DemoHolding>[
    DemoHolding(
      id: 'demo-large-cap',
      schemeName: '[DEMO] Summit Large Cap Fund',
      amcName: '[DEMO] Summit Asset Management',
      category: 'Large Cap Equity',
      assetClass: 'Equity',
      invested: 200000,
      currentValue: 250000,
      units: 2000,
      latestNav: 125,
      navDate: '2026-11-20',
      averagePurchaseNav: 100,
      folio: 'DEMO-1001',
      xirr: 15.1,
      plan: 'Direct',
      option: 'Growth',
    ),
    DemoHolding(
      id: 'demo-flexi-cap',
      schemeName: '[DEMO] Cedar Flexi Cap Fund',
      amcName: '[DEMO] Cedar Asset Management',
      category: 'Flexi Cap Equity',
      assetClass: 'Equity',
      invested: 180000,
      currentValue: 225000,
      units: 1500,
      latestNav: 150,
      navDate: '2026-11-20',
      averagePurchaseNav: 120,
      folio: 'DEMO-1002',
      xirr: 15.8,
      plan: 'Direct',
      option: 'Growth',
    ),
    DemoHolding(
      id: 'demo-mid-cap',
      schemeName: '[DEMO] Harbor Mid Cap Fund',
      amcName: '[DEMO] Harbor Asset Management',
      category: 'Mid Cap Equity',
      assetClass: 'Equity',
      invested: 140000,
      currentValue: 180000,
      units: 1000,
      latestNav: 180,
      navDate: '2026-11-20',
      averagePurchaseNav: 140,
      folio: 'DEMO-1003',
      xirr: 17.2,
      plan: 'Direct',
      option: 'Growth',
    ),
    DemoHolding(
      id: 'demo-index',
      schemeName: '[DEMO] Meridian Nifty 50 Index Fund',
      amcName: '[DEMO] Meridian Asset Management',
      category: 'Nifty 50 Index',
      assetClass: 'Equity',
      invested: 120000,
      currentValue: 145000,
      units: 1000,
      latestNav: 145,
      navDate: '2026-11-20',
      averagePurchaseNav: 120,
      folio: 'DEMO-1004',
      xirr: 13.9,
      plan: 'Direct',
      option: 'Growth',
    ),
    DemoHolding(
      id: 'demo-debt',
      schemeName: '[DEMO] Willow Short Duration Fund',
      amcName: '[DEMO] Willow Asset Management',
      category: 'Short Duration Debt',
      assetClass: 'Debt',
      invested: 120000,
      currentValue: 130000,
      units: 10000,
      latestNav: 13,
      navDate: '2026-11-20',
      averagePurchaseNav: 12,
      folio: 'DEMO-1005',
      xirr: 7.4,
      plan: 'Direct',
      option: 'Growth',
    ),
    DemoHolding(
      id: 'demo-hybrid',
      schemeName: '[DEMO] Juniper Aggressive Hybrid Fund',
      amcName: '[DEMO] Juniper Asset Management',
      category: 'Aggressive Hybrid',
      assetClass: 'Hybrid',
      invested: 90000,
      currentValue: 95000,
      units: 5000,
      latestNav: 19,
      navDate: '2026-11-20',
      averagePurchaseNav: 18,
      folio: 'DEMO-1006',
      xirr: 6.3,
      plan: 'Direct',
      option: 'Growth',
    ),
  ];

  final sips = const <DemoSip>[
    DemoSip(
      id: 'demo-sip-1',
      schemeName: '[DEMO] Summit Large Cap Fund',
      monthlyAmount: 25000,
      sipDay: 5,
      startDate: '2023-02-05',
      nextInstallment: '2026-12-05',
      installments: 46,
      successfulInstallments: 45,
      status: 'Active',
      mandateStatus: 'Demo mandate active',
    ),
    DemoSip(
      id: 'demo-sip-2',
      schemeName: '[DEMO] Cedar Flexi Cap Fund',
      monthlyAmount: 15000,
      sipDay: 10,
      startDate: '2024-01-10',
      nextInstallment: '2026-12-10',
      installments: 35,
      successfulInstallments: 35,
      status: 'Upcoming',
      mandateStatus: 'Demo mandate active',
    ),
    DemoSip(
      id: 'demo-sip-3',
      schemeName: '[DEMO] Harbor Mid Cap Fund',
      monthlyAmount: 10000,
      sipDay: 15,
      startDate: '2022-09-15',
      nextInstallment: '— (paused)',
      installments: 24,
      successfulInstallments: 20,
      status: 'Paused',
      mandateStatus: 'Demo mandate paused',
    ),
    DemoSip(
      id: 'demo-sip-4',
      schemeName: '[DEMO] Meridian Nifty 50 Index Fund',
      monthlyAmount: 5000,
      sipDay: 20,
      startDate: '2021-06-20',
      nextInstallment: '— (completed)',
      installments: 12,
      successfulInstallments: 12,
      status: 'Completed',
      mandateStatus: 'Demo mandate ended',
    ),
  ];

  final transactions = const <DemoTransaction>[
    DemoTransaction(
      date: '2026-11-05',
      schemeName: '[DEMO] Summit Large Cap Fund',
      type: 'SIP installment',
      amount: 25000,
      units: 200,
      status: 'Confirmed (demo)',
    ),
    DemoTransaction(
      date: '2026-10-10',
      schemeName: '[DEMO] Cedar Flexi Cap Fund',
      type: 'Purchase',
      amount: 15000,
      units: 100,
      status: 'Confirmed (demo)',
    ),
    DemoTransaction(
      date: '2026-09-18',
      schemeName: '[DEMO] Harbor Mid Cap Fund',
      type: 'Redemption',
      amount: 5000,
      units: 27.78,
      status: 'Confirmed (demo)',
    ),
    DemoTransaction(
      date: '2026-08-12',
      schemeName: '[DEMO] Meridian Nifty 50 Index Fund',
      type: 'Switch',
      amount: 10000,
      units: 68.97,
      status: 'Confirmed (demo)',
    ),
    DemoTransaction(
      date: '2026-07-05',
      schemeName: '[DEMO] Willow Short Duration Fund',
      type: 'Purchase',
      amount: 20000,
      units: 1538.46,
      status: 'Confirmed (demo)',
    ),
  ];

  final orders = const <DemoOrder>[
    DemoOrder(
      date: '2026-11-22',
      schemeName: '[DEMO] Summit Large Cap Fund',
      type: 'Purchase',
      amount: 10000,
      status: 'Pending',
    ),
    DemoOrder(
      date: '2026-11-18',
      schemeName: '[DEMO] Cedar Flexi Cap Fund',
      type: 'Switch',
      amount: 25000,
      status: 'Processing',
    ),
    DemoOrder(
      date: '2026-11-10',
      schemeName: '[DEMO] Harbor Mid Cap Fund',
      type: 'Purchase',
      amount: 15000,
      status: 'Successful',
    ),
    DemoOrder(
      date: '2026-11-02',
      schemeName: '[DEMO] Willow Short Duration Fund',
      type: 'Purchase',
      amount: 5000,
      status: 'Failed',
    ),
  ];

  DemoPortfolioSummary get summary => DemoPortfolioSummary(
    invested: holdings.fold(0, (total, holding) => total + holding.invested),
    currentValue: holdings.fold(
      0,
      (total, holding) => total + holding.currentValue,
    ),
    xirr: 14.8,
    lastUpdated: DateTime(2026, 11, 23),
  );

  double get monthlySipCommitment => sips
      .where((sip) => sip.status == 'Active' || sip.status == 'Upcoming')
      .fold(0, (total, sip) => total + sip.monthlyAmount);

  int get scheduledSipCount => sips
      .where((sip) => sip.status == 'Active' || sip.status == 'Upcoming')
      .length;

  List<DemoPerformancePoint> performance({String range = 'ALL'}) {
    final now = DateTime.now();
    const monthsByRange = {'1M': 1, '3M': 3, '6M': 6, '1Y': 12, '3Y': 36};
    final months = monthsByRange[range] ?? 36;
    final start = DateTime(now.year, now.month - months, 1);
    final points = <DemoPerformancePoint>[];
    for (var month = months; month >= 0; month--) {
      final date = DateTime(now.year, now.month - month, 1);
      final progress = (months - month) / months;
      points.add(
        DemoPerformancePoint(
          date: date,
          invested: summary.invested * (0.12 + 0.88 * progress),
          value: summary.currentValue * (0.11 + 0.89 * progress),
        ),
      );
    }
    return points.where((point) => !point.date.isBefore(start)).toList();
  }

  List<DemoAllocation> allocation(String groupBy) {
    final grouped = <String, double>{};
    for (final holding in holdings) {
      final key = switch (groupBy) {
        'Category' => holding.category,
        'AMC' => holding.amcName,
        'Scheme' => holding.schemeName,
        _ => holding.assetClass,
      };
      grouped.update(
        key,
        (value) => value + holding.currentValue,
        ifAbsent: () => holding.currentValue,
      );
    }
    final entries = grouped.entries.toList()
      ..sort((first, second) => second.value.compareTo(first.value));
    return [
      for (var index = 0; index < entries.length; index++)
        DemoAllocation(
          name: entries[index].key,
          value: entries[index].value,
          colorIndex: index,
        ),
    ];
  }

  DemoHolding? holding(String id) {
    for (final item in holdings) {
      if (item.id == id) return item;
    }
    return null;
  }
}
