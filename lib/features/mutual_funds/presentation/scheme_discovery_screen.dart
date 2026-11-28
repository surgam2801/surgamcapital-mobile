import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_financial_widgets.dart';
import '../data/mutual_fund_providers.dart';
import '../domain/amfi_scheme_classification.dart';
import '../domain/mutual_fund_scheme.dart';

class SchemeDiscoveryScreen extends ConsumerStatefulWidget {
  const SchemeDiscoveryScreen({super.key});

  @override
  ConsumerState<SchemeDiscoveryScreen> createState() =>
      _SchemeDiscoveryScreenState();
}

class _SchemeDiscoveryScreenState extends ConsumerState<SchemeDiscoveryScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  Future<SchemePage>? _results;
  late Future<List<MutualFundFilterOption>> _categories;
  String? _category;
  String? _categoryName;
  final Set<String> _selectedAmcs = {};
  String? _risk;
  String? _schemeClass;
  String? _marketCap;
  String? _subCategory;
  String? _planType;
  String? _optionType;
  double? _minExpenseRatio;
  double? _maxExpenseRatio;
  String? _error;
  int _page = 0;
  String _sort = 'schemeName';
  String _sortDirection = 'ASC';
  bool _loading = false;

  int get _activeFilterCount =>
      (_risk == null ? 0 : 1) +
      (_schemeClass == null ? 0 : 1) +
      (_marketCap == null ? 0 : 1) +
      (_subCategory == null ? 0 : 1) +
      (_planType == null ? 0 : 1) +
      (_optionType == null ? 0 : 1) +
      (_minExpenseRatio == null && _maxExpenseRatio == null ? 0 : 1);

  bool get _hasActiveFilters =>
      _category != null || _selectedAmcs.isNotEmpty || _activeFilterCount > 0;

  @override
  void initState() {
    super.initState();
    _categories = ref.read(mutualFundRepositoryProvider).categories();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      _loading = true;
      _error = null;
      _results = ref
          .read(mutualFundRepositoryProvider)
          .search(
            query: _search.text,
            category: _category,
            amcIds: _selectedAmcs.toList(growable: false),
            schemeClass: _schemeClass,
            marketCap: _marketCap,
            risk: _risk,
            subCategory: _subCategory,
            planType: _planType,
            optionType: _optionType,
            minExpenseRatio: _minExpenseRatio,
            maxExpenseRatio: _maxExpenseRatio,
            page: _page,
            sortBy: _sort,
            sortDirection: _sortDirection,
          );
    });
    _results!.then(
      (_) {
        if (mounted) {
          setState(() => _loading = false);
        }
      },
      onError: (Object error) {
        if (mounted) {
          setState(() {
            _error = error is AppException
                ? error.message
                : 'Unable to load schemes.';
            _loading = false;
          });
        }
      },
    );
  }

  void _scheduleSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _page = 0;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    final comparison = ref.watch(comparisonSelectionProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore mutual funds'),
        actions: [
          if (!isAmfiSampleMode)
            IconButton(
              tooltip: 'Watchlist',
              onPressed: () => context.push(AppRoutes.watchlist),
              icon: const Icon(Icons.bookmark_border),
            ),
          IconButton(
            tooltip: 'Compare schemes',
            onPressed: comparison.isEmpty
                ? null
                : () => context.push(AppRoutes.compareFunds),
            icon: Badge(
              isLabelVisible: comparison.isNotEmpty,
              label: Text('${comparison.length}'),
              child: const Icon(Icons.compare_arrows),
            ),
          ),
        ],
      ),
      body: AppAdaptiveBody(
        selectedIndex: 0,
        child: Column(
          children: [
            if (isAmfiSampleMode)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 20,
                  isMobile ? 6 : 8,
                  isMobile ? 16 : 20,
                  0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1050),
                    child: const AppSourceNote(
                      source: 'AMFI category sample',
                      caption:
                          'One captured NAV per category · dated, not live.',
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 20,
                isMobile ? 8 : 10,
                isMobile ? 16 : 20,
                2,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1050),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Browse categories',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton(
                        onPressed: _selectCategory,
                        child: const Text('All categories'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _categoryTiles(),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 20,
                isMobile ? 6 : 8,
                isMobile ? 16 : 20,
                4,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1050),
                  child: TextField(
                    controller: _search,
                    onChanged: _scheduleSearch,
                    decoration: InputDecoration(
                      hintText: 'Search scheme, AMC, category or scheme code',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _search.clear();
                                _load();
                              },
                              icon: const Icon(Icons.clear),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 54,
              child: ListView(
                key: const ValueKey('explore-filter-controls'),
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
                scrollDirection: Axis.horizontal,
                children: [
                  _filterChip(
                    label: _categoryName ?? 'All categories',
                    onTap: _selectCategory,
                  ),
                  _filterChip(
                    label: _selectedAmcs.isEmpty
                        ? 'All AMCs'
                        : 'AMCs · ${_selectedAmcs.length}',
                    onTap: _selectAmcs,
                  ),
                  _filterChip(
                    label: _activeFilterCount == 0
                        ? 'Filters'
                        : 'Filters · $_activeFilterCount',
                    onTap: _selectFilters,
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      final parts = value.split('|');
                      setState(() {
                        _sort = parts.first;
                        _sortDirection = parts.last;
                      });
                      _load();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'schemeName|ASC',
                        child: Text('Name · A to Z'),
                      ),
                      PopupMenuItem(
                        value: 'schemeName|DESC',
                        child: Text('Name · Z to A'),
                      ),
                      PopupMenuItem(
                        value: 'latestNavDate|DESC',
                        child: Text('NAV date · newest first'),
                      ),
                      if (!isAmfiSampleMode)
                        PopupMenuItem(
                          value: 'expenseRatio|ASC',
                          child: Text('Expense ratio · low to high'),
                        ),
                      if (!isAmfiSampleMode)
                        PopupMenuItem(
                          value: 'aum|DESC',
                          child: Text('AUM · high to low'),
                        ),
                    ],
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(Icons.sort_rounded),
                          SizedBox(width: 4),
                          Text('Sort'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_hasActiveFilters)
              SizedBox(
                height: 42,
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (_categoryName != null)
                      _appliedFilterChip(_categoryName!, () {
                        setState(() {
                          _category = null;
                          _categoryName = null;
                          _subCategory = null;
                        });
                        _load();
                      }),
                    if (_selectedAmcs.isNotEmpty)
                      _appliedFilterChip('AMCs · ${_selectedAmcs.length}', () {
                        setState(_selectedAmcs.clear);
                        _load();
                      }),
                    if (_schemeClass != null)
                      _appliedFilterChip(_schemeClass!, () {
                        setState(() => _schemeClass = null);
                        _load();
                      }),
                    if (_marketCap != null)
                      _appliedFilterChip(_marketCap!, () {
                        setState(() => _marketCap = null);
                        _load();
                      }),
                    if (_risk != null)
                      _appliedFilterChip(
                        'Risk: ${_risk!.replaceAll('_', ' ')}',
                        () => setState(() {
                          _risk = null;
                          _load();
                        }),
                      ),
                    if (_subCategory != null)
                      _appliedFilterChip(
                        'Subcategory: $_subCategory',
                        () => setState(() {
                          _subCategory = null;
                          _load();
                        }),
                      ),
                    if (_planType != null)
                      _appliedFilterChip(
                        '$_planType plan',
                        () => setState(() {
                          _planType = null;
                          _load();
                        }),
                      ),
                    if (_optionType != null)
                      _appliedFilterChip(
                        _optionType!,
                        () => setState(() {
                          _optionType = null;
                          _load();
                        }),
                      ),
                    if (_minExpenseRatio != null || _maxExpenseRatio != null)
                      _appliedFilterChip(
                        'Expense ${_minExpenseRatio ?? 0}%–${_maxExpenseRatio ?? 'any'}%',
                        () => setState(() {
                          _minExpenseRatio = null;
                          _maxExpenseRatio = null;
                          _load();
                        }),
                      ),
                  ],
                ),
              ),
            if (comparison.isNotEmpty)
              MaterialBanner(
                content: Text(
                  '${comparison.length} selected for comparison (maximum 4)',
                ),
                actions: [
                  TextButton(
                    onPressed: () => context.push(AppRoutes.compareFunds),
                    child: const Text('Compare'),
                  ),
                ],
              ),
            Expanded(child: _schemeList()),
          ],
        ),
      ),
    );
  }

  Widget _schemeList() {
    final isMobile = AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width);
    if (_loading && _results == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _messageState(_error!, action: 'Retry', onPressed: _load);
    }
    return FutureBuilder<SchemePage>(
      future: _results,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _messageState(
            _error ?? 'Unable to load schemes.',
            action: 'Retry',
            onPressed: _load,
          );
        }
        final result = snapshot.data;
        if (result == null || result.items.isEmpty) {
          return _messageState('No schemes match these filters.');
        }
        return Column(
          children: [
            if (result.items.any((scheme) => scheme.mockData))
              const _DemoBanner(),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 20,
                  4,
                  isMobile ? 16 : 20,
                  isMobile ? 16 : 20,
                ),
                itemCount: result.items.length + 1,
                itemBuilder: (context, index) {
                  if (index == result.items.length) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${result.totalElements} schemes'),
                        IconButton(
                          tooltip: 'Next page',
                          onPressed: result.page + 1 >= result.totalPages
                              ? null
                              : () {
                                  _page++;
                                  _load();
                                },
                          icon: const Icon(Icons.arrow_forward),
                        ),
                      ],
                    );
                  }
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1050),
                      child: _SchemeCard(scheme: result.items[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _filterChip({required String label, required VoidCallback onTap}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ActionChip(label: Text(label), onPressed: onTap),
      );

  Widget _categoryTiles() => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: AppTheme.isMobileWidth(MediaQuery.sizeOf(context).width)
          ? 16
          : 20,
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1050),
        child: FutureBuilder<List<MutualFundFilterOption>>(
          future: _categories,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return SizedBox(
                height: 64,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1050),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.secondaryText,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Categories could not be loaded.',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(
                              () => _categories = ref
                                  .read(mutualFundRepositoryProvider)
                                  .categories(),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 64,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final categories = snapshot.data!;
            if (categories.isEmpty) {
              return const SizedBox(
                height: 64,
                child: Center(
                  child: Text('No categories are available for this data set.'),
                ),
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 600
                    ? 3
                    : constraints.maxWidth < 900
                    ? 4
                    : 6;
                final shownCategories = categories.take(5).toList();
                const gap = 8.0;
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    SizedBox(
                      key: const ValueKey('category-all'),
                      width: width,
                      height: 64,
                      child: _CategoryTile(
                        name: 'All schemes',
                        isAll: true,
                        selected: _category == null,
                        onTap: _clearCategory,
                      ),
                    ),
                    for (final category in shownCategories)
                      SizedBox(
                        width: width,
                        height: 64,
                        child: _CategoryTile(
                          key: ValueKey('category-${category.code}'),
                          name: category.name,
                          selected: _category == category.code,
                          onTap: () => _applyCategory(category),
                        ),
                      ),
                    SizedBox(
                      key: const ValueKey('category-more'),
                      width: width,
                      height: 64,
                      child: _CategoryTile(
                        name: 'More categories',
                        isMore: true,
                        selected: false,
                        onTap: _selectCategory,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    ),
  );

  void _clearCategory() {
    setState(() {
      _category = null;
      _categoryName = null;
      _subCategory = null;
      _schemeClass = null;
      _marketCap = null;
      _page = 0;
    });
    _load();
  }

  void _applyCategory(MutualFundFilterOption category) {
    setState(() {
      _category = category.code;
      _categoryName = category.name;
      _subCategory = null;
      _schemeClass = null;
      _marketCap = null;
      _page = 0;
    });
    _load();
  }

  Future<void> _selectCategory() async {
    try {
      final categories = await ref
          .read(mutualFundRepositoryProvider)
          .categories();
      if (!mounted) return;
      final selected = await showModalBottomSheet<String?>(
        context: context,
        builder: (context) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('All categories'),
                onTap: () => Navigator.pop(context, ''),
              ),
              for (final category in categories)
                ListTile(
                  title: Text(category.name),
                  subtitle: category.assetClass == null
                      ? null
                      : Text(category.assetClass!),
                  onTap: () => Navigator.pop(context, category.code),
                ),
            ],
          ),
        ),
      );
      if (selected != null) {
        final option = categories.where((item) => item.code == selected);
        setState(() {
          _category = selected.isEmpty ? null : selected;
          _categoryName = option.isEmpty ? null : option.first.name;
          _schemeClass = null;
          _marketCap = null;
          _page = 0;
        });
        _load();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _selectAmcs() async {
    try {
      final amcs = await ref.read(mutualFundRepositoryProvider).amcs();
      if (!mounted) return;
      final selectedAmcs = Set<String>.of(_selectedAmcs);
      final selected = await showModalBottomSheet<Set<String>>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Choose fund houses',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setSheetState(selectedAmcs.clear),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final amc in amcs)
                          CheckboxListTile(
                            value: selectedAmcs.contains(amc.code),
                            title: Text(amc.name),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (checked) => setSheetState(() {
                              if (checked == true) {
                                selectedAmcs.add(amc.code);
                              } else {
                                selectedAmcs.remove(amc.code);
                              }
                            }),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, selectedAmcs),
                        child: Text(
                          selectedAmcs.isEmpty
                              ? 'Show all fund houses'
                              : selectedAmcs.length == 1
                              ? 'Apply 1 fund house'
                              : 'Apply ${selectedAmcs.length} fund houses',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      if (selected != null) {
        setState(() {
          _selectedAmcs
            ..clear()
            ..addAll(selected);
          _page = 0;
        });
        _load();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _selectFilters() async {
    late final List<MutualFundFilterOption> categoryOptions;
    try {
      categoryOptions = await _categories;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
      return;
    }
    if (!mounted) return;
    final schemeClassCounts = {
      for (final value in AmfiSchemeClassification.schemeClasses)
        value: categoryOptions
            .where(
              (option) =>
                  AmfiSchemeClassification.schemeClass(option.name) == value,
            )
            .length,
    };
    final marketCapCounts = {
      for (final value in AmfiSchemeClassification.marketCaps)
        value: categoryOptions
            .where(
              (option) =>
                  AmfiSchemeClassification.marketCap(option.name) == value,
            )
            .length,
    };
    final subCategoryController = TextEditingController(
      text: _subCategory ?? '',
    );
    final minExpenseController = TextEditingController(
      text: _minExpenseRatio?.toString() ?? '',
    );
    final maxExpenseController = TextEditingController(
      text: _maxExpenseRatio?.toString() ?? '',
    );
    var schemeClass = _schemeClass ?? '';
    var marketCap = _marketCap ?? '';
    var risk = _risk ?? '';
    var plan = _planType ?? '';
    var option = _optionType ?? '';

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              4,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter schemes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: schemeClass,
                    decoration: const InputDecoration(
                      labelText: 'Scheme classification',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('All classifications'),
                      ),
                      for (final value
                          in AmfiSchemeClassification.schemeClasses)
                        DropdownMenuItem(
                          value: value,
                          child: Text(
                            '$value · ${schemeClassCounts[value]} categories',
                          ),
                        ),
                    ],
                    onChanged: (value) =>
                        setSheetState(() => schemeClass = value ?? ''),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: marketCap,
                    decoration: const InputDecoration(
                      labelText: 'Market-cap category style',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Any market-cap style'),
                      ),
                      for (final value in AmfiSchemeClassification.marketCaps)
                        DropdownMenuItem(
                          value: value,
                          child: Text(
                            '$value · ${marketCapCounts[value]} categories',
                          ),
                        ),
                    ],
                    onChanged: (value) =>
                        setSheetState(() => marketCap = value ?? ''),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Styles are inferred from AMFI scheme category names; '
                    'they do not represent current portfolio holdings.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  if (!isAmfiSampleMode) ...[
                    DropdownButtonFormField<String>(
                      initialValue: risk,
                      decoration: const InputDecoration(
                        labelText: 'Risk level',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('Any risk level'),
                        ),
                        for (final value in const [
                          'LOW',
                          'MODERATE',
                          'MODERATELY_HIGH',
                          'HIGH',
                          'VERY_HIGH',
                        ])
                          DropdownMenuItem(
                            value: value,
                            child: Text(value.replaceAll('_', ' ')),
                          ),
                      ],
                      onChanged: (value) =>
                          setSheetState(() => risk = value ?? ''),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subCategoryController,
                      decoration: const InputDecoration(
                        labelText: 'Subcategory',
                        hintText: 'Exact subcategory name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minExpenseController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Min expense ratio (%)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: maxExpenseController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Max expense ratio (%)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ] else
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Risk and expense data are not included in this AMFI snapshot.',
                      ),
                    ),
                  DropdownButtonFormField<String>(
                    initialValue: plan,
                    decoration: const InputDecoration(labelText: 'Plan'),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Any plan')),
                      DropdownMenuItem(value: 'DIRECT', child: Text('Direct')),
                      DropdownMenuItem(
                        value: 'REGULAR',
                        child: Text('Regular'),
                      ),
                    ],
                    onChanged: (value) =>
                        setSheetState(() => plan = value ?? ''),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: option,
                    decoration: const InputDecoration(labelText: 'Option'),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Any option')),
                      DropdownMenuItem(value: 'GROWTH', child: Text('Growth')),
                      DropdownMenuItem(value: 'IDCW', child: Text('IDCW')),
                    ],
                    onChanged: (value) =>
                        setSheetState(() => option = value ?? ''),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(sheetContext, 'clear'),
                        child: const Text('Clear filters'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.pop(sheetContext, 'apply'),
                        child: const Text('Apply filters'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'clear') {
      setState(() {
        _schemeClass = null;
        _marketCap = null;
        _risk = null;
        _subCategory = null;
        _planType = null;
        _optionType = null;
        _minExpenseRatio = null;
        _maxExpenseRatio = null;
        _page = 0;
      });
      _load();
    } else if (action == 'apply') {
      final minExpense = _parseExpense(minExpenseController.text);
      final maxExpense = _parseExpense(maxExpenseController.text);
      if (minExpenseController.text.trim().isNotEmpty && minExpense == null ||
          maxExpenseController.text.trim().isNotEmpty && maxExpense == null ||
          (minExpense != null &&
              maxExpense != null &&
              minExpense > maxExpense)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter valid expense limits in ascending order.'),
          ),
        );
      } else {
        setState(() {
          _schemeClass = schemeClass.isEmpty ? null : schemeClass;
          _marketCap = marketCap.isEmpty ? null : marketCap;
          _risk = risk.isEmpty ? null : risk;
          _subCategory = subCategoryController.text.trim().isEmpty
              ? null
              : subCategoryController.text.trim();
          _planType = plan.isEmpty ? null : plan;
          _optionType = option.isEmpty ? null : option;
          _minExpenseRatio = minExpense;
          _maxExpenseRatio = maxExpense;
          _page = 0;
        });
        _load();
      }
    }
    subCategoryController.dispose();
    minExpenseController.dispose();
    maxExpenseController.dispose();
  }

  double? _parseExpense(String value) {
    if (value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.trim());
    return parsed != null && parsed >= 0 ? parsed : null;
  }

  Widget _appliedFilterChip(String label, VoidCallback onRemoved) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: InputChip(label: Text(label), onDeleted: onRemoved),
  );

  Widget _messageState(
    String message, {
    String? action,
    VoidCallback? onPressed,
  }) {
    final children = <Widget>[
      const Icon(Icons.search_off, size: 40, color: AppColors.secondaryText),
      const SizedBox(height: 8),
      Text(message, textAlign: TextAlign.center),
    ];
    if (action != null) {
      children.addAll([
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onPressed, child: Text(action)),
      ]);
    }

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 160),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ),
    );
  }
}

class _SchemeCard extends ConsumerWidget {
  const _SchemeCard({required this.scheme});
  final MutualFundScheme scheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref
        .watch(comparisonSelectionProvider)
        .any((item) => item.id == scheme.id);
    return Card(
      key: ValueKey('scheme-row-${scheme.id}'),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('${AppRoutes.schemeDetail}/${scheme.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (scheme.mockData) const _DemoTag(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _amcMark(scheme.amcName),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scheme.schemeName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          scheme.amcName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      color: AppColors.secondaryText,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      scheme.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${scheme.planType} · ${scheme.optionType}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'NAV  ',
                                style: TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 11,
                                ),
                              ),
                              TextSpan(
                                text:
                                    scheme.latestNav?.toStringAsFixed(4) ??
                                    'Unavailable',
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'As of ${scheme.latestNavDate ?? 'date unavailable'} · Code ${scheme.schemeCode}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.secondaryText),
                        ),
                        if (!isAmfiSampleMode)
                          Text(
                            'Risk ${scheme.riskometer ?? 'unavailable'} · 1Y ${_returnLabel(scheme.oneYearReturn)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.secondaryText),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: selected ? 'Remove from comparison' : 'Compare',
                    onPressed: () {
                      final selection = ref.read(comparisonSelectionProvider);
                      if (!selected && selection.length >= 4) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Compare up to four schemes.'),
                          ),
                        );
                        return;
                      }
                      ref
                          .read(comparisonSelectionProvider.notifier)
                          .toggle(scheme);
                    },
                    icon: Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.add_circle_outline_rounded,
                    ),
                  ),
                  if (!isAmfiSampleMode)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Add to watchlist',
                      onPressed: () async {
                        try {
                          await ref
                              .read(mutualFundRepositoryProvider)
                              .addToWatchlist(scheme.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Added to watchlist'),
                              ),
                            );
                          }
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.bookmark_add_outlined),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    super.key,
    required this.name,
    this.isAll = false,
    this.isMore = false,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool isAll;
  final bool isMore;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.navy : AppColors.surface,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isMore
                  ? Icons.more_horiz_rounded
                  : isAll
                  ? Icons.grid_view_rounded
                  : Icons.category_outlined,
              size: 18,
              color: selected ? AppColors.teal : AppColors.navy,
            ),
            const SizedBox(height: 3),
            Text(
              name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? Colors.white : AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _amcMark(String amc) {
  final words = amc
      .replaceAll(RegExp(r'[^A-Za-z0-9 ]'), ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty && word.toLowerCase() != 'mutual');
  final letters = words.take(2).map((word) => word[0].toUpperCase()).join();
  return letters.isEmpty ? 'MF' : letters;
}

String _returnLabel(PerformanceMetric? metric) {
  if (metric == null || metric.status != 'AVAILABLE' || metric.value == null) {
    return 'N/A';
  }
  return '${metric.value!.toStringAsFixed(2)}% NAV-based';
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();
  @override
  Widget build(BuildContext context) => const MaterialBanner(
    content: Text(
      'DEMO DATA ONLY — these are synthetic examples, not real schemes or market data.',
    ),
    leading: Icon(Icons.science_outlined),
    actions: [SizedBox.shrink()],
  );
}

class _DemoTag extends StatelessWidget {
  const _DemoTag();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Chip(
      visualDensity: VisualDensity.compact,
      label: const Text('DEMO DATA ONLY'),
      backgroundColor: AppColors.warning.withValues(alpha: .15),
    ),
  );
}
