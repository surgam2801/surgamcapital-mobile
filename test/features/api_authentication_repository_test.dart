import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surgam_capital/core/network/dio_client.dart';
import 'package:surgam_capital/features/authentication/data/api_authentication_repository.dart';
import 'package:surgam_capital/features/authentication/data/token_storage.dart';

void main() {
  test(
    'login parses a challenge and sends the versioned API payload',
    () async {
      final adapter = _FixtureAdapter({
        'success': true,
        'data': {
          'challengeId': 'challenge-123',
          'maskedDestination': '******3210',
          'expiresInSeconds': 300,
        },
      });
      final repository = ApiAuthenticationRepository(
        dio: Dio(BaseOptions(baseUrl: 'https://auth.example.test'))
          ..httpClientAdapter = adapter,
        tokenStorage: _MemoryTokenStorage(),
      );

      final challenge = await repository.login(
        username: 'investor',
        password: 'a-test-password',
      );

      expect(challenge.challengeId, 'challenge-123');
      expect(challenge.maskedDestination, '******3210');
      expect(adapter.request?.path, '/api/v1/auth/login');
      expect(adapter.request?.data, {
        'username': 'investor',
        'password': 'a-test-password',
      });
    },
  );

  test('OTP verification stores access and refresh tokens securely', () async {
    final adapter = _FixtureAdapter({
      'success': true,
      'data': {
        'accessToken': 'access-test-value',
        'refreshToken': 'refresh-test-value',
        'tokenType': 'Bearer',
        'expiresInSeconds': 900,
      },
    });
    final storage = _MemoryTokenStorage();
    final repository = ApiAuthenticationRepository(
      dio: Dio(BaseOptions(baseUrl: 'https://auth.example.test'))
        ..httpClientAdapter = adapter,
      tokenStorage: storage,
    );

    final tokens = await repository.verifyOtp(
      challengeId: 'challenge-123',
      otp: '123456',
    );

    expect(tokens.accessToken, 'access-test-value');
    expect(storage.accessToken, tokens.accessToken);
    expect(storage.refreshToken, tokens.refreshToken);
    expect(adapter.request?.path, '/api/v1/auth/otp/verify');
  });

  test(
    'auth interceptor sends the stored bearer token to its configured API origin',
    () async {
      final adapter = _FixtureAdapter({'success': true});
      final storage = _MemoryTokenStorage()
        ..accessToken = 'stored-access-token'
        ..refreshToken = 'stored-refresh-token';
      final client = DioClient(
        dio: Dio(BaseOptions(baseUrl: 'https://auth.example.test'))
          ..httpClientAdapter = adapter,
        tokenStorage: storage,
      ).dio;

      await client.get<void>('/api/v1/onboarding/current');

      expect(
        adapter.request?.headers['Authorization'],
        'Bearer stored-access-token',
      );
    },
  );

  test(
    'auth interceptor never sends bearer tokens to another origin',
    () async {
      final adapter = _FixtureAdapter({'success': true});
      final storage = _MemoryTokenStorage()
        ..accessToken = 'stored-access-token'
        ..refreshToken = 'stored-refresh-token';
      final client = DioClient(
        dio: Dio(BaseOptions(baseUrl: 'https://auth.example.test'))
          ..httpClientAdapter = adapter,
        tokenStorage: storage,
      ).dio;

      await client.get<void>('https://third-party.example/resource');

      expect(adapter.request?.headers['Authorization'], isNull);
    },
  );
}

class _FixtureAdapter implements HttpClientAdapter {
  _FixtureAdapter(this.response);

  final Map<String, Object> response;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode(response),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _MemoryTokenStorage implements TokenStorage {
  String? accessToken;
  String? refreshToken;

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }

  @override
  Future<bool> hasTokens() async => accessToken != null && refreshToken != null;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }
}
