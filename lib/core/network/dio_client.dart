import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../errors/app_exception.dart';
import '../../features/authentication/data/token_storage.dart';

class DioClient {
  DioClient({
    Dio? dio,
    String? baseUrl,
    TokenStorage? tokenStorage,
    Future<void> Function()? onSessionExpired,
  }) : dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl:
                   baseUrl ??
                   const String.fromEnvironment(
                     'API_BASE_URL',
                     defaultValue: 'http://localhost:8081',
                   ),
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 20),
             ),
           ) {
    final apiUri = Uri.parse(this.dio.options.baseUrl);
    if (kReleaseMode && apiUri.scheme != 'https') {
      throw StateError('Production API_BASE_URL must use HTTPS.');
    }
    if (tokenStorage != null) {
      this.dio.interceptors.add(
        _AuthInterceptor(this.dio, tokenStorage, onSessionExpired),
      );
    }
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  final Dio dio;

  AppException mapError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map &&
          data['error'] is Map &&
          (data['error'] as Map)['message'] is String) {
        return AppException(
          (data['error'] as Map)['message'] as String,
          statusCode: error.response?.statusCode,
        );
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return const AppException(
          'Unable to connect. Check your internet connection and try again.',
        );
      }
      return AppException(
        'Unable to complete the request. Please try again.',
        statusCode: error.response?.statusCode,
      );
    }
    return const AppException('An unexpected error occurred.');
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio, this._storage, this._onSessionExpired);

  final Dio _dio;
  final TokenStorage _storage;
  final Future<void> Function()? _onSessionExpired;
  Future<String?>? _refreshing;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _storage.readAccessToken();
    if (accessToken != null &&
        _sameOrigin(options.uri, Uri.parse(_dio.options.baseUrl)) &&
        !_isAuthPath(options.path)) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final request = error.requestOptions;
    if (error.response?.statusCode != 401 ||
        request.extra['authRetry'] == true ||
        !_sameOrigin(request.uri, Uri.parse(_dio.options.baseUrl)) ||
        _isAuthPath(request.path)) {
      handler.next(error);
      return;
    }
    try {
      final accessToken = await (_refreshing ??= _refresh());
      _refreshing = null;
      if (accessToken == null) {
        await _expireSession();
        handler.next(error);
        return;
      }
      request
        ..headers['Authorization'] = 'Bearer $accessToken'
        ..extra['authRetry'] = true;
      handler.resolve(await _dio.fetch<dynamic>(request));
    } on DioException {
      _refreshing = null;
      await _expireSession();
      handler.next(error);
    }
  }

  Future<void> _expireSession() async {
    await _storage.clear();
    await _onSessionExpired?.call();
  }

  Future<String?> _refresh() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null) return null;
    final response =
        await Dio(
          BaseOptions(
            baseUrl: _dio.options.baseUrl,
            connectTimeout: _dio.options.connectTimeout,
            receiveTimeout: _dio.options.receiveTimeout,
          ),
        ).post<Map<String, dynamic>>(
          '/api/v1/auth/refresh',
          data: {'refreshToken': refreshToken},
        );
    final data = response.data?['data'] as Map<String, dynamic>?;
    if (response.data?['success'] != true || data == null) {
      await _storage.clear();
      return null;
    }
    await _storage.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    return data['accessToken'] as String;
  }

  bool _isAuthPath(String path) =>
      path.endsWith('/api/v1/auth/register') ||
      path.endsWith('/api/v1/auth/login') ||
      path.endsWith('/api/v1/auth/otp/verify') ||
      path.endsWith('/api/v1/auth/otp/resend') ||
      path.endsWith('/api/v1/auth/refresh') ||
      path.endsWith('/api/v1/auth/forgot-password') ||
      path.endsWith('/api/v1/auth/reset-password');

  bool _sameOrigin(Uri request, Uri base) =>
      request.scheme == base.scheme &&
      request.host == base.host &&
      request.port == base.port;
}
