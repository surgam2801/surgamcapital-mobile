package com.surgamcapital.onboarding.application.service;

import com.surgamcapital.onboarding.application.port.KycProvider;
import com.surgamcapital.onboarding.application.port.PanVerificationProvider;
import com.surgamcapital.onboarding.infrastructure.persistence.OnboardingApplication;
import com.surgamcapital.onboarding.infrastructure.persistence.OnboardingApplicationRepository;
import com.surgamcapital.onboarding.infrastructure.persistence.OnboardingStatusHistory;
import com.surgamcapital.onboarding.infrastructure.persistence.OnboardingStatusHistoryRepository;
import com.surgamcapital.onboarding.presentation.dto.OnboardingRequests;
import com.surgamcapital.onboarding.presentation.dto.OnboardingSnapshot;
import com.surgamcapital.shared.exception.AuthException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;
import java.util.UUID;

@Service
public class OnboardingService {
    private final OnboardingApplicationRepository applications;
    private final OnboardingStatusHistoryRepository history;
    private final PanVerificationProvider panProvider;
    private final KycProvider kycProvider;
    private final PanLookupHasher panHasher;
    private final SensitiveDataEncryptionService encryption;

    public OnboardingService(OnboardingApplicationRepository applications,
                             OnboardingStatusHistoryRepository history,
                             PanVerificationProvider panProvider,
                             KycProvider kycProvider,
                             PanLookupHasher panHasher,
                             SensitiveDataEncryptionService encryption) {
        this.applications = applications;
        this.history = history;
        this.panProvider = panProvider;
        this.kycProvider = kycProvider;
        this.panHasher = panHasher;
        this.encryption = encryption;
    }

    @Transactional
    public OnboardingSnapshot start(UUID userId) {
        OnboardingApplication application = applications.findByUserId(userId)
                .orElseGet(() -> applications.save(new OnboardingApplication(
                        userId, "SC-" + UUID.randomUUID().toString().substring(0, 12)
                                .toUpperCase(Locale.ROOT))));
        return OnboardingSnapshot.from(application);
    }

    @Transactional(readOnly = true)
    public OnboardingSnapshot current(UUID userId) {
        return OnboardingSnapshot.from(findForUser(userId));
    }

    @Transactional(readOnly = true)
    public OnboardingSnapshot get(UUID userId, UUID applicationId) {
        return OnboardingSnapshot.from(findForUser(userId, applicationId));
    }

    @Transactional
    public OnboardingSnapshot savePersonal(UUID userId, UUID applicationId,
                                           OnboardingRequests.Personal request) {
        OnboardingApplication application = findForUser(userId, applicationId);
        requireEditable(application);
        String previousStatus = application.getOnboardingStatus();
        application.updatePersonal(request.firstName(), request.middleName(),
                request.lastName(), request.dateOfBirth(), request.gender());
        recordTransition(application, userId, previousStatus, "PERSONAL_SAVED");
        return OnboardingSnapshot.from(applications.save(application));
    }

    @Transactional
    public OnboardingSnapshot saveAddress(UUID userId, UUID applicationId,
                                          OnboardingRequests.Address request) {
        OnboardingApplication application = findForUser(userId, applicationId);
        requireEditable(application);
        String previousStatus = application.getOnboardingStatus();
        application.updateAddress(request.addressLine1(), request.addressLine2(),
                request.city(), request.state(), request.postalCode(), request.countryCode());
        recordTransition(application, userId, previousStatus, "ADDRESS_SAVED");
        return OnboardingSnapshot.from(applications.save(application));
    }

    @Transactional
    public OnboardingSnapshot saveTaxResidency(UUID userId, UUID applicationId,
                                               OnboardingRequests.TaxResidency request) {
        if (!request.confirmed()) {
            throw badRequest("TAX_DECLARATION_NOT_CONFIRMED",
                    "Confirm the tax residency declaration to continue.");
        }
        if (request.taxResidentInIndia()
                && !"IN".equalsIgnoreCase(request.countryCode())) {
            throw badRequest("TAX_RESIDENCY_MISMATCH",
                    "The declared country must match the selected Indian tax residency.");
        }
        OnboardingApplication application = findForUser(userId, applicationId);
        requireEditable(application);
        String previousStatus = application.getOnboardingStatus();
        application.updateTaxResidency(request.taxResidentInIndia(),
                request.countryCode(), request.declarationVersion());
        recordTransition(application, userId, previousStatus, "TAX_RESIDENCY_SAVED");
        return OnboardingSnapshot.from(applications.save(application));
    }

    @Transactional
    public OnboardingSnapshot verifyPan(UUID userId, UUID applicationId,
                                        OnboardingRequests.PanVerification request) {
        OnboardingApplication application = findForUser(userId, applicationId);
        requireEditable(application);
        String previousStatus = application.getOnboardingStatus();
        String pan = request.pan().trim().toUpperCase(Locale.ROOT);
        String panHash = panHasher.hash(pan);
        if (applications.existsByPanLookupHashAndIdNot(panHash, application.getId())) {
            throw new AuthException(HttpStatus.CONFLICT, "PAN_ALREADY_IN_USE",
                    "This PAN cannot be used for this application.");
        }
        PanVerificationProvider.PanResult result = panProvider.verify(pan);
        if (!java.util.Set.of("NOT_STARTED", "PENDING", "VERIFIED", "FAILED",
                "MANUAL_REVIEW_REQUIRED")
                .contains(result.status())) {
            throw new AuthException(HttpStatus.BAD_GATEWAY, "PAN_PROVIDER_INVALID_RESPONSE",
                    "PAN verification is temporarily unavailable.");
        }
        application.recordPan(panHash, encryption.encrypt(pan),
                PanLookupHasher.mask(pan), result.status(), result.providerReference());
        recordTransition(application, userId, previousStatus, "PAN_VERIFICATION_REQUESTED");
        return OnboardingSnapshot.from(applications.save(application));
    }

    @Transactional
    public OnboardingSnapshot checkKyc(UUID userId, UUID applicationId) {
        OnboardingApplication application = findForUser(userId, applicationId);
        if (application.getMaskedPan() == null) {
            throw badRequest("PAN_REQUIRED", "Complete PAN verification before checking existing KYC.");
        }
        KycProvider.KycResult result = kycProvider.checkExisting(
                encryption.decrypt(application.getPanEncrypted()));
        if (!java.util.Set.of("VALIDATED", "REGISTERED", "ON_HOLD", "REJECTED",
                "PENDING", "UNKNOWN").contains(result.providerStatus())) {
            throw new AuthException(HttpStatus.BAD_GATEWAY, "KYC_PROVIDER_INVALID_RESPONSE",
                    "Existing KYC status is temporarily unavailable.");
        }
        application.recordKycProviderStatus(result.providerStatus(), result.providerReference());
        return OnboardingSnapshot.from(applications.save(application));
    }

    @Transactional
    public OnboardingSnapshot submit(UUID userId, UUID applicationId) {
        OnboardingApplication application = findForUser(userId, applicationId);
        String previousStatus = application.getOnboardingStatus();
        try {
            application.submit();
        } catch (IllegalStateException exception) {
            throw badRequest("ONBOARDING_INCOMPLETE", exception.getMessage());
        }
        recordTransition(application, userId, previousStatus, "INVESTOR_SUBMITTED");
        return OnboardingSnapshot.from(applications.save(application));
    }

    private OnboardingApplication findForUser(UUID userId) {
        return applications.findByUserId(userId)
                .orElseThrow(() -> new AuthException(HttpStatus.NOT_FOUND,
                        "ONBOARDING_NOT_FOUND", "No onboarding application was found."));
    }

    private OnboardingApplication findForUser(UUID userId, UUID applicationId) {
        return applications.findByIdAndUserId(applicationId, userId)
                .orElseThrow(() -> new AuthException(HttpStatus.NOT_FOUND,
                        "ONBOARDING_NOT_FOUND", "No onboarding application was found."));
    }

    private void requireEditable(OnboardingApplication application) {
        if (!EDITABLE_STATUSES.contains(application.getOnboardingStatus())) {
            throw new AuthException(HttpStatus.CONFLICT, "ONBOARDING_NOT_EDITABLE",
                    "This onboarding application can no longer be edited.");
        }
    }

    private AuthException badRequest(String code, String message) {
        return new AuthException(HttpStatus.BAD_REQUEST, code, message);
    }

    private void recordTransition(OnboardingApplication application, UUID userId,
                                  String fromStatus, String reason) {
        if (!fromStatus.equals(application.getOnboardingStatus())) {
            history.save(new OnboardingStatusHistory(application.getId(), fromStatus,
                    application.getOnboardingStatus(), userId, reason));
        }
    }

    private static final java.util.Set<String> EDITABLE_STATUSES =
            java.util.Set.of("DRAFT", "IN_PROGRESS", "ACTION_REQUIRED", "REJECTED");
}
