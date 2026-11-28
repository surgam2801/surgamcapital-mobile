package com.surgamcapital.onboarding.application.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.util.Base64;

@Component
public class PanLookupHasher {
    private final byte[] key;

    public PanLookupHasher(@Value("${surgam.onboarding.pan-hmac-secret}") String encodedKey) {
        try {
            key = Base64.getDecoder().decode(encodedKey);
        } catch (IllegalArgumentException exception) {
            throw new IllegalStateException("PAN_HMAC_SECRET must be valid Base64.", exception);
        }
        if (key.length < 32) {
            throw new IllegalStateException("PAN_HMAC_SECRET must contain at least 256 bits.");
        }
    }

    public String hash(String normalizedPan) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(key, "HmacSHA256"));
            return java.util.HexFormat.of().formatHex(
                    mac.doFinal(normalizedPan.getBytes(java.nio.charset.StandardCharsets.US_ASCII)));
        } catch (java.security.GeneralSecurityException exception) {
            throw new IllegalStateException("PAN lookup hashing is unavailable.", exception);
        }
    }

    public static String mask(String normalizedPan) {
        return "*****" + normalizedPan.substring(5);
    }
}
