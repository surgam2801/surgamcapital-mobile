import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'api_authentication_repository.dart';
import 'authentication_repository.dart';
import 'mock_authentication_repository.dart';
import 'token_storage.dart';
import '../application/auth_state.dart';

final authenticationRepositoryProvider = Provider<AuthenticationRepository>((
  ref,
) {
  const authMode = String.fromEnvironment('AUTH_MODE', defaultValue: 'api');
  if (authMode == 'mock') return MockAuthenticationRepository();
  if (authMode != 'api') {
    throw StateError('Unsupported AUTH_MODE "$authMode". Use "api" or "mock".');
  }

  return ApiAuthenticationRepository(
    dio: ref.watch(apiDioProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final apiDioProvider = Provider((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return DioClient(
    tokenStorage: storage,
    onSessionExpired: () => ref.read(authenticatedProvider.notifier).clear(),
    baseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8081',
    ),
  ).dio;
});
