class AuthChallenge {
  const AuthChallenge({
    required this.challengeId,
    required this.maskedDestination,
    required this.expiresInSeconds,
  });

  final String challengeId;
  final String maskedDestination;
  final int expiresInSeconds;

  factory AuthChallenge.fromJson(Map<String, dynamic> json) => AuthChallenge(
    challengeId: json['challengeId'] as String,
    maskedDestination: json['maskedDestination'] as String,
    expiresInSeconds: json['expiresInSeconds'] as int,
  );
}

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresInSeconds,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresInSeconds;

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    expiresInSeconds: json['expiresInSeconds'] as int,
  );
}

abstract class AuthenticationRepository {
  Future<AuthChallenge> login({
    required String username,
    required String password,
  });
  Future<AuthTokens> verifyOtp({
    required String challengeId,
    required String otp,
  });
  Future<AuthChallenge> resendOtp({required String challengeId});
  Future<AuthChallenge> forgotPassword({required String identifier});
  Future<void> resetPassword({
    required String challengeId,
    required String otp,
    required String newPassword,
  });
  Future<void> register({
    required String username,
    required String password,
    required String email,
    required String mobileNumber,
  });
  Future<void> logout();
}
