package com.surgamcapital.auth.application.service;

import com.surgamcapital.auth.presentation.dto.AuthDtos.TokenResult;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.UUID;

@Service
public class TokenService {
    private static final SecureRandom RANDOM = new SecureRandom();
    private final JwtEncoder encoder;
    private final String issuer;
    private final String audience;
    private final Duration accessTtl;
    private final Duration refreshTtl;

    public TokenService(JwtEncoder encoder,
                        @Value("${surgam.auth.jwt.issuer}") String issuer,
                        @Value("${surgam.auth.jwt.audience}") String audience,
                        @Value("${surgam.auth.jwt.access-ttl:PT15M}") Duration accessTtl,
                        @Value("${surgam.auth.jwt.refresh-ttl:P14D}") Duration refreshTtl) {
        this.encoder = encoder;
        this.issuer = issuer;
        this.audience = audience;
        this.accessTtl = accessTtl;
        this.refreshTtl = refreshTtl;
    }

    public TokenResult issue(UUID userId, UUID sessionId, String refreshToken) {
        Instant now = Instant.now();
        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer(issuer)
                .audience(java.util.List.of(audience))
                .subject(userId.toString())
                .issuedAt(now)
                .expiresAt(now.plus(accessTtl))
                .id(UUID.randomUUID().toString())
                .claim("sid", sessionId.toString())
                .build();
        String accessToken = encoder.encode(JwtEncoderParameters.from(
                JwsHeader.with(MacAlgorithm.HS256).build(), claims)).getTokenValue();
        return new TokenResult(accessToken, refreshToken, "Bearer", accessTtl.toSeconds());
    }

    public String newRefreshToken() {
        byte[] bytes = new byte[48];
        RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    public String hashRefreshToken(String token) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(token.getBytes(StandardCharsets.UTF_8));
            return java.util.HexFormat.of().formatHex(digest);
        } catch (java.security.NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable.", exception);
        }
    }

    public Instant refreshExpiry() {
        return Instant.now().plus(refreshTtl);
    }
}
