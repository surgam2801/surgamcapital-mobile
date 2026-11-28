import 'package:flutter_test/flutter_test.dart';
import 'package:surgam_capital/features/portfolio/data/demo_portfolio_repository.dart';

void main() {
  const repository = DemoPortfolioRepository();

  test('sample holdings reconcile to demo portfolio summary', () {
    final summary = repository.summary;
    expect(repository.holdings, hasLength(6));
    expect(summary.invested, 850000);
    expect(summary.currentValue, 1025000);
    expect(summary.gain, 175000);
    expect(summary.absoluteReturn, closeTo(20.588235, 0.00001));
    for (final holding in repository.holdings) {
      expect(holding.units * holding.latestNav, holding.currentValue);
    }
  });

  test('performance filters retain the latest sample and exact summary', () {
    for (final range in const ['1M', '3M', '6M', '1Y', '3Y', 'ALL']) {
      final points = repository.performance(range: range);
      expect(points, isNotEmpty, reason: range);
      expect(points.last.invested, repository.summary.invested, reason: range);
      expect(points.last.value, repository.summary.currentValue, reason: range);
    }
  });

  test('allocation groups reconcile to current portfolio value', () {
    for (final grouping in const ['Asset class', 'Category', 'AMC', 'Scheme']) {
      final value = repository
          .allocation(grouping)
          .fold<double>(0, (total, item) => total + item.value);
      expect(value, repository.summary.currentValue, reason: grouping);
    }
  });

  test('demo schedules, transactions and orders are separate datasets', () {
    expect(repository.sips, hasLength(4));
    expect(
      repository.sips.map((sip) => sip.status).toSet(),
      containsAll(['Active', 'Upcoming', 'Paused', 'Completed']),
    );
    expect(repository.transactions, isNotEmpty);
    expect(repository.orders, hasLength(4));
    expect(repository.orders.map((order) => order.status).toSet(), {
      'Pending',
      'Processing',
      'Successful',
      'Failed',
    });
    expect(repository.holding('demo-large-cap'), isNotNull);
  });
}
