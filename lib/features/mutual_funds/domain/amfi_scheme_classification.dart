class AmfiSchemeClassification {
  const AmfiSchemeClassification._();

  static const schemeClasses = [
    'Equity',
    'Debt',
    'Hybrid',
    'Index',
    'ELSS',
    'International',
    'Gold/Silver',
    'Other',
  ];

  static const marketCaps = [
    'Large Cap',
    'Mid Cap',
    'Small Cap',
    'Multi Cap',
    'Flexi Cap',
    'Large & Mid Cap',
  ];

  static String schemeClass(String category) {
    final value = category.toLowerCase();
    if (value.contains('elss') || value.contains('tax saver')) return 'ELSS';
    if (_containsAny(value, [
      'overseas',
      'international',
      'foreign',
      'global',
    ])) {
      return 'International';
    }
    if (_containsAny(value, ['gold', 'silver'])) return 'Gold/Silver';
    if (_containsAny(value, ['hybrid', 'arbitrage'])) return 'Hybrid';
    if (_containsAny(value, ['index', 'etf', 'exchange traded'])) {
      return 'Index';
    }
    if (_containsAny(value, ['debt', 'income', 'gilt'])) return 'Debt';
    if (value.contains('equity')) return 'Equity';
    return 'Other';
  }

  static String? marketCap(String category) {
    final value = category.toLowerCase();
    if (_containsAny(value, ['large & mid cap', 'large and mid cap'])) {
      return 'Large & Mid Cap';
    }
    if (value.contains('multi cap')) return 'Multi Cap';
    if (value.contains('flexi cap')) return 'Flexi Cap';
    if (value.contains('large cap')) return 'Large Cap';
    if (value.contains('mid cap')) return 'Mid Cap';
    if (value.contains('small cap')) return 'Small Cap';
    return null;
  }

  static bool _containsAny(String value, List<String> terms) =>
      terms.any(value.contains);
}
