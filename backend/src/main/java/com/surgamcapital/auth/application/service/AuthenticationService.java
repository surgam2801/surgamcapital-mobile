package com.surgamcapital.auth.application.service;

import com.surgamcapital.auth.domain.model.UserAccount;
import com.surgamcapital.auth.domain.model.UserCredential;
import com.surgamcapital.auth.infrastructure.persistence.RefreshToken;
import com.surgamcapital.auth.infrastructure.persistence.RefreshTokenRepository;
import com.surgamcapital.auth.infrastructure.persistence.UserRepository;
import com.surgamcapital.auth.infrastructure.persistence.UserCredentialRepository;
import com.surgamcapital.auth.infrastructure.persistence.UserSession;
import com.surgamcapital.auth.infrastructure.persistence.UserSessionRepository;
import com.surgamcapital.auth.presentation.dto.AuthDtos.ChallengeResult;
import com.surgamcapital.auth.presentation.dto.AuthDtos.RegistrationResult;
import com.surgamcapital.auth.presentation.dto.AuthDtos.ResetChallengeResult;
import com.surgamcapital.auth.presentation.dto.AuthDtos.TokenResult;
import com.surgamcapital.auth.presentation.dto.LoginRequest;
import com.surgamcapital.auth.presentation.dto.OtpVerifyRequest;
import com.surgamcapital.auth.presentation.dto.RegisterRequest;
import com.surgamcapital.shared.exception.AuthException;
import com.surgamcapital.shared.audit.AuditService;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class AuthenticationService {
    private final UserRepository users;
    private final UserCredentialRepository credentials;
    private final UserSessionRepository sessions;
    private final RefreshTokenRepository refreshTokens;
    private final PasswordEncoder passwords;
    private final OtpChallengeService otp;
    private final TokenService tokens;
    private final AbuseControlService abuseControl;
    private final AuditService audit;
    private final PasswordPolicy passwordPolicy;
    private final String dummyPasswordHash;

    public AuthenticationService(UserRepository users, UserCredentialRepository credentials,
                                 UserSessionRepository sessions,
                                 RefreshTokenRepository refreshTokens, PasswordEncoder passwords,
                                 OtpChallengeService otp, TokenService tokens,
                                 AbuseControlService abuseControl, AuditService audit,
                                 PasswordPolicy passwordPolicy) {
        this.users = users;
        this.credentials = credentials;
        this.sessions = sessions;
        this.refreshTokens = refreshTokens;
        this.passwords = passwords;
        this.otp = otp;
        this.tokens = tokens;
        this.abuseControl = abuseControl;
        this.audit = audit;
        this.passwordPolicy = passwordPolicy;
        this.dummyPasswordHash = passwords.encode(UUID.randomUUID() + "-not-a-user-password");
    }

    @Transactional
    public RegistrationResult register(RegisterRequest request) {
        passwordPolicy.validate(request.password());
        String username = request.username().trim().toLowerCase(java.util.Locale.ROOT);
        String email = request.email().trim().toLowerCase(java.util.Locale.ROOT);
        if (users.existsByNormalizedUsername(username) || users.existsByNormalizedEmail(email)
                || users.existsByMobileE164(request.mobileNumber())) {
            throw new AuthException(HttpStatus.CONFLICT, "DUPLICATE_REGISTRATION",
                    "An account could not be created with the supplied information.");
        }
        UserAccount user = users.save(new UserAccount(request.username(), email,
                request.mobileNumber()));
        users.flush();
        credentials.save(new UserCredential(user.getId(), passwords.encode(request.password())));
        audit.record("REGISTRATION_COMPLETED", user.getId());
        return new RegistrationResult(user.getId(), user.getStatus());
    }

    @Transactional(noRollbackFor = AuthException.class)
    public ChallengeResult login(LoginRequest request) {
        String username = request.username().trim().toLowerCase(java.util.Locale.ROOT);
        UserAccount user = users.findByNormalizedUsername(username).orElse(null);
        UserCredential credential = user == null ? null
                : credentials.findById(user.getId()).orElse(null);
        boolean validPassword = credential == null
                ? passwords.matches(request.password(), dummyPasswordHash)
                : passwords.matches(request.password(), credential.getPasswordHash());
        if (user == null || !validPassword
                || "LOCKED".equals(user.getStatus()) || "DISABLED".equals(user.getStatus())) {
            abuseControl.failedLogin(username);
            audit.record("LOGIN_FAILURE", user == null ? null : user.getId());
            throw AuthException.invalidCredentials();
        }
        abuseControl.successfulLogin(username);
        OtpChallengeService.Challenge challenge = otp.issue(user);
        audit.record("OTP_CHALLENGE_CREATED", user.getId());
        return new ChallengeResult(challenge.challengeId(), challenge.maskedDestination(),
                challenge.expiresInSeconds());
    }

    public ChallengeResult resendOtp(String challengeId) {
        OtpChallengeService.Challenge challenge = otp.resend(challengeId);
        return new ChallengeResult(challenge.challengeId(), challenge.maskedDestination(),
                challenge.expiresInSeconds());
    }

    public ResetChallengeResult forgotPassword(String identifier) {
        abuseControl.forgotPasswordRequest(identifier);
        String normalized = identifier.trim().toLowerCase(java.util.Locale.ROOT);
        UserAccount user = users.findByNormalizedUsername(normalized)
                .or(() -> users.findByNormalizedEmail(normalized))
                .or(() -> users.findByMobileE164(identifier.trim()))
                .orElse(null);
        if (user == null) {
            return new ResetChallengeResult(UUID.randomUUID().toString(), 300);
        }
        OtpChallengeService.Challenge challenge = otp.issuePasswordReset(user);
        audit.record("PASSWORD_RESET_INITIATED", user.getId());
        return new ResetChallengeResult(challenge.challengeId(), challenge.expiresInSeconds());
    }

    @Transactional(noRollbackFor = AuthException.class)
    public void resetPassword(String challengeId, String otpCode, String newPassword) {
        passwordPolicy.validate(newPassword);
        UUID userId;
        try {
            userId = otp.verifyPasswordReset(challengeId, otpCode);
        } catch (AuthException exception) {
            audit.record("PASSWORD_RESET_FAILURE", null);
            throw exception;
        }
        UserAccount user = users.findById(userId).orElseThrow(AuthException::invalidCredentials);
        UserCredential credential = credentials.findById(userId)
                .orElseThrow(AuthException::invalidCredentials);
        credential.updatePasswordHash(passwords.encode(newPassword));
        for (UserSession session : sessions.findAllByUserId(userId)) {
            session.revoke();
            revokeFamily(session.getFamilyId());
        }
        audit.record("PASSWORD_RESET_COMPLETED", userId);
    }

    @Transactional(noRollbackFor = AuthException.class)
    public TokenResult verifyOtp(OtpVerifyRequest request) {
        UUID userId;
        try {
            userId = otp.verify(request.challengeId(), request.otp());
        } catch (AuthException exception) {
            audit.record("OTP_VERIFICATION_FAILURE", null);
            throw exception;
        }
        UserAccount user = users.findById(userId)
                .orElseThrow(AuthException::invalidCredentials);
        user.activate();
        audit.record("OTP_VERIFICATION_SUCCESS", user.getId());
        String rawRefreshToken = tokens.newRefreshToken();
        UUID familyId = UUID.randomUUID();
        UserSession session = sessions.save(new UserSession(user.getId(), familyId,
                tokens.hashRefreshToken(rawRefreshToken), tokens.refreshExpiry()));
        refreshTokens.save(new RefreshToken(session.getId(), familyId,
                tokens.hashRefreshToken(rawRefreshToken), tokens.refreshExpiry()));
        return tokens.issue(user.getId(), session.getId(), rawRefreshToken);
    }

    @Transactional(noRollbackFor = AuthException.class)
    public TokenResult refresh(String rawRefreshToken) {
        String hash = tokens.hashRefreshToken(rawRefreshToken);
        RefreshToken oldToken = refreshTokens.findByHashForUpdate(hash)
                .orElseThrow(() -> new AuthException(HttpStatus.UNAUTHORIZED,
                        "INVALID_REFRESH_TOKEN", "The session has expired. Please sign in again."));
        UserSession session = sessions.findByIdForUpdate(oldToken.getSessionId())
                .orElseThrow(() -> new AuthException(HttpStatus.UNAUTHORIZED,
                        "INVALID_REFRESH_TOKEN", "The session has expired. Please sign in again."));
        if (oldToken.getConsumedAt() != null) {
            revokeFamily(oldToken.getFamilyId());
            throw new AuthException(HttpStatus.UNAUTHORIZED, "REFRESH_TOKEN_REUSE",
                    "The session has expired. Please sign in again.");
        }
        if (!oldToken.isUsable() || !session.isActive()
                || !hash.equals(session.getRefreshTokenHash())) {
            throw new AuthException(HttpStatus.UNAUTHORIZED, "INVALID_REFRESH_TOKEN",
                    "The session has expired. Please sign in again.");
        }
        oldToken.consume();
        String replacement = tokens.newRefreshToken();
        String replacementHash = tokens.hashRefreshToken(replacement);
        session.rotate(replacementHash, tokens.refreshExpiry());
        refreshTokens.save(new RefreshToken(session.getId(), oldToken.getFamilyId(),
                replacementHash, tokens.refreshExpiry()));
        UserAccount user = users.findById(session.getUserId())
                .orElseThrow(AuthException::invalidCredentials);
        audit.record("TOKEN_REFRESHED", user.getId());
        return tokens.issue(user.getId(), session.getId(), replacement);
    }

    @Transactional(noRollbackFor = AuthException.class)
    public void logout(UUID sessionId) {
        UserSession session = sessions.findByIdForUpdate(sessionId)
                .orElseThrow(() -> new AuthException(HttpStatus.UNAUTHORIZED,
                        "INVALID_SESSION", "The session has expired."));
        session.revoke();
        revokeFamily(session.getFamilyId());
        audit.record("LOGOUT", session.getUserId());
    }

    private void revokeFamily(UUID familyId) {
        refreshTokens.findAllByFamilyId(familyId).forEach(RefreshToken::revoke);
    }
}
