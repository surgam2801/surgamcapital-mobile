import '../domain/onboarding_application.dart';
import 'onboarding_repository.dart';

class MockOnboardingRepository implements OnboardingRepository {
  OnboardingApplication? _application;

  OnboardingApplication _make({
    String? onboardingStatus,
    String? panVerificationStatus,
    String? kycProviderStatus,
    String? kycWorkflowStatus,
    String? maskedPan,
    Map<String, dynamic>? personal,
    Map<String, dynamic>? address,
    Map<String, dynamic>? taxResidency,
    DateTime? submittedAt,
    DateTime? updatedAt,
  }) => OnboardingApplication(
    applicationId: _application?.applicationId ?? 'mock-onboarding',
    applicationReference: _application?.applicationReference ?? 'SC-DEMO-0001',
    onboardingStatus:
        onboardingStatus ?? _application?.onboardingStatus ?? 'DRAFT',
    kycWorkflowStatus:
        kycWorkflowStatus ?? _application?.kycWorkflowStatus ?? 'NOT_STARTED',
    kycProviderStatus:
        kycProviderStatus ?? _application?.kycProviderStatus ?? 'UNKNOWN',
    panVerificationStatus:
        panVerificationStatus ??
        _application?.panVerificationStatus ??
        'NOT_STARTED',
    maskedPan: maskedPan ?? _application?.maskedPan,
    personal: personal ?? _application?.personal ?? const {},
    address: address ?? _application?.address ?? const {},
    taxResidency: taxResidency ?? _application?.taxResidency ?? const {},
    submittedAt: submittedAt ?? _application?.submittedAt,
    updatedAt: updatedAt ?? DateTime.now().toUtc(),
  );

  @override
  Future<OnboardingApplication> startOrResume() async =>
      _application ??= _make();

  @override
  Future<OnboardingApplication> savePersonal({
    required OnboardingApplication application,
    required String firstName,
    required String middleName,
    required String lastName,
    required String dateOfBirth,
    required String gender,
  }) async => _application = _make(
    onboardingStatus: 'IN_PROGRESS',
    personal: {
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
    },
  );

  @override
  Future<OnboardingApplication> verifyPan({
    required OnboardingApplication application,
    required String pan,
  }) async => _application = _make(
    onboardingStatus: 'IN_PROGRESS',
    panVerificationStatus: 'PENDING',
    maskedPan: '*****${pan.toUpperCase().substring(5)}',
  );

  @override
  Future<OnboardingApplication> checkKyc(
    OnboardingApplication application,
  ) async => _application = _make(
    kycProviderStatus: 'UNKNOWN',
    kycWorkflowStatus: 'NOT_STARTED',
  );

  @override
  Future<OnboardingApplication> saveAddress({
    required OnboardingApplication application,
    required String addressLine1,
    required String addressLine2,
    required String city,
    required String state,
    required String postalCode,
    required String countryCode,
  }) async => _application = _make(
    onboardingStatus: 'IN_PROGRESS',
    address: {
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'countryCode': countryCode,
    },
  );

  @override
  Future<OnboardingApplication> saveTaxResidency({
    required OnboardingApplication application,
    required bool taxResidentInIndia,
    required String countryCode,
  }) async => _application = _make(
    onboardingStatus: 'IN_PROGRESS',
    taxResidency: {
      'taxResidentInIndia': taxResidentInIndia,
      'countryCode': countryCode,
      'declarationVersion': '2026-01',
    },
  );

  @override
  Future<OnboardingApplication> submit(
    OnboardingApplication application,
  ) async => _application = _make(
    onboardingStatus: 'PENDING_VERIFICATION',
    kycWorkflowStatus: 'PENDING',
    submittedAt: DateTime.now().toUtc(),
  );
}
