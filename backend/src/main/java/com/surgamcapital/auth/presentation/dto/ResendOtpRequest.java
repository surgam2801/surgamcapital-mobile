package com.surgamcapital.auth.presentation.dto;

import jakarta.validation.constraints.NotBlank;

public record ResendOtpRequest(@NotBlank String challengeId) {}
