import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/amfi_scheme_classification.dart';
import '../domain/mutual_fund_scheme.dart';
import 'mutual_fund_repository.dart';

class ApiMutualFundRepository implements MutualFundRepository {
  ApiMutualFundRepository(this._dio);
  final Dio _dio;
  List<MutualFundFilterOption>? _categoryOptions;

  @override
  Future<List<MutualFundFilterOption>> categories() async {
    final cached = _categoryOptions;
    if (cached != null) return cached;
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/mutual-funds/categories',
      );
      final options = _options(_listData(response.data));
      _categoryOptions = options;
      return options;
    } on DioException catch (error) {
      throw _error(error);
    }
  }

  @override
  Future<List<MutualFundFilterOption>> amcs() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/mutual-funds/amcs',
      );
      return _options(_listData(response.data));
    } on DioException catch (error) {
      throw _error(error);
    }
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
    try {
      final classifiedCategoryCodes = await _matchingCategoryCodes(
        schemeClass,
        marketCap,
      );
      if (classifiedCategoryCodes != null && classifiedCategoryCodes.isEmpty) {
        return SchemePage(
          items: const [],
          page: page,
          totalPages: 0,
          totalElements: 0,
        );
      }
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/mutual-funds/schemes',
        queryParameters: {
          if (query != null && query.trim().isNotEmpty) 'search': query.trim(),
          'category': ?category,
          'categories': ?classifiedCategoryCodes,
          'amcId': ?amc,
          'amcIds': ?amcIds,
          'riskLevel': ?risk,
          'subCategory': ?subCategory,
          'planType': ?planType,
          'optionType': ?optionType,
          'minExpenseRatio': ?minExpenseRatio,
          'maxExpenseRatio': ?maxExpenseRatio,
          'page': page,
          'size': 20,
          'sortBy': sortBy,
          'sortDirection': sortDirection,
        },
      );
      return SchemePage.fromJson(_data(response.data));
    } on DioException catch (error) {
      throw _error(error);
    }
  }

  Future<List<String>?> _matchingCategoryCodes(
    String? schemeClass,
    String? marketCap,
  ) async {
    if (schemeClass == null && marketCap == null) return null;
    final options = await categories();
    return options
        .where(
          (option) =>
              (schemeClass == null ||
                  AmfiSchemeClassification.schemeClass(option.name) ==
                      schemeClass) &&
              (marketCap == null ||
                  AmfiSchemeClassification.marketCap(option.name) == marketCap),
        )
        .map((option) => option.code)
        .toList(growable: false);
  }

  @override
  Future<MutualFundScheme> details(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/mutual-funds/schemes/$id',
      );
      return _schemeFromDetails(_data(response.data));
    } on DioException catch (error) {
      throw _error(error);
    }
  }

  @override
  Future<NavHistory> navHistory(String id, {required String range}) async {
    final months = switch (range) {
      '1M' => 1,
      '3M' => 3,
      '6M' => 6,
      '1Y' => 12,
      '3Y' => 36,
      '5Y' => 60,
      '10Y' => 120,
      _ => 1200,
    };
    final now = DateTime.now();
    final from = DateTime(now.year, now.month - months, now.day);
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/mutual-funds/schemes/$id/nav-history',
        queryParameters: {
          'fromDate': _date(from),
          'toDate': _date(now),
          'interval': months > 36 ? 'WEEKLY' : 'DAILY',
        },
      );
      return NavHistory.fromJson(_data(response.data));
    } on DioException catch (error) {
      throw _error(error);
    }
  }

  @override
  Future<List<PerformanceMetric>> performance(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/mutual-funds/schemes/$id/performance',
      );
      final metrics = _asList(_data(response.data)['metrics']);
      return metrics
          .whereType<Map<String, dynamic>>()
          .map(PerformanceMetric.fromJson)
          .toList();
    } on DioException catch (error) {
      throw _error(error);
    }
  }

  @override
  Future<List<MutualFundScheme>> compare(List<String> ids) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/mutual-funds/schemes/compare',
        data: {'schemeIds': ids},
      );
      final data = _data(response.data);
      return _asList(
        data['schemes'],
      ).whereType<Map<String, dynamic>>().map(_schemeFromDetails).toList();
    } on DioException catch (error) {
      throw _error(error);
    }
  }

  @override
  Future<List<MutualFundScheme>> watchlist() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/investors/me/watchlist',
      );
      return _asList(_data(response.data)['items'])
          .whereType<Map<String, dynamic>>()
          .map(MutualFundScheme.fromJson)
          .toList();
    } on DioException catch (error) {
      throw _error(error);
    }
  }

  @override
  Future<void> addToWatchlist(String id) async {
    try {
      await _dio.post<void>('/api/v1/investors/me/watchlist/$id');
    } on DioException catch (error) {
      throw _error(error);
    }
  }

  @override
  Future<void> removeFromWatchlist(String id) async {
    try {
      await _dio.delete<void>('/api/v1/investors/me/watchlist/$id');
    } on DioException catch (error) {
      throw _error(error);
    }
  }

  Map<String, dynamic> _data(Map<String, dynamic>? response) {
    final data = response?['data'];
    if (response?['success'] != true || data is! Map<String, dynamic>) {
      throw const AppException(
        'The scheme service returned an invalid response.',
      );
    }
    return data;
  }

  List<dynamic> _listData(Map<String, dynamic>? response) {
    final data = response?['data'];
    if (response?['success'] != true) {
      throw const AppException('The scheme service returned invalid filters.');
    }
    return _asList(data);
  }

  List<dynamic> _asList(Object? value) {
    if (value is! List<dynamic>) {
      throw const AppException('The scheme service returned an invalid list.');
    }
    return value;
  }

  MutualFundScheme _schemeFromDetails(Map<String, dynamic> details) {
    final scheme = details['scheme'];
    if (scheme is! Map<String, dynamic>) {
      throw const AppException('The scheme service returned invalid details.');
    }
    return MutualFundScheme.fromJson({
      ...scheme,
      for (final key in const [
        'schemeType',
        'benchmarkName',
        'inceptionDate',
        'aum',
        'exitLoad',
        'minimumLumpsum',
        'minimumSip',
        'investmentObjective',
        'description',
        'fundManager',
        'sourceUpdatedAt',
        'performance',
      ])
        if (details.containsKey(key)) key: details[key],
    });
  }

  List<MutualFundFilterOption> _options(Object? value) => _asList(value)
      .whereType<Map<String, dynamic>>()
      .map(MutualFundFilterOption.fromJson)
      .toList();

  AppException _error(DioException error) {
    final response = error.response?.data;
    final errorBody = response is Map ? response['error'] : null;
    final message = errorBody is Map && errorBody['message'] is String
        ? errorBody['message'] as String
        : error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout
        ? 'Unable to reach the mutual fund research service.'
        : 'Unable to retrieve scheme information. Please retry.';
    return AppException(message, statusCode: error.response?.statusCode);
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
