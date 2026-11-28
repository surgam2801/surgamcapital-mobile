package com.surgamcapital.onboarding.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "onboarding_applications")
public class OnboardingApplication {
    @Id
    private UUID id;
    @Column(name = "user_id", nullable = false, unique = true)
    private UUID userId;
    @Column(name = "application_reference", nullable = false, unique = true, length = 24)
    private String applicationReference;
    @Column(name = "onboarding_status", nullable = false, length = 32)
    private String onboardingStatus;
    @Column(name = "kyc_workflow_status", nullable = false, length = 32)
    private String kycWorkflowStatus;
    @Column(name = "kyc_provider_status", nullable = false, length = 32)
    private String kycProviderStatus;
    @Column(name = "pan_verification_status", nullable = false, length = 32)
    private String panVerificationStatus;
    @Column(name = "pan_lookup_hash", length = 64)
    private String panLookupHash;
    @Column(name = "pan_encrypted")
    private byte[] panEncrypted;
    @Column(name = "masked_pan", length = 10)
    private String maskedPan;
    @Column(name = "pan_provider_reference", length = 120)
    private String panProviderReference;
    @Column(name = "kyc_provider_reference", length = 120)
    private String kycProviderReference;
    @Column(name = "first_name", length = 80)
    private String firstName;
    @Column(name = "middle_name", length = 80)
    private String middleName;
    @Column(name = "last_name", length = 80)
    private String lastName;
    @Column(name = "date_of_birth")
    private LocalDate dateOfBirth;
    @Column(length = 24)
    private String gender;
    @Column(name = "address_line_1", length = 160)
    private String addressLine1;
    @Column(name = "address_line_2", length = 160)
    private String addressLine2;
    @Column(length = 80)
    private String city;
    @Column(length = 80)
    private String state;
    @Column(name = "postal_code", length = 10)
    private String postalCode;
    @Column(name = "country_code", length = 2)
    private String countryCode;
    @Column(name = "tax_resident_in_india")
    private Boolean taxResidentInIndia;
    @Column(name = "tax_country_code", length = 2)
    private String taxCountryCode;
    @Column(name = "tax_declaration_version", length = 32)
    private String taxDeclarationVersion;
    @Column(name = "tax_declared_at")
    private Instant taxDeclaredAt;
    @Column(name = "submitted_at")
    private Instant submittedAt;
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
    @Version
    private long version;

    protected OnboardingApplication() {}

    public OnboardingApplication(UUID userId, String applicationReference) {
        this.id = UUID.randomUUID();
        this.userId = userId;
        this.applicationReference = applicationReference;
        this.onboardingStatus = "DRAFT";
        this.kycWorkflowStatus = "NOT_STARTED";
        this.kycProviderStatus = "UNKNOWN";
        this.panVerificationStatus = "NOT_STARTED";
        this.createdAt = Instant.now();
        this.updatedAt = this.createdAt;
    }

    public UUID getId() { return id; }
    public UUID getUserId() { return userId; }
    public String getApplicationReference() { return applicationReference; }
    public String getOnboardingStatus() { return onboardingStatus; }
    public String getKycWorkflowStatus() { return kycWorkflowStatus; }
    public String getKycProviderStatus() { return kycProviderStatus; }
    public String getPanVerificationStatus() { return panVerificationStatus; }
    public String getMaskedPan() { return maskedPan; }
    public byte[] getPanEncrypted() { return panEncrypted == null ? null : panEncrypted.clone(); }
    public String getFirstName() { return firstName; }
    public String getMiddleName() { return middleName; }
    public String getLastName() { return lastName; }
    public LocalDate getDateOfBirth() { return dateOfBirth; }
    public String getGender() { return gender; }
    public String getAddressLine1() { return addressLine1; }
    public String getAddressLine2() { return addressLine2; }
    public String getCity() { return city; }
    public String getState() { return state; }
    public String getPostalCode() { return postalCode; }
    public String getCountryCode() { return countryCode; }
    public Boolean getTaxResidentInIndia() { return taxResidentInIndia; }
    public String getTaxCountryCode() { return taxCountryCode; }
    public String getTaxDeclarationVersion() { return taxDeclarationVersion; }
    public Instant getTaxDeclaredAt() { return taxDeclaredAt; }
    public Instant getSubmittedAt() { return submittedAt; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }

    public void updatePersonal(String first, String middle, String last,
                               LocalDate dob, String gender) {
        this.firstName = first.trim();
        this.middleName = middle == null || middle.isBlank() ? null : middle.trim();
        this.lastName = last.trim();
        this.dateOfBirth = dob;
        this.gender = gender;
        markInProgress();
    }

    public void updateAddress(String line1, String line2, String city, String state,
                              String postalCode, String countryCode) {
        this.addressLine1 = line1.trim();
        this.addressLine2 = line2 == null || line2.isBlank() ? null : line2.trim();
        this.city = city.trim();
        this.state = state.trim();
        this.postalCode = postalCode.trim();
        this.countryCode = countryCode.toUpperCase(java.util.Locale.ROOT);
        markInProgress();
    }

    public void updateTaxResidency(boolean residentInIndia, String countryCode,
                                   String declarationVersion) {
        this.taxResidentInIndia = residentInIndia;
        this.taxCountryCode = countryCode.toUpperCase(java.util.Locale.ROOT);
        this.taxDeclarationVersion = declarationVersion;
        this.taxDeclaredAt = Instant.now();
        markInProgress();
    }

    public void recordPan(String lookupHash, byte[] encryptedPan, String maskedPan,
                          String status, String providerReference) {
        this.panLookupHash = lookupHash;
        this.panEncrypted = encryptedPan.clone();
        this.maskedPan = maskedPan;
        this.panVerificationStatus = status;
        this.panProviderReference = providerReference;
        markInProgress();
    }

    public void recordKycProviderStatus(String providerStatus, String providerReference) {
        this.kycProviderStatus = providerStatus;
        this.kycProviderReference = providerReference;
        this.kycWorkflowStatus = switch (providerStatus) {
            case "VALIDATED" -> "VERIFIED";
            case "ON_HOLD", "REJECTED" -> "ACTION_REQUIRED";
            case "REGISTERED", "PENDING" -> "PENDING";
            default -> "NOT_STARTED";
        };
        this.updatedAt = Instant.now();
    }

    public void submit() {
        if (firstName == null || lastName == null || dateOfBirth == null
                || addressLine1 == null || city == null || state == null
                || postalCode == null || countryCode == null
                || taxResidentInIndia == null || taxCountryCode == null
                || taxDeclarationVersion == null || panLookupHash == null) {
            throw new IllegalStateException("Complete the required onboarding information first.");
        }
        if (onboardingStatus.equals("PENDING_VERIFICATION")
                || onboardingStatus.equals("APPROVED")) return;
        String next = "PENDING_VERIFICATION";
        com.surgamcapital.onboarding.domain.OnboardingStatuses
                .requireTransition(onboardingStatus, next);
        onboardingStatus = next;
        submittedAt = Instant.now();
        updatedAt = submittedAt;
        if (!kycWorkflowStatus.equals("VERIFIED")) kycWorkflowStatus = "PENDING";
    }

    private void markInProgress() {
        if (onboardingStatus.equals("DRAFT") || onboardingStatus.equals("ACTION_REQUIRED")
                || onboardingStatus.equals("REJECTED")) {
            com.surgamcapital.onboarding.domain.OnboardingStatuses
                    .requireTransition(onboardingStatus, "IN_PROGRESS");
            onboardingStatus = "IN_PROGRESS";
        }
        updatedAt = Instant.now();
    }
}
