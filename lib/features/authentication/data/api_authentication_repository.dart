import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import 'authentication_repository.dart';
import 'token_storage.dart';

class ApiAuthenticationRepository implements AuthenticationRepository {
  ApiAuthenticationRepository({
    required this._dio,
    required this._tokenStorage,
  });

  final Dio _dio;
  final TokenStorage _tokenStorage;

  @override
  Future<AuthChallenge> login({
    required String username,
    required String password,
  }) async {
    final response = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/login',
        data: {'username': username, 'password': password},
      ),
    );
    return AuthChallenge.fromJson(_data(response));
  }

  @override
  Future<AuthTokens> verifyOtp({
    required String challengeId,
    required String otp,
  }) async {
    final response = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/otp/verify',
        data: {'challengeId': challengeId, 'otp': otp},
      ),
    );
    final tokens = AuthTokens.fromJson(_data(response));
    await _tokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return tokens;
  }

  @override
  Future<AuthChallenge> resendOtp({required String challengeId}) async {
    final response = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/otp/resend',
        data: {'challengeId': challengeId},
      ),
    );
    return AuthChallenge.fromJson(_data(response));
  }

  @override
  Future<AuthChallenge> forgotPassword({required String identifier}) async {
    final response = await _request(
      () => _dio.post<dynamic>(
        '/api/v1/auth/forgot-password',
        data: {'identifier': identifier},
      ),
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const AppException('The server returned an invalid response.');
    }
    return AuthChallenge(
      challengeId: data['challengeId'] as String,
      maskedDestination: '',
      expiresInSeconds: data['expiresInSeconds'] as int,
    );
  }

  @override
  Future<void> resetPassword({
    required String challengeId,
    required String otp,
    required String newPassword,
  }) async {
    await _request(
      () => _dio.post<dynamic>(
        '/api/v1/auth/reset-password',
        data: {
          'challengeId': challengeId,
          'otp': otp,
          'newPassword': newPassword,
        },
      ),
    );
  }

  @override
  Future<void> register({
    required String username,
    required String password,
    required String email,
    required String mobileNumber,
  }) async {
    await _request(
      () => _dio.post<dynamic>(
        '/api/v1/auth/register',
        data: {
          'username': username,
          'password': password,
          'email': email,
          'mobileNumber': mobileNumber,
        },
      ),
    );
  }

  @override
  Future<void> logout() async {
    try {
      await _request(() => _dio.post<dynamic>('/api/v1/auth/logout'));
    } finally {
      await _tokenStorage.clear();
    }
  }

  Future<Map<String, dynamic>> _request(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      final body = response.data;
      if (body is! Map<String, dynamic> || body['success'] != true) {
        throw const AppException('Unable to complete the request.');
      }
      return body;
    } on DioException catch (error) {
      throw _friendlyError(error);
    }
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    throw const AppException('The server returned an invalid response.');
  }

  AppException _friendlyError(DioException error) {
    final body = error.response?.data;
    final errorBody = body is Map ? body['error'] : null;
    final code = errorBody is Map ? errorBody['code'] : null;
    final message = switch (code) {
      'INVALID_CREDENTIALS' => 'Unable to authenticate with those credentials.',
      'INVALID_OTP' => 'That verification code is incorrect. Try again.',
      'OTP_EXPIRED' => 'That verification code has expired. Request a new one.',
      'TOO_MANY_ATTEMPTS' =>
        'Too many attempts. Request a new verification code.',
      'INVALID_REFRESH_TOKEN' ||
      'REFRESH_TOKEN_REUSE' => 'Your session expired. Please sign in again.',
      'DUPLICATE_REGISTRATION' =>
        'An account could not be created with those details.',
      _
          when error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError =>
        'Unable to connect. Check your internet connection and try again.',
      _
          when error.response?.statusCode != null &&
              error.response!.statusCode! >= 500 =>
        'The service is temporarily unavailable. Please try again later.',
      _ => 'Unable to complete the request. Please try again.',
    };
    return AppException(message, statusCode: error.response?.statusCode);
  }
}
