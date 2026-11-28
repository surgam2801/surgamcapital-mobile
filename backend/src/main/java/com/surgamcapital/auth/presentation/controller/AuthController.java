package com.surgamcapital.auth.presentation.controller;

import com.surgamcapital.auth.application.service.AuthenticationService;
import com.surgamcapital.auth.presentation.dto.AuthDtos.ChallengeResult;
import com.surgamcapital.auth.presentation.dto.AuthDtos.RegistrationResult;
import com.surgamcapital.auth.presentation.dto.AuthDtos.ResetChallengeResult;
import com.surgamcapital.auth.presentation.dto.AuthDtos.TokenResult;
import com.surgamcapital.auth.presentation.dto.LoginRequest;
import com.surgamcapital.auth.presentation.dto.ForgotPasswordRequest;
import com.surgamcapital.auth.presentation.dto.OtpVerifyRequest;
import com.surgamcapital.auth.presentation.dto.ResetPasswordRequest;
import com.surgamcapital.auth.presentation.dto.RefreshRequest;
import com.surgamcapital.auth.presentation.dto.RegisterRequest;
import com.surgamcapital.auth.presentation.dto.ResendOtpRequest;
import com.surgamcapital.shared.response.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {
    private final AuthenticationService authentication;

    public AuthController(AuthenticationService authentication) {
        this.authentication = authentication;
    }

    @PostMapping("/register")
    public ApiResponse<RegistrationResult> register(@Valid @RequestBody RegisterRequest request) {
        return ApiResponse.success("Registration received.", authentication.register(request));
    }

    @PostMapping("/login")
    public ApiResponse<ChallengeResult> login(@Valid @RequestBody LoginRequest request) {
        return ApiResponse.success("OTP challenge initiated.", authentication.login(request));
    }

    @PostMapping("/otp/verify")
    public ApiResponse<TokenResult> verifyOtp(@Valid @RequestBody OtpVerifyRequest request) {
        return ApiResponse.success("Authentication successful.", authentication.verifyOtp(request));
    }

    @PostMapping("/otp/resend")
    public ApiResponse<ChallengeResult> resendOtp(@Valid @RequestBody ResendOtpRequest request) {
        return ApiResponse.success("OTP challenge resent.", authentication.resendOtp(request.challengeId()));
    }

    @PostMapping("/refresh")
    public ApiResponse<TokenResult> refresh(@Valid @RequestBody RefreshRequest request) {
        return ApiResponse.success("Session refreshed.", authentication.refresh(request.refreshToken()));
    }

    @PostMapping("/forgot-password")
    public ApiResponse<ResetChallengeResult> forgotPassword(
            @Valid @RequestBody ForgotPasswordRequest request) {
        return ApiResponse.success("If the account exists, password reset instructions were sent.",
                authentication.forgotPassword(request.identifier()));
    }

    @PostMapping("/reset-password")
    public ApiResponse<Map<String, Boolean>> resetPassword(
            @Valid @RequestBody ResetPasswordRequest request) {
        authentication.resetPassword(request.challengeId(), request.otp(), request.newPassword());
        return ApiResponse.success("Password updated.", Map.of("updated", true));
    }

    @PostMapping("/logout")
    public ApiResponse<Map<String, Boolean>> logout(@AuthenticationPrincipal Jwt jwt) {
        authentication.logout(UUID.fromString(jwt.getClaimAsString("sid")));
        return ApiResponse.success("Logged out.", Map.of("loggedOut", true));
    }
}
