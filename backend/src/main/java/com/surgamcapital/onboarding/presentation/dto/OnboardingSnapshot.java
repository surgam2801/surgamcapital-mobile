package com.surgamcapital.onboarding.presentation.dto;

import com.surgamcapital.onboarding.infrastructure.persistence.OnboardingApplication;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public record OnboardingSnapshot(
        UUID applicationId,
        String applicationReference,
        String onboardingStatus,
        String kycWorkflowStatus,
        String kycProviderStatus,
        String panVerificationStatus,
        String maskedPan,
        Personal personal,
        Address address,
        TaxResidency taxResidency,
        Instant submittedAt,
        Instant updatedAt) {

    public record Personal(String firstName, String middleName, String lastName,
                           LocalDate dateOfBirth, String gender) {}
    public record Address(String addressLine1, String addressLine2, String city,
                          String state, String postalCode, String countryCode) {}
    public record TaxResidency(Boolean taxResidentInIndia, String countryCode,
                               String declarationVersion, Instant declaredAt) {}

    public static OnboardingSnapshot from(OnboardingApplication application) {
        return new OnboardingSnapshot(
                application.getId(),
                application.getApplicationReference(),
                application.getOnboardingStatus(),
                application.getKycWorkflowStatus(),
                application.getKycProviderStatus(),
                application.getPanVerificationStatus(),
                application.getMaskedPan(),
                new Personal(application.getFirstName(), application.getMiddleName(),
                        application.getLastName(), application.getDateOfBirth(),
                        application.getGender()),
                new Address(application.getAddressLine1(), application.getAddressLine2(),
                        application.getCity(), application.getState(),
                        application.getPostalCode(), application.getCountryCode()),
                new TaxResidency(application.getTaxResidentInIndia(),
                        application.getTaxCountryCode(),
                        application.getTaxDeclarationVersion(),
                        application.getTaxDeclaredAt()),
                application.getSubmittedAt(),
                application.getUpdatedAt());
    }
}
