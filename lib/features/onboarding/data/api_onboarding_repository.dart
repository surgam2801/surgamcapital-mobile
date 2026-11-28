import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/onboarding_application.dart';
import 'onboarding_repository.dart';

class ApiOnboardingRepository implements OnboardingRepository {
  ApiOnboardingRepository(this._dio);

  final Dio _dio;

  @override
  Future<OnboardingApplication> startOrResume() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/onboarding',
      );
      return _parse(response.data);
    } on DioException catch (error) {
      throw _friendlyError(error);
    }
  }

  @override
  Future<OnboardingApplication> savePersonal({
    required OnboardingApplication application,
    required String firstName,
    required String middleName,
    required String lastName,
    required String dateOfBirth,
    required String gender,
  }) => _put(application, 'personal', {
    'firstName': firstName,
    'middleName': middleName,
    'lastName': lastName,
    'dateOfBirth': dateOfBirth,
    'gender': gender,
  });

  @override
  Future<OnboardingApplication> verifyPan({
    required OnboardingApplication application,
    required String pan,
  }) => _post(application, 'pan/verify', {'pan': pan});

  @override
  Future<OnboardingApplication> checkKyc(OnboardingApplication application) =>
      _post(application, 'kyc/status-check', const {});

  @override
  Future<OnboardingApplication> saveAddress({
    required OnboardingApplication application,
    required String addressLine1,
    required String addressLine2,
    required String city,
    required String state,
    required String postalCode,
    required String countryCode,
  }) => _put(application, 'address', {
    'addressLine1': addressLine1,
    'addressLine2': addressLine2,
    'city': city,
    'state': state,
    'postalCode': postalCode,
    'countryCode': countryCode,
  });

  @override
  Future<OnboardingApplication> saveTaxResidency({
    required OnboardingApplication application,
    required bool taxResidentInIndia,
    required String countryCode,
  }) => _put(application, 'tax-residencies', {
    'taxResidentInIndia': taxResidentInIndia,
    'countryCode': countryCode,
    'declarationVersion': '2026-01',
    'confirmed': true,
  });

  @override
  Future<OnboardingApplication> submit(OnboardingApplication application) =>
      _post(application, 'submit', const {});

  Future<OnboardingApplication> _put(
    OnboardingApplication application,
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/v1/onboarding/${application.applicationId}/$path',
        data: data,
      );
      return _parse(response.data);
    } on DioException catch (error) {
      throw _friendlyError(error);
    }
  }

  Future<OnboardingApplication> _post(
    OnboardingApplication application,
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/onboarding/${application.applicationId}/$path',
        data: data,
      );
      return _parse(response.data);
    } on DioException catch (error) {
      throw _friendlyError(error);
    }
  }

  OnboardingApplication _parse(Map<String, dynamic>? response) {
    final data = response?['data'];
    if (response?['success'] != true || data is! Map<String, dynamic>) {
      throw const AppException('The onboarding response was invalid.');
    }
    return OnboardingApplication.fromJson(data);
  }

  AppException _friendlyError(DioException error) {
    final response = error.response?.data;
    final errorBody = response is Map ? response['error'] : null;
    final message = errorBody is Map && errorBody['message'] is String
        ? errorBody['message'] as String
        : error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout
        ? 'Unable to reach the onboarding service. Check the connection and retry.'
        : 'Unable to save onboarding details. Please retry.';
    return AppException(message, statusCode: error.response?.statusCode);
  }
}
