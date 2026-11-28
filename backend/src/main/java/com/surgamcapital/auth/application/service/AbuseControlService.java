package com.surgamcapital.auth.application.service;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import com.surgamcapital.shared.exception.AuthException;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.util.HexFormat;

@Service
public class AbuseControlService {
    private static final long MAX_FAILURES = 10;
    private static final Duration WINDOW = Duration.ofMinutes(15);
    private final StringRedisTemplate redis;

    public AbuseControlService(StringRedisTemplate redis) {
        this.redis = redis;
    }

    public void failedLogin(String normalizedUsername) {
        String key = "auth:login:fail:" + hash(normalizedUsername);
        Long count = redis.opsForValue().increment(key);
        if (count != null && count == 1L) redis.expire(key, WINDOW);
        if (count == null || count > MAX_FAILURES) {
            throw new AuthException(HttpStatus.TOO_MANY_REQUESTS, "TOO_MANY_ATTEMPTS",
                    "Too many sign-in attempts. Please try again later.");
        }
    }

    public void successfulLogin(String normalizedUsername) {
        redis.delete("auth:login:fail:" + hash(normalizedUsername));
    }

    public void forgotPasswordRequest(String identifier) {
        String key = "auth:password:reset:" + hash(identifier.trim().toLowerCase(java.util.Locale.ROOT));
        Long count = redis.opsForValue().increment(key);
        if (count != null && count == 1L) redis.expire(key, Duration.ofHours(1));
        if (count == null || count > 5L) {
            throw new AuthException(HttpStatus.TOO_MANY_REQUESTS, "TOO_MANY_ATTEMPTS",
                    "Too many requests. Please try again later.");
        }
    }

    private String hash(String input) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(input.getBytes(StandardCharsets.UTF_8)));
        } catch (java.security.NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable.", exception);
        }
    }
}
