import 'package:flutter_test/flutter_test.dart';
import 'package:surgam_capital/features/calculators/domain/calculator_engine.dart';

void main() {
  group('CalculatorEngine', () {
    test('regular SIP compounds monthly with month-end contributions', () {
      final result = CalculatorEngine.sip(
        monthlyInvestment: 1000,
        years: 1,
        annualReturnPercent: 12,
      );

      expect(result.invested, 12000);
      expect(result.corpus, closeTo(12682.50, 0.01));
      expect(result.points, hasLength(1));
    });

    test('zero-rate SIP and target SIP avoid division by zero', () {
      final result = CalculatorEngine.sip(
        monthlyInvestment: 500,
        years: 2,
        annualReturnPercent: 0,
      );
      final required = CalculatorEngine.requiredMonthlySip(
        targetAmount: 12000,
        years: 2,
        annualReturnPercent: 0,
      );

      expect(result.corpus, 12000);
      expect(required, 500);
    });

    test(
      'step-up SIP increases annual contributions and target mode solves it',
      () {
        final regular = CalculatorEngine.sip(
          monthlyInvestment: 1000,
          years: 5,
          annualReturnPercent: 10,
        );
        final stepped = CalculatorEngine.sip(
          monthlyInvestment: 1000,
          years: 5,
          annualReturnPercent: 10,
          annualStepUpPercent: 10,
        );
        final required = CalculatorEngine.requiredMonthlySip(
          targetAmount: 200000,
          years: 10,
          annualReturnPercent: 10,
          annualStepUpPercent: 10,
        );
        final projected = CalculatorEngine.sip(
          monthlyInvestment: required,
          years: 10,
          annualReturnPercent: 10,
          annualStepUpPercent: 10,
        );

        expect(stepped.corpus, greaterThan(regular.corpus));
        expect(stepped.invested, greaterThan(regular.invested));
        expect(projected.corpus, closeTo(200000, 0.01));
      },
    );

    test('lumpsum compounds annually', () {
      final result = CalculatorEngine.lumpsum(
        principal: 100000,
        years: 3,
        annualReturnPercent: 10,
      );

      expect(result.corpus, closeTo(133100, 0.001));
      expect(result.invested, 100000);
      expect(result.points.last.corpus, result.corpus);
    });

    test(
      'goal adjusts inflation, existing corpus and existing monthly SIP',
      () {
        final result = CalculatorEngine.goal(
          amountToday: 1000000,
          years: 10,
          inflationPercent: 6,
          annualReturnPercent: 10,
          existingSavings: 100000,
          existingMonthlyInvestment: 1000,
        );

        expect(result.futureAmount, closeTo(1790847.6965, 0.01));
        expect(result.existingSavingsFutureValue, closeTo(259374.246, 0.01));
        expect(
          result.additionalMonthlySip,
          closeTo(result.requiredMonthlySip - 1000, 0.01),
        );
        expect(result.estimatedCorpus, closeTo(result.futureAmount, 0.01));
        expect(result.points, hasLength(10));
      },
    );

    test('validates unsupported duration and non-finite amounts', () {
      expect(
        () => CalculatorEngine.sip(
          monthlyInvestment: 1000,
          years: 0,
          annualReturnPercent: 10,
        ),
        throwsRangeError,
      );
      expect(
        () => CalculatorEngine.lumpsum(
          principal: double.infinity,
          years: 1,
          annualReturnPercent: 10,
        ),
        throwsRangeError,
      );
    });
  });
}
