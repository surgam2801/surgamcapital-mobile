package com.surgamcapital.auth.presentation.dto;

import java.util.UUID;

public final class AuthDtos {
    private AuthDtos() {}

    public record RegistrationResult(UUID userId, String status) {}
    public record ChallengeResult(String challengeId, String maskedDestination, int expiresInSeconds) {}
    public record ResetChallengeResult(String challengeId, int expiresInSeconds) {}
    public record TokenResult(String accessToken, String refreshToken, String tokenType,
                              long expiresInSeconds) {}
}
