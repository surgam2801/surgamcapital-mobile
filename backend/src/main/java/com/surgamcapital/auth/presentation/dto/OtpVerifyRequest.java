package com.surgamcapital.auth.presentation.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record OtpVerifyRequest(
        @NotBlank String challengeId,
        @NotBlank @Pattern(regexp = "^\\d{6}$") String otp) {
    @Override
    public String toString() {
        return "OtpVerifyRequest[challengeId=[REDACTED], otp=[REDACTED]]";
    }
}
