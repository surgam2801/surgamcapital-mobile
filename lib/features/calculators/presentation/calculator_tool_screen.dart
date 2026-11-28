import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';
import '../domain/calculator_engine.dart';
import 'calculator_tool_catalog.dart';

class CalculatorToolScreen extends StatefulWidget {
  const CalculatorToolScreen({super.key, required this.calculatorId});

  final String calculatorId;

  @override
  State<CalculatorToolScreen> createState() => _CalculatorToolScreenState();
}

class _CalculatorToolScreenState extends State<CalculatorToolScreen> {
  late final TextEditingController _amount;
  late final TextEditingController _years;
  late final TextEditingController _rate;
  late final TextEditingController _inflation;
  late final TextEditingController _savings;
  late final TextEditingController _monthly;
  late final TextEditingController _stepUp;
  final GlobalKey _selectedToolTabKey = GlobalKey();
  bool _targetMode = false;
  bool _stepUpEnabled = false;

  bool get _isGoal =>
      !const {'sip', 'step-up-sip', 'lumpsum'}.contains(widget.calculatorId);
  bool get _isLumpsum => widget.calculatorId == 'lumpsum';
  bool get _isSip =>
      widget.calculatorId == 'sip' || widget.calculatorId == 'step-up-sip';
  String get _goalName => switch (widget.calculatorId) {
    'retirement' => 'Retirement',
    'education' => 'Child education',
    'home' => 'Home purchase',
    'car' => 'Car purchase',
    'wedding' => 'Wedding',
    'travel' => 'Travel',
    'emergency' => 'Emergency fund',
    _ => 'Custom financial goal',
  };
  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: _isLumpsum
          ? '250000'
          : _isGoal
          ? '2500000'
          : '15000',
    );
    _years = TextEditingController(text: _isGoal ? '15' : '10');
    _rate = TextEditingController(text: '12');
    _inflation = TextEditingController(text: '6');
    _savings = TextEditingController(text: '100000');
    _monthly = TextEditingController(text: '3000');
    _stepUp = TextEditingController(text: '10');
    _stepUpEnabled = widget.calculatorId == 'step-up-sip';
    _ensureSelectedToolVisible();
  }

  @override
  void didUpdateWidget(covariant CalculatorToolScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.calculatorId != widget.calculatorId) {
      _restoreDefaults();
      _ensureSelectedToolVisible();
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _years.dispose();
    _rate.dispose();
    _inflation.dispose();
    _savings.dispose();
    _monthly.dispose();
    _stepUp.dispose();
    super.dispose();
  }

  double _number(TextEditingController controller, double fallback) =>
      double.tryParse(controller.text.replaceAll(',', '').trim()) ?? fallback;

  double _verticalSpace(BuildContext context, double value) =>
      AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width)
      ? value * .8
      : value;

  int get _yearValue => _number(_years, 10).round().clamp(1, 50);
  double get _returnRate => _number(_rate, 12).clamp(0, 100);
  double get _investmentAmount => _number(_amount, 0).clamp(0, 1000000000);

  void _updateNumber(TextEditingController controller, double value) {
    final text = value.round().toString();
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {});
  }

  void _reset() {
    setState(_restoreDefaults);
  }

  void _restoreDefaults() {
    _amount.text = _isLumpsum
        ? '250000'
        : _isGoal
        ? '2500000'
        : '15000';
    _years.text = _isGoal ? '15' : '10';
    _rate.text = '12';
    _inflation.text = '6';
    _savings.text = '100000';
    _monthly.text = '3000';
    _stepUp.text = '10';
    _targetMode = false;
    _stepUpEnabled = widget.calculatorId == 'step-up-sip';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      leading: IconButton(
        tooltip: 'All goals and calculators',
        onPressed: () => context.go(AppRoutes.calculators),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: Text(
        _isGoal ? 'Plan a goal' : 'Investment calculators',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        TextButton.icon(
          onPressed: _reset,
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('Reset'),
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: _toolTabs(),
      ),
    ),
    body: AppAdaptiveBody(
      selectedIndex: 2,
      child: LayoutBuilder(
        builder: (context, outerConstraints) {
          final isMobile = AppTheme.isMobileWidth(outerConstraints.maxWidth);
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore an estimate by changing the assumptions below.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: _verticalSpace(context, 18)),
                    if (outerConstraints.maxWidth >= 900)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 4, child: _inputs(context)),
                          const SizedBox(width: 18),
                          Expanded(flex: 6, child: _results(context)),
                        ],
                      )
                    else ...[
                      _inputs(context),
                      SizedBox(height: _verticalSpace(context, 16)),
                      _results(context),
                    ],
                    SizedBox(height: _verticalSpace(context, 16)),
                    const _ExactDisclaimer(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );

  void _switchCalculator(String calculatorId) {
    if (calculatorId != widget.calculatorId) {
      context.go('${AppRoutes.calculator}/$calculatorId');
    }
  }

  void _ensureSelectedToolVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final selectedContext = _selectedToolTabKey.currentContext;
      if (selectedContext != null) {
        Scrollable.ensureVisible(
          selectedContext,
          alignment: 0.5,
          duration: Duration.zero,
        );
      }
    });
  }

  Widget _toolTabs() {
    final tools = [...goalCalculatorTools, ...investmentCalculatorTools];
    return SizedBox(
      height: 56,
      child: SingleChildScrollView(
        key: const ValueKey('calculator-tool-tabs'),
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              for (var index = 0; index < tools.length; index++) ...[
                if (index == goalCalculatorTools.length)
                  Container(
                    width: 1,
                    height: 26,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: AppColors.border,
                  ),
                _toolTab(tools[index]),
                if (index < tools.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolTab(CalculatorToolOption option) {
    final selected = option.id == widget.calculatorId;
    return Semantics(
      key: ValueKey('calculator-tool-tab-${option.id}'),
      button: true,
      selected: selected,
      label: option.title,
      child: Material(
        key: selected ? _selectedToolTabKey : null,
        color: selected ? AppColors.blue : AppColors.surface,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? AppColors.blue : AppColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _switchCalculator(option.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(
              _toolTabLabel(option),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? Colors.white : AppColors.primaryText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _toolTabLabel(CalculatorToolOption option) => switch (option.id) {
    'education' => 'Education',
    'home' => 'Home',
    'retirement' => 'Retirement',
    'car' => 'Car',
    'wedding' => 'Wedding',
    'travel' => 'Travel',
    'emergency' => 'Emergency',
    'custom' => 'Custom',
    'sip' => 'SIP',
    'step-up-sip' => 'Step-up SIP',
    'lumpsum' => 'Lumpsum',
    _ => option.title,
  };

  Widget _inputs(BuildContext context) => _CalculatorPanel(
    title: 'Your assumptions',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isSip) ...[
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('Monthly amount'),
                icon: Icon(Icons.payments_outlined),
              ),
              ButtonSegment(
                value: true,
                label: Text('Target amount'),
                icon: Icon(Icons.flag_outlined),
              ),
            ],
            selected: {_targetMode},
            onSelectionChanged: (value) => setState(() {
              _targetMode = value.first;
              _amount.text = _targetMode ? '5000000' : '15000';
            }),
          ),
          SizedBox(height: _verticalSpace(context, 18)),
          _sliderInput(
            context,
            label: _targetMode ? 'Target corpus' : 'Monthly SIP',
            controller: _amount,
            min: _targetMode ? 100000 : 500,
            max: _targetMode ? 50000000 : 200000,
            prefix: '₹',
            divisions: 100,
          ),
        ] else
          _sliderInput(
            context,
            label: _isGoal ? 'Goal amount today' : 'Initial investment',
            controller: _amount,
            min: 10000,
            max: _isGoal ? 100000000 : 10000000,
            prefix: '₹',
            divisions: 100,
          ),
        SizedBox(height: _verticalSpace(context, 10)),
        _shortInputPair(
          context,
          _sliderInput(
            context,
            label: 'Time horizon',
            controller: _years,
            min: 1,
            max: 50,
            suffix: ' years',
            divisions: 49,
            integer: true,
          ),
          _sliderInput(
            context,
            label: 'Expected annual return',
            controller: _rate,
            min: 0,
            max: 30,
            suffix: '%',
            divisions: 60,
            decimals: true,
          ),
        ),
        if (_isGoal) ...[
          SizedBox(height: _verticalSpace(context, 10)),
          _sliderInput(
            context,
            label: 'Expected annual inflation',
            controller: _inflation,
            min: 0,
            max: 15,
            suffix: '%',
            divisions: 30,
            decimals: true,
          ),
          SizedBox(height: _verticalSpace(context, 10)),
          _sliderInput(
            context,
            label: 'Existing savings',
            controller: _savings,
            min: 0,
            max: 5000000,
            prefix: '₹',
            divisions: 100,
          ),
          SizedBox(height: _verticalSpace(context, 10)),
          _sliderInput(
            context,
            label: 'Monthly investment already planned',
            controller: _monthly,
            min: 0,
            max: 100000,
            prefix: '₹',
            divisions: 100,
          ),
        ],
        if (_isSip) ...[
          SizedBox(height: _verticalSpace(context, 14)),
          Material(
            color: AppColors.surface,
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Increase SIP every year'),
              subtitle: const Text('Compare annual step-up with a regular SIP'),
              value: _stepUpEnabled,
              onChanged: (value) => setState(() => _stepUpEnabled = value),
            ),
          ),
          if (_stepUpEnabled)
            _sliderInput(
              context,
              label: 'Annual step-up',
              controller: _stepUp,
              min: 0,
              max: 50,
              suffix: '%',
              divisions: 50,
              decimals: true,
            ),
        ],
        if (_isGoal) ...[
          SizedBox(height: _verticalSpace(context, 12)),
          Text(
            'Goal: $_goalName',
            style: const TextStyle(
              color: AppColors.blue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        SizedBox(height: _verticalSpace(context, 12)),
        Text(
          _isLumpsum
              ? 'Lumpsum uses annual compounding. SIPs use a nominal annual rate divided by 12, with contributions at each month end.'
              : 'SIP projections use a nominal annual rate divided by 12, with contributions at each month end. Step-ups apply once per year.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );

  Widget _shortInputPair(BuildContext context, Widget first, Widget second) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 360 ? 2 : 1;
          final gap = _verticalSpace(context, 10);
          final width = columns == 2
              ? (constraints.maxWidth - gap) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: gap,
            runSpacing: _verticalSpace(context, 10),
            children: [
              SizedBox(width: width, child: first),
              SizedBox(width: width, child: second),
            ],
          );
        },
      );

  Widget _sliderInput(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required double min,
    required double max,
    required int divisions,
    String prefix = '',
    String suffix = '',
    bool integer = false,
    bool decimals = false,
  }) {
    final value = (_number(controller, min).clamp(min, max)).toDouble();
    final shown = decimals
        ? value.toStringAsFixed(1)
        : value.round().toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.labelLarge),
            ),
            SizedBox(
              width: math.min(124, MediaQuery.sizeOf(context).width * .3),
              child: TextField(
                controller: controller,
                textAlign: TextAlign.end,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  prefixText: prefix,
                  suffixText: suffix,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: '$prefix$shown$suffix',
          onChanged: (next) =>
              _updateNumber(controller, integer ? next.roundToDouble() : next),
        ),
      ],
    );
  }

  Widget _results(BuildContext context) {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    final years = _yearValue;
    final annualReturn = _returnRate;
    InvestmentProjection? projection;
    InvestmentProjection? regularProjection;
    GoalProjection? goalProjection;
    var primaryLabel = 'Estimated maturity value';
    var monthlyAmount = 0.0;
    try {
      if (_isGoal) {
        goalProjection = CalculatorEngine.goal(
          amountToday: _investmentAmount,
          years: years,
          inflationPercent: _number(_inflation, 6).clamp(0, 100),
          annualReturnPercent: annualReturn,
          existingSavings: _number(_savings, 0).clamp(0, 1000000000),
          existingMonthlyInvestment: _number(_monthly, 0).clamp(0, 1000000000),
        );
        primaryLabel = 'Inflation-adjusted goal';
      } else if (_isLumpsum) {
        projection = CalculatorEngine.lumpsum(
          principal: _investmentAmount,
          years: years,
          annualReturnPercent: annualReturn,
        );
      } else {
        monthlyAmount = _targetMode
            ? CalculatorEngine.requiredMonthlySip(
                targetAmount: _investmentAmount,
                years: years,
                annualReturnPercent: annualReturn,
                annualStepUpPercent: _stepUpEnabled
                    ? _number(_stepUp, 10).clamp(0, 100)
                    : 0,
              )
            : _investmentAmount;
        projection = CalculatorEngine.sip(
          monthlyInvestment: monthlyAmount,
          years: years,
          annualReturnPercent: annualReturn,
          annualStepUpPercent: _stepUpEnabled
              ? _number(_stepUp, 10).clamp(0, 100)
              : 0,
        );
        if (_stepUpEnabled) {
          final regularMonthlyAmount = _targetMode
              ? CalculatorEngine.requiredMonthlySip(
                  targetAmount: _investmentAmount,
                  years: years,
                  annualReturnPercent: annualReturn,
                )
              : monthlyAmount;
          regularProjection = CalculatorEngine.sip(
            monthlyInvestment: regularMonthlyAmount,
            years: years,
            annualReturnPercent: annualReturn,
          );
        }
        primaryLabel = _targetMode ? 'Required monthly SIP' : 'Maturity value';
      }
    } on RangeError {
      return _CalculatorPanel(
        title: 'Projection',
        child: const Text('Enter values within the available ranges.'),
      );
    }

    final corpus = goalProjection?.estimatedCorpus ?? projection!.corpus;
    final invested = goalProjection == null
        ? projection!.invested
        : goalProjection.existingSavings +
              goalProjection.investedThroughRequiredSip;
    final gains = math.max(0.0, corpus - invested);
    final points = goalProjection?.points ?? projection!.points;
    final comparisonPoints = regularProjection?.points;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 18 : 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.navy, Color(0xFF1E5961)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                primaryLabel.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFB5D9CE),
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: _verticalSpace(context, 8)),
              Text(
                _formatCurrency(
                  goalProjection != null
                      ? goalProjection.futureAmount
                      : _targetMode
                      ? monthlyAmount
                      : corpus,
                ),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 26 : 30,
                  height: isMobile ? 1.1 : null,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (goalProjection != null) ...[
                SizedBox(height: _verticalSpace(context, 8)),
                Text(
                  'Additional monthly SIP: ${_formatCurrency(goalProjection.additionalMonthlySip)}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
              if (_isSip && !_targetMode) ...[
                SizedBox(height: _verticalSpace(context, 8)),
                Text(
                  'Monthly SIP: ${_formatCurrency(monthlyAmount)}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
              SizedBox(height: _verticalSpace(context, 8)),
              Text(
                'Illustration for $years years at ${annualReturn.toStringAsFixed(1)}% assumed annual return',
                style: const TextStyle(color: Color(0xFFE0EAF0)),
              ),
            ],
          ),
        ),
        SizedBox(height: _verticalSpace(context, 14)),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _metric('Invested', _formatCurrency(invested), AppColors.navy),
            _metric('Estimated gains', _formatCurrency(gains), AppColors.blue),
            _metric(
              'Projected corpus',
              _formatCurrency(corpus),
              const Color(0xFF526D82),
            ),
          ],
        ),
        SizedBox(height: _verticalSpace(context, 14)),
        _CalculatorPanel(
          title: 'Investment vs estimated returns',
          child: Row(
            children: [
              SizedBox(
                height: isMobile ? 112 : 130,
                width: isMobile ? 112 : 130,
                child: CustomPaint(
                  painter: _BreakdownPainter(
                    invested: invested,
                    returns: gains,
                  ),
                  child: const Center(
                    child: Text(
                      'ESTIMATE',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: _verticalSpace(context, 14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _keyValue('Invested', _formatCurrency(invested)),
                    _keyValue('Estimated returns', _formatCurrency(gains)),
                    _keyValue('Projected corpus', _formatCurrency(corpus)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (goalProjection != null) ...[
          SizedBox(height: _verticalSpace(context, 14)),
          _CalculatorPanel(
            title: 'Goal funding plan',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _keyValue(
                  'Goal amount in today’s value',
                  _formatCurrency(goalProjection.todayAmount),
                ),
                _keyValue(
                  'Future cost after inflation',
                  _formatCurrency(goalProjection.futureAmount),
                ),
                _keyValue(
                  'Existing savings at goal date',
                  _formatCurrency(goalProjection.existingSavingsFutureValue),
                ),
                _keyValue(
                  'Required total monthly SIP',
                  _formatCurrency(goalProjection.requiredMonthlySip),
                ),
                _keyValue(
                  'Estimated final corpus',
                  _formatCurrency(goalProjection.estimatedCorpus),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: _verticalSpace(context, 14)),
        _CalculatorPanel(
          title: 'Projected growth',
          trailing: comparisonPoints == null
              ? null
              : const Text('Step-up vs regular'),
          child: Column(
            children: [
              SizedBox(
                height: isMobile ? 190 : 210,
                width: double.infinity,
                child: CustomPaint(
                  painter: _ProjectionPainter(
                    points: points,
                    comparisonPoints: comparisonPoints,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              SizedBox(height: _verticalSpace(context, 8)),
              const _ChartLegend(),
            ],
          ),
        ),
        SizedBox(height: _verticalSpace(context, 14)),
        _CalculatorPanel(
          title: 'Year-wise illustration',
          child: Column(
            children: [
              const _ProjectionRow(
                year: 'Year',
                invested: 'Invested',
                corpus: 'Projected value',
                header: true,
              ),
              for (final point in _displayPoints(points))
                _ProjectionRow(
                  year: '${point.year}',
                  invested: _formatCurrency(point.invested),
                  corpus: _formatCurrency(point.corpus),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<ProjectionPoint> _displayPoints(List<ProjectionPoint> points) {
    if (points.length <= 8) return points;
    final sampled = <ProjectionPoint>[];
    for (var index = 0; index < 6; index++) {
      sampled.add(points[(index * (points.length - 1) / 5).round()]);
    }
    if (sampled.last.year != points.last.year) sampled.add(points.last);
    return sampled;
  }

  Widget _metric(String label, String value, Color accent) => SizedBox(
    width: 160,
    child: Container(
      padding: EdgeInsets.all(
        AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width) ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: .18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          SizedBox(height: _verticalSpace(context, 5)),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _keyValue(String label, String value) => Padding(
    padding: EdgeInsets.symmetric(vertical: _verticalSpace(context, 5)),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );

  String _formatCurrency(double value) {
    if (!value.isFinite) return '—';
    final amount = value.round().toString();
    final lastThree = amount.length > 3
        ? amount.substring(amount.length - 3)
        : amount;
    final prefix = amount.length > 3
        ? amount.substring(0, amount.length - 3)
        : '';
    final grouped = prefix.isEmpty
        ? lastThree
        : '${prefix.replaceAllMapped(RegExp(r'\B(?=(\d{2})+(?!\d))'), (match) => ',')},$lastThree';
    return '₹$grouped';
  }
}

class _CalculatorPanel extends StatelessWidget {
  const _CalculatorPanel({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(
      AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width) ? 14 : 18,
    ),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
        SizedBox(
          height: AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width)
              ? 11
              : 14,
        ),
        child,
      ],
    ),
  );
}

class _ProjectionRow extends StatelessWidget {
  const _ProjectionRow({
    required this.year,
    required this.invested,
    required this.corpus,
    this.header = false,
  });

  final String year;
  final String invested;
  final String corpus;
  final bool header;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: AppColors.border.withValues(alpha: .8)),
      ),
    ),
    child: Row(
      children: [
        Expanded(flex: 1, child: Text(year, style: _style(context))),
        Expanded(
          flex: 2,
          child: Text(
            invested,
            textAlign: TextAlign.end,
            style: _style(context),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(corpus, textAlign: TextAlign.end, style: _style(context)),
        ),
      ],
    ),
  );

  TextStyle? _style(BuildContext context) => header
      ? Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.secondaryText,
        )
      : Theme.of(context).textTheme.bodySmall;
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend();

  @override
  Widget build(BuildContext context) => const Wrap(
    spacing: 16,
    runSpacing: 8,
    children: [
      _LegendDot(color: AppColors.blue, label: 'Projected value'),
      _LegendDot(color: AppColors.navy, label: 'Invested amount'),
      _LegendDot(color: AppColors.teal, label: 'Regular SIP comparison'),
    ],
  );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _ProjectionPainter extends CustomPainter {
  const _ProjectionPainter({required this.points, this.comparisonPoints});

  final List<ProjectionPoint> points;
  final List<ProjectionPoint>? comparisonPoints;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const horizontalPadding = 12.0;
    const verticalPadding = 10.0;
    final chartSize = Size(
      size.width - horizontalPadding * 2,
      size.height - verticalPadding * 2,
    );
    final maxValue = [
      ...points.map((point) => point.corpus),
      ...points.map((point) => point.invested),
      ...?comparisonPoints?.map((point) => point.corpus),
    ].fold<double>(0, math.max);
    if (maxValue <= 0) return;

    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var row = 0; row <= 3; row++) {
      final y = verticalPadding + chartSize.height * row / 3;
      canvas.drawLine(
        Offset(horizontalPadding, y),
        Offset(size.width - horizontalPadding, y),
        grid,
      );
    }

    List<Offset> positions(
      List<ProjectionPoint> values,
      double Function(ProjectionPoint) select,
    ) => [
      for (var index = 0; index < values.length; index++)
        Offset(
          horizontalPadding +
              (values.length == 1
                  ? chartSize.width
                  : chartSize.width * index / (values.length - 1)),
          verticalPadding +
              chartSize.height * (1 - select(values[index]) / maxValue),
        ),
    ];

    void drawLine(List<Offset> values, Color color, {bool dashed = false}) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final path = Path()..moveTo(values.first.dx, values.first.dy);
      for (final point in values.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      if (!dashed) {
        canvas.drawPath(path, paint);
      } else {
        for (var index = 1; index < values.length; index++) {
          if (index.isEven) {
            canvas.drawLine(values[index - 1], values[index], paint);
          }
        }
      }
      for (final point in values) {
        canvas.drawCircle(point, 2.5, Paint()..color = color);
      }
    }

    if (comparisonPoints != null && comparisonPoints!.isNotEmpty) {
      drawLine(
        positions(comparisonPoints!, (point) => point.corpus),
        AppColors.teal,
        dashed: true,
      );
    }
    drawLine(positions(points, (point) => point.invested), AppColors.navy);
    drawLine(positions(points, (point) => point.corpus), AppColors.blue);
  }

  @override
  bool shouldRepaint(covariant _ProjectionPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.comparisonPoints != comparisonPoints;
}

class _BreakdownPainter extends CustomPainter {
  const _BreakdownPainter({required this.invested, required this.returns});

  final double invested;
  final double returns;

  @override
  void paint(Canvas canvas, Size size) {
    final total = invested + returns;
    if (total <= 0) return;
    final side = math.min(size.width, size.height) * .92;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: side,
      height: side,
    );
    final base = Paint()
      ..color = AppColors.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * .2;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, base);
    final rate = returns / total;
    if (rate > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * rate,
        false,
        Paint()
          ..color = AppColors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = side * .2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BreakdownPainter oldDelegate) =>
      oldDelegate.invested != invested || oldDelegate.returns != returns;
}

class _ExactDisclaimer extends StatelessWidget {
  const _ExactDisclaimer();

  @override
  Widget build(BuildContext context) {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0D89C)),
      ),
      child: Text(
        'These calculations are illustrative estimates based on the assumptions entered. Actual mutual fund returns are market-linked and may be higher or lower. Past performance does not guarantee future returns. Mutual fund investments are subject to market risks. Please read all scheme-related documents carefully.',
        style: TextStyle(fontSize: 12, height: isMobile ? 1.35 : 1.4),
      ),
    );
  }
}
