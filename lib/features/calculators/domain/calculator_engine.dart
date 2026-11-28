class ProjectionPoint {
  const ProjectionPoint({
    required this.year,
    required this.invested,
    required this.corpus,
  });

  final int year;
  final double invested;
  final double corpus;

  double get returns => corpus - invested;
}

class InvestmentProjection {
  const InvestmentProjection({
    required this.invested,
    required this.corpus,
    required this.monthlyInvestment,
    required this.years,
    required this.annualReturn,
    required this.points,
  });

  final double invested;
  final double corpus;
  final double monthlyInvestment;
  final int years;
  final double annualReturn;
  final List<ProjectionPoint> points;

  double get returns => corpus - invested;
}

class GoalProjection {
  const GoalProjection({
    required this.todayAmount,
    required this.futureAmount,
    required this.existingSavings,
    required this.existingSavingsFutureValue,
    required this.requiredMonthlySip,
    required this.existingMonthlyInvestment,
    required this.additionalMonthlySip,
    required this.investedThroughRequiredSip,
    required this.estimatedCorpus,
    required this.years,
    required this.points,
  });

  final double todayAmount;
  final double futureAmount;
  final double existingSavings;
  final double existingSavingsFutureValue;
  final double requiredMonthlySip;
  final double existingMonthlyInvestment;
  final double additionalMonthlySip;
  final double investedThroughRequiredSip;
  final double estimatedCorpus;
  final int years;
  final List<ProjectionPoint> points;
}

class CalculatorEngine {
  const CalculatorEngine._();

  static const maxYears = 50;

  static InvestmentProjection sip({
    required double monthlyInvestment,
    required int years,
    required double annualReturnPercent,
    double annualStepUpPercent = 0,
  }) {
    _validateYears(years);
    _validateNonNegative(monthlyInvestment, 'monthlyInvestment');
    _validateRate(annualReturnPercent, 'annualReturnPercent');
    _validateRate(annualStepUpPercent, 'annualStepUpPercent');

    final monthlyRate = annualReturnPercent / 1200;
    var monthlyAmount = monthlyInvestment;
    var invested = 0.0;
    var corpus = 0.0;
    final points = <ProjectionPoint>[];
    for (var month = 1; month <= years * 12; month++) {
      if (month > 1 && (month - 1) % 12 == 0) {
        monthlyAmount *= 1 + annualStepUpPercent / 100;
      }
      corpus = corpus * (1 + monthlyRate) + monthlyAmount;
      invested += monthlyAmount;
      if (month % 12 == 0) {
        points.add(
          ProjectionPoint(
            year: month ~/ 12,
            invested: invested,
            corpus: corpus,
          ),
        );
      }
    }
    return InvestmentProjection(
      invested: invested,
      corpus: corpus,
      monthlyInvestment: monthlyInvestment,
      years: years,
      annualReturn: annualReturnPercent,
      points: List.unmodifiable(points),
    );
  }

  static double requiredMonthlySip({
    required double targetAmount,
    required int years,
    required double annualReturnPercent,
    double annualStepUpPercent = 0,
  }) {
    _validateYears(years);
    _validateNonNegative(targetAmount, 'targetAmount');
    _validateRate(annualReturnPercent, 'annualReturnPercent');
    _validateRate(annualStepUpPercent, 'annualStepUpPercent');
    if (targetAmount == 0) return 0;
    if (annualStepUpPercent > 0) {
      var low = 0.0;
      var high = targetAmount / (years * 12);
      double corpus(double startingPayment) {
        final rate = annualReturnPercent / 1200;
        var amount = startingPayment;
        var value = 0.0;
        for (var month = 1; month <= years * 12; month++) {
          if (month > 1 && (month - 1) % 12 == 0) {
            amount *= 1 + annualStepUpPercent / 100;
          }
          value = value * (1 + rate) + amount;
        }
        return value;
      }

      while (corpus(high) < targetAmount) {
        high *= 2;
      }
      for (var iteration = 0; iteration < 64; iteration++) {
        final middle = (low + high) / 2;
        if (corpus(middle) < targetAmount) {
          low = middle;
        } else {
          high = middle;
        }
      }
      return (low + high) / 2;
    }
    final months = years * 12;
    final monthlyRate = annualReturnPercent / 1200;
    if (monthlyRate == 0) return targetAmount / months;
    final factor = ((1 + monthlyRate).pow(months) - 1) / monthlyRate;
    return targetAmount / factor;
  }

  static InvestmentProjection lumpsum({
    required double principal,
    required int years,
    required double annualReturnPercent,
  }) {
    _validateYears(years);
    _validateNonNegative(principal, 'principal');
    _validateRate(annualReturnPercent, 'annualReturnPercent');
    final annualRate = annualReturnPercent / 100;
    var corpus = principal;
    final points = <ProjectionPoint>[];
    for (var year = 1; year <= years; year++) {
      corpus *= 1 + annualRate;
      points.add(
        ProjectionPoint(year: year, invested: principal, corpus: corpus),
      );
    }
    return InvestmentProjection(
      invested: principal,
      corpus: corpus,
      monthlyInvestment: 0,
      years: years,
      annualReturn: annualReturnPercent,
      points: List.unmodifiable(points),
    );
  }

  static GoalProjection goal({
    required double amountToday,
    required int years,
    required double inflationPercent,
    required double annualReturnPercent,
    double existingSavings = 0,
    double existingMonthlyInvestment = 0,
  }) {
    _validateYears(years);
    _validateNonNegative(amountToday, 'amountToday');
    _validateNonNegative(existingSavings, 'existingSavings');
    _validateNonNegative(
      existingMonthlyInvestment,
      'existingMonthlyInvestment',
    );
    _validateRate(inflationPercent, 'inflationPercent');
    _validateRate(annualReturnPercent, 'annualReturnPercent');
    final futureAmount = amountToday * (1 + inflationPercent / 100).pow(years);
    final existingSavingsFutureValue =
        existingSavings * (1 + annualReturnPercent / 100).pow(years);
    final neededFromMonthlyInvestments =
        (futureAmount - existingSavingsFutureValue)
            .clamp(0, double.infinity)
            .toDouble();
    final requiredMonthlySip = CalculatorEngine.requiredMonthlySip(
      targetAmount: neededFromMonthlyInvestments,
      years: years,
      annualReturnPercent: annualReturnPercent,
    );
    final additionalMonthlySip =
        (requiredMonthlySip - existingMonthlyInvestment)
            .clamp(0, double.infinity)
            .toDouble();
    final plan = sip(
      monthlyInvestment: requiredMonthlySip,
      years: years,
      annualReturnPercent: annualReturnPercent,
    );
    final investedThroughRequiredSip = requiredMonthlySip * years * 12;
    final estimatedCorpus = existingSavingsFutureValue + plan.corpus;
    final points = <ProjectionPoint>[];
    for (var year = 1; year <= years; year++) {
      final projected = sip(
        monthlyInvestment: requiredMonthlySip,
        years: year,
        annualReturnPercent: annualReturnPercent,
      );
      points.add(
        ProjectionPoint(
          year: year,
          invested: existingSavings + projected.invested,
          corpus:
              existingSavings * (1 + annualReturnPercent / 100).pow(year) +
              projected.corpus,
        ),
      );
    }
    return GoalProjection(
      todayAmount: amountToday,
      futureAmount: futureAmount,
      existingSavings: existingSavings,
      existingSavingsFutureValue: existingSavingsFutureValue,
      requiredMonthlySip: requiredMonthlySip,
      existingMonthlyInvestment: existingMonthlyInvestment,
      additionalMonthlySip: additionalMonthlySip,
      investedThroughRequiredSip: investedThroughRequiredSip,
      estimatedCorpus: estimatedCorpus,
      years: years,
      points: List.unmodifiable(points),
    );
  }

  static void _validateYears(int years) {
    if (years < 1 || years > maxYears) {
      throw RangeError.range(years, 1, maxYears, 'years');
    }
  }

  static void _validateRate(double rate, String name) {
    if (!rate.isFinite || rate < 0 || rate > 100) {
      throw RangeError.range(rate, 0, 100, name);
    }
  }

  static void _validateNonNegative(double value, String name) {
    if (!value.isFinite || value < 0) {
      throw RangeError.value(
        value,
        name,
        'Must be a finite non-negative value.',
      );
    }
  }
}

extension on double {
  double pow(int exponent) {
    var result = 1.0;
    for (var index = 0; index < exponent; index++) {
      result *= this;
    }
    return result;
  }
}
