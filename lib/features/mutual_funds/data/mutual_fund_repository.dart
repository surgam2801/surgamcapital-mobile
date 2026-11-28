import '../domain/mutual_fund_scheme.dart';

abstract interface class MutualFundRepository {
  Future<List<MutualFundFilterOption>> categories();
  Future<List<MutualFundFilterOption>> amcs();
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
    int page,
    String sortBy,
    String sortDirection,
  });
  Future<MutualFundScheme> details(String id);
  Future<NavHistory> navHistory(String id, {required String range});
  Future<List<PerformanceMetric>> performance(String id);
  Future<List<MutualFundScheme>> compare(List<String> ids);
  Future<List<MutualFundScheme>> watchlist();
  Future<void> addToWatchlist(String id);
  Future<void> removeFromWatchlist(String id);
}
