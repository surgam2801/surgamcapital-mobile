import 'package:flutter_test/flutter_test.dart';
import 'package:surgam_capital/features/onboarding/data/mock_onboarding_repository.dart';

void main() {
  test(
    'mock provider journey stays pending and preserves separate KYC states',
    () async {
      final repository = MockOnboardingRepository();
      var application = await repository.startOrResume();

      application = await repository.savePersonal(
        application: application,
        firstName: 'Demo',
        middleName: '',
        lastName: 'Investor',
        dateOfBirth: '1990-01-01',
        gender: 'PREFER_NOT_TO_SAY',
      );
      application = await repository.verifyPan(
        application: application,
        pan: 'ABCDE1234F',
      );
      expect(application.panVerificationStatus, 'PENDING');
      expect(application.maskedPan, '*****1234F');
      application = await repository.checkKyc(application);
      expect(application.kycProviderStatus, 'UNKNOWN');
      expect(application.kycWorkflowStatus, 'NOT_STARTED');

      application = await repository.saveAddress(
        application: application,
        addressLine1: '1 Example Road',
        addressLine2: '',
        city: 'Mumbai',
        state: 'Maharashtra',
        postalCode: '400001',
        countryCode: 'IN',
      );
      application = await repository.saveTaxResidency(
        application: application,
        taxResidentInIndia: true,
        countryCode: 'IN',
      );
      application = await repository.submit(application);

      expect(application.onboardingStatus, 'PENDING_VERIFICATION');
      expect(application.kycWorkflowStatus, 'PENDING');
      expect(application.kycProviderStatus, 'UNKNOWN');
    },
  );
}
