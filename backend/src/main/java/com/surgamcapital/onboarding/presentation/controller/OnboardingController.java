package com.surgamcapital.onboarding.presentation.controller;

import com.surgamcapital.onboarding.application.service.OnboardingService;
import com.surgamcapital.onboarding.presentation.dto.OnboardingRequests;
import com.surgamcapital.onboarding.presentation.dto.OnboardingSnapshot;
import com.surgamcapital.shared.response.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/onboarding")
public class OnboardingController {
    private final OnboardingService onboarding;

    public OnboardingController(OnboardingService onboarding) {
        this.onboarding = onboarding;
    }

    @PostMapping
    public ApiResponse<OnboardingSnapshot> start(@AuthenticationPrincipal Jwt jwt) {
        return ApiResponse.success("Onboarding application ready.", onboarding.start(userId(jwt)));
    }

    @GetMapping("/current")
    public ApiResponse<OnboardingSnapshot> current(@AuthenticationPrincipal Jwt jwt) {
        return ApiResponse.success("Onboarding application retrieved.", onboarding.current(userId(jwt)));
    }

    @GetMapping("/{applicationId}")
    public ApiResponse<OnboardingSnapshot> get(@AuthenticationPrincipal Jwt jwt,
                                                @PathVariable UUID applicationId) {
        return ApiResponse.success("Onboarding application retrieved.",
                onboarding.get(userId(jwt), applicationId));
    }

    @PutMapping("/{applicationId}/personal")
    public ApiResponse<OnboardingSnapshot> savePersonal(
            @AuthenticationPrincipal Jwt jwt, @PathVariable UUID applicationId,
            @Valid @RequestBody OnboardingRequests.Personal request) {
        return ApiResponse.success("Personal information saved.",
                onboarding.savePersonal(userId(jwt), applicationId, request));
    }

    @PutMapping("/{applicationId}/address")
    public ApiResponse<OnboardingSnapshot> saveAddress(
            @AuthenticationPrincipal Jwt jwt, @PathVariable UUID applicationId,
            @Valid @RequestBody OnboardingRequests.Address request) {
        return ApiResponse.success("Address saved.",
                onboarding.saveAddress(userId(jwt), applicationId, request));
    }

    @PutMapping("/{applicationId}/tax-residencies")
    public ApiResponse<OnboardingSnapshot> saveTaxResidency(
            @AuthenticationPrincipal Jwt jwt, @PathVariable UUID applicationId,
            @Valid @RequestBody OnboardingRequests.TaxResidency request) {
        return ApiResponse.success("Tax residency declaration saved.",
                onboarding.saveTaxResidency(userId(jwt), applicationId, request));
    }

    @PostMapping("/{applicationId}/pan/verify")
    public ApiResponse<OnboardingSnapshot> verifyPan(
            @AuthenticationPrincipal Jwt jwt, @PathVariable UUID applicationId,
            @Valid @RequestBody OnboardingRequests.PanVerification request) {
        return ApiResponse.success("PAN verification request received.",
                onboarding.verifyPan(userId(jwt), applicationId, request));
    }

    @PostMapping("/{applicationId}/kyc/status-check")
    public ApiResponse<OnboardingSnapshot> checkKyc(
            @AuthenticationPrincipal Jwt jwt, @PathVariable UUID applicationId) {
        return ApiResponse.success("Existing KYC status checked.",
                onboarding.checkKyc(userId(jwt), applicationId));
    }

    @PostMapping("/{applicationId}/submit")
    public ApiResponse<OnboardingSnapshot> submit(
            @AuthenticationPrincipal Jwt jwt, @PathVariable UUID applicationId) {
        return ApiResponse.success("Onboarding submitted for verification.",
                onboarding.submit(userId(jwt), applicationId));
    }

    @GetMapping("/{applicationId}/status")
    public ApiResponse<OnboardingSnapshot> status(
            @AuthenticationPrincipal Jwt jwt, @PathVariable UUID applicationId) {
        return ApiResponse.success("Onboarding status retrieved.",
                onboarding.get(userId(jwt), applicationId));
    }

    private UUID userId(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }
}
