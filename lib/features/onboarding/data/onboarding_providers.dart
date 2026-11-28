import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/data/authentication_providers.dart';
import 'api_onboarding_repository.dart';
import 'mock_onboarding_repository.dart';
import 'onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  const authMode = String.fromEnvironment('AUTH_MODE', defaultValue: 'api');
  if (authMode == 'mock') return MockOnboardingRepository();
  return ApiOnboardingRepository(ref.watch(apiDioProvider));
});
