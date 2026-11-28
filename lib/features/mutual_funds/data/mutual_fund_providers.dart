import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/data/authentication_providers.dart';
import 'api_mutual_fund_repository.dart';
import 'amfi_sample_mutual_fund_repository.dart';
import 'mock_mutual_fund_repository.dart';
import 'mutual_fund_repository.dart';
import '../domain/mutual_fund_scheme.dart';

const isAmfiSampleMode = bool.fromEnvironment(
  'AMFI_SAMPLE_MODE',
  defaultValue: true,
);

final mutualFundRepositoryProvider = Provider<MutualFundRepository>((ref) {
  if (isAmfiSampleMode) return AmfiSampleMutualFundRepository();
  const authMode = String.fromEnvironment('AUTH_MODE', defaultValue: 'api');
  if (authMode == 'mock') return MockMutualFundRepository();
  return ApiMutualFundRepository(ref.watch(apiDioProvider));
});

final comparisonSelectionProvider =
    NotifierProvider<ComparisonSelection, List<MutualFundScheme>>(
      ComparisonSelection.new,
    );

class ComparisonSelection extends Notifier<List<MutualFundScheme>> {
  @override
  List<MutualFundScheme> build() => const [];

  void toggle(MutualFundScheme scheme) {
    if (state.any((item) => item.id == scheme.id)) {
      state = state.where((item) => item.id != scheme.id).toList();
      return;
    }
    if (state.length < 4) state = [...state, scheme];
  }

  void clear() => state = const [];
}
