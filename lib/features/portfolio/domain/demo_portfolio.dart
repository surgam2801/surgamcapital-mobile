class DemoHolding {
  const DemoHolding({
    required this.id,
    required this.schemeName,
    required this.amcName,
    required this.category,
    required this.assetClass,
    required this.invested,
    required this.currentValue,
    required this.units,
    required this.latestNav,
    required this.navDate,
    required this.averagePurchaseNav,
    required this.folio,
    required this.xirr,
    required this.plan,
    required this.option,
  });

  final String id;
  final String schemeName;
  final String amcName;
  final String category;
  final String assetClass;
  final double invested;
  final double currentValue;
  final double units;
  final double latestNav;
  final String navDate;
  final double averagePurchaseNav;
  final String folio;
  final double xirr;
  final String plan;
  final String option;

  double get gain => currentValue - invested;
  double get returnPercent => invested == 0 ? 0 : gain / invested * 100;
}

class DemoSip {
  const DemoSip({
    required this.id,
    required this.schemeName,
    required this.monthlyAmount,
    required this.sipDay,
    required this.startDate,
    required this.nextInstallment,
    required this.installments,
    required this.successfulInstallments,
    required this.status,
    required this.mandateStatus,
  });

  final String id;
  final String schemeName;
  final double monthlyAmount;
  final int sipDay;
  final String startDate;
  final String nextInstallment;
  final int installments;
  final int successfulInstallments;
  final String status;
  final String mandateStatus;
}

class DemoTransaction {
  const DemoTransaction({
    required this.date,
    required this.schemeName,
    required this.type,
    required this.amount,
    required this.units,
    required this.status,
  });

  final String date;
  final String schemeName;
  final String type;
  final double amount;
  final double units;
  final String status;
}

class DemoOrder {
  const DemoOrder({
    required this.date,
    required this.schemeName,
    required this.type,
    required this.amount,
    required this.status,
  });

  final String date;
  final String schemeName;
  final String type;
  final double amount;
  final String status;
}

class DemoPerformancePoint {
  const DemoPerformancePoint({
    required this.date,
    required this.invested,
    required this.value,
  });

  final DateTime date;
  final double invested;
  final double value;
}

class DemoPortfolioSummary {
  const DemoPortfolioSummary({
    required this.invested,
    required this.currentValue,
    required this.xirr,
    required this.lastUpdated,
  });

  final double invested;
  final double currentValue;
  final double xirr;
  final DateTime lastUpdated;

  double get gain => currentValue - invested;
  double get absoluteReturn => invested == 0 ? 0 : gain / invested * 100;
}

class DemoAllocation {
  const DemoAllocation({
    required this.name,
    required this.value,
    required this.colorIndex,
  });

  final String name;
  final double value;
  final int colorIndex;
}
