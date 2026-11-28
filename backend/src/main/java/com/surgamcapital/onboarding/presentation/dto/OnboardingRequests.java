package com.surgamcapital.onboarding.presentation.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public final class OnboardingRequests {
    private OnboardingRequests() {}

    public record Personal(
            @NotBlank @Size(max = 80) String firstName,
            @Size(max = 80) String middleName,
            @NotBlank @Size(max = 80) String lastName,
            @NotNull @Past LocalDate dateOfBirth,
            @NotBlank @Pattern(regexp = "MALE|FEMALE|OTHER|PREFER_NOT_TO_SAY") String gender) {}

    public record Address(
            @NotBlank @Size(max = 160) String addressLine1,
            @Size(max = 160) String addressLine2,
            @NotBlank @Size(max = 80) String city,
            @NotBlank @Size(max = 80) String state,
            @NotBlank @Pattern(regexp = "[0-9]{6}") String postalCode,
            @NotBlank @Pattern(regexp = "[A-Za-z]{2}") String countryCode) {}

    public record TaxResidency(
            @NotNull Boolean taxResidentInIndia,
            @NotBlank @Pattern(regexp = "[A-Za-z]{2}") String countryCode,
            @NotBlank @Size(max = 32) String declarationVersion,
            @NotNull Boolean confirmed) {}

    public record PanVerification(
            @NotBlank @Pattern(regexp = "[A-Za-z]{5}[0-9]{4}[A-Za-z]") String pan) {}
}
