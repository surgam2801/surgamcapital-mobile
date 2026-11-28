import 'package:flutter_test/flutter_test.dart';
import 'package:surgam_capital/features/authentication/data/mock_authentication_repository.dart';

void main() {
  test('mock login completes', () async {
    final repository = MockAuthenticationRepository();
    await repository.login(username: 'investor', password: 'not-real');
  });

  test('mock OTP verification completes', () async {
    final repository = MockAuthenticationRepository();
    await repository.verifyOtp(
      challengeId: 'local-mock-challenge',
      otp: '123456',
    );
  });
}
