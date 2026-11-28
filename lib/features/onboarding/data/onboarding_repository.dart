import '../domain/onboarding_application.dart';

abstract interface class OnboardingRepository {
  Future<OnboardingApplication> startOrResume();
  Future<OnboardingApplication> savePersonal({
    required OnboardingApplication application,
    required String firstName,
    required String middleName,
    required String lastName,
    required String dateOfBirth,
    required String gender,
  });
  Future<OnboardingApplication> verifyPan({
    required OnboardingApplication application,
    required String pan,
  });
  Future<OnboardingApplication> checkKyc(OnboardingApplication application);
  Future<OnboardingApplication> saveAddress({
    required OnboardingApplication application,
    required String addressLine1,
    required String addressLine2,
    required String city,
    required String state,
    required String postalCode,
    required String countryCode,
  });
  Future<OnboardingApplication> saveTaxResidency({
    required OnboardingApplication application,
    required bool taxResidentInIndia,
    required String countryCode,
  });
  Future<OnboardingApplication> submit(OnboardingApplication application);
}
