import 'authentication_repository.dart';

class MockAuthenticationRepository implements AuthenticationRepository {
  @override
  Future<AuthChallenge> login({
    required String username,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return const AuthChallenge(
      challengeId: 'local-mock-challenge',
      maskedDestination: '******0000',
      expiresInSeconds: 300,
    );
  }

  @override
  Future<AuthTokens> verifyOtp({
    required String challengeId,
    required String otp,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return const AuthTokens(
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
      expiresInSeconds: 900,
    );
  }

  @override
  Future<AuthChallenge> resendOtp({required String challengeId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return const AuthChallenge(
      challengeId: 'local-mock-challenge',
      maskedDestination: '******0000',
      expiresInSeconds: 300,
    );
  }

  @override
  Future<AuthChallenge> forgotPassword({required String identifier}) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return const AuthChallenge(
      challengeId: 'local-mock-reset',
      maskedDestination: '******0000',
      expiresInSeconds: 300,
    );
  }

  @override
  Future<void> resetPassword({
    required String challengeId,
    required String otp,
    required String newPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  @override
  Future<void> register({
    required String username,
    required String password,
    required String email,
    required String mobileNumber,
  }) async {}

  @override
  Future<void> logout() async {}
}
