package com.surgamcapital.auth.presentation.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record ResetPasswordRequest(
        @NotBlank String challengeId,
        @NotBlank @Pattern(regexp = "^\\d{6}$") String otp,
        @NotBlank @Size(min = 12, max = 128) String newPassword) {
    @Override
    public String toString() {
        return "ResetPasswordRequest[challengeId=[REDACTED], otp=[REDACTED], newPassword=[REDACTED]]";
    }
}
