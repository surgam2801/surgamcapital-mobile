package com.surgamcapital.auth.application.service;

import com.surgamcapital.auth.application.port.OtpDeliveryProvider;
import com.surgamcapital.auth.domain.model.UserAccount;
import com.surgamcapital.auth.infrastructure.persistence.UserRepository;
import com.surgamcapital.shared.exception.AuthException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.script.DefaultRedisScript;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.time.Duration;
import java.util.Base64;
import java.util.Map;
import java.util.UUID;

@Service
public class OtpChallengeService {
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final DefaultRedisScript<Long> VERIFY_SCRIPT = new DefaultRedisScript<>("""
        if redis.call('EXISTS', KEYS[1]) == 0 then return -1 end
        local attempts = redis.call('HINCRBY', KEYS[1], 'attempts', 1)
        if attempts > tonumber(ARGV[2]) then
          redis.call('DEL', KEYS[1])
          return -2
        end
        local expected = redis.call('HGET', KEYS[1], 'hash')
        local candidate = ARGV[1]
        if not expected or #expected ~= #candidate then return 0 end
        local difference = 0
        for index = 1, #expected do
          difference = bit.bor(difference,
            bit.bxor(string.byte(expected, index), string.byte(candidate, index)))
        end
        if difference ~= 0 then return 0 end
        redis.call('DEL', KEYS[1])
        return 1
        """, Long.class);

    private final StringRedisTemplate redis;
    private final UserRepository users;
    private final OtpDeliveryProvider delivery;
    private final byte[] hmacSecret;
    private final Duration ttl;
    private final int maxAttempts;

    public OtpChallengeService(StringRedisTemplate redis, UserRepository users,
                               OtpDeliveryProvider delivery,
                               @Value("${surgam.auth.otp.hmac-secret:}") String secret,
                               @Value("${surgam.auth.otp.ttl:PT5M}") Duration ttl,
                               @Value("${surgam.auth.otp.max-attempts:5}") int maxAttempts) {
        if (secret == null || secret.isBlank()) {
            throw new IllegalStateException("OTP_HMAC_SECRET must be configured.");
        }
        this.redis = redis;
        this.users = users;
        this.delivery = delivery;
        this.hmacSecret = Base64.getDecoder().decode(secret);
        if (hmacSecret.length < 32) {
            throw new IllegalStateException("OTP_HMAC_SECRET must contain at least 256 bits.");
        }
        this.ttl = ttl;
        this.maxAttempts = maxAttempts;
    }

    public Challenge issue(UserAccount user) {
        return issue(user, "LOGIN");
    }

    public Challenge issuePasswordReset(UserAccount user) {
        return issue(user, "PASSWORD_RESET");
    }

    private Challenge issue(UserAccount user, String purpose) {
        String issueRateKey = "auth:otp:issue:" + purpose + ":" + user.getId();
        Long issueCount = redis.opsForValue().increment(issueRateKey);
        if (issueCount != null && issueCount == 1L) {
            redis.expire(issueRateKey, Duration.ofHours(1));
        }
        if (issueCount == null || issueCount > 10L) {
            throw new AuthException(HttpStatus.TOO_MANY_REQUESTS, "TOO_MANY_ATTEMPTS",
                    "Too many OTP requests. Please try again later.");
        }
        String otp = "%06d".formatted(RANDOM.nextInt(1_000_000));
        String challengeId = UUID.randomUUID().toString();
        String hash = hmac(challengeId, user.getId().toString(), purpose, otp);
        String currentKey = "auth:otp:current:" + purpose + ":" + user.getId();
        String previousId = redis.opsForValue().get(currentKey);
        if (previousId != null) redis.delete(key(previousId));
        String key = key(challengeId);
        redis.opsForHash().putAll(key, Map.of(
                "userId", user.getId().toString(),
                "purpose", purpose,
                "hash", hash,
                "attempts", "0"));
        redis.expire(key, ttl);
        redis.opsForValue().set(currentKey, challengeId, ttl);
        delivery.deliver(user.getMobileE164(), otp);
        return new Challenge(challengeId, mask(user.getMobileE164()), (int) ttl.toSeconds());
    }

    public Challenge resend(String previousChallengeId) {
        String oldKey = key(previousChallengeId);
        Object owner = redis.opsForHash().get(oldKey, "userId");
        Object purpose = redis.opsForHash().get(oldKey, "purpose");
        if (owner == null || !"LOGIN".equals(purpose)) {
            throw new AuthException(HttpStatus.UNAUTHORIZED, "OTP_EXPIRED",
                    "The OTP challenge is invalid or expired.");
        }
        String rateKey = "auth:otp:resend:" + owner;
        Long count = redis.opsForValue().increment(rateKey);
        if (count != null && count == 1L) redis.expire(rateKey, Duration.ofHours(1));
        if (count == null || count > 3L) {
            throw new AuthException(HttpStatus.TOO_MANY_REQUESTS, "TOO_MANY_ATTEMPTS",
                    "Too many OTP requests. Please try again later.");
        }
        UserAccount user = users.findById(UUID.fromString(owner.toString()))
                .orElseThrow(AuthException::invalidCredentials);
        Challenge renewed = issue(user);
        redis.delete(oldKey);
        return renewed;
    }

    public UUID verify(String challengeId, String otp) {
        return verify(challengeId, otp, "LOGIN");
    }

    public UUID verifyPasswordReset(String challengeId, String otp) {
        return verify(challengeId, otp, "PASSWORD_RESET");
    }

    private UUID verify(String challengeId, String otp, String requiredPurpose) {
        String key = key(challengeId);
        Object owner = redis.opsForHash().get(key, "userId");
        Object purpose = redis.opsForHash().get(key, "purpose");
        if (owner == null || !requiredPurpose.equals(purpose)) {
            throw new AuthException(HttpStatus.UNAUTHORIZED, "OTP_EXPIRED", "The OTP is invalid or expired.");
        }
        Long result = redis.execute(
                VERIFY_SCRIPT,
                java.util.List.of(key),
                hmac(challengeId, owner.toString(), purpose.toString(), otp),
                Integer.toString(maxAttempts));
        if (result == null || result != 1L) {
            String code = result != null && result == -2L ? "TOO_MANY_ATTEMPTS" : "INVALID_OTP";
            throw new AuthException(HttpStatus.UNAUTHORIZED, code, "The OTP is invalid or expired.");
        }
        return UUID.fromString(owner.toString());
    }

    private String hmac(String challenge, String user, String purpose, String otp) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(hmacSecret, "HmacSHA256"));
            byte[] digest = mac.doFinal((challenge + ":" + user + ":" + purpose + ":" + otp)
                    .getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(digest);
        } catch (java.security.GeneralSecurityException exception) {
            throw new IllegalStateException("HMAC is unavailable.", exception);
        }
    }

    private String key(String challengeId) {
        return "auth:otp:" + challengeId;
    }

    private String mask(String mobile) {
        return "******" + mobile.substring(Math.max(0, mobile.length() - 4));
    }

    public record Challenge(String challengeId, String maskedDestination, int expiresInSeconds) {}
}
