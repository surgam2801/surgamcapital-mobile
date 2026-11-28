package com.surgamcapital.onboarding.application.service;

import org.junit.jupiter.api.Test;

import java.util.Base64;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;

class SensitiveDataEncryptionServiceTest {
    private final String key = Base64.getEncoder().encodeToString(new byte[32]);
    private final SensitiveDataEncryptionService encryption =
            new SensitiveDataEncryptionService(key);

    @Test
    void encryptsAndDecryptsSensitiveValuesWithFreshNonces() {
        byte[] first = encryption.encrypt("ABCDE1234F");
        byte[] second = encryption.encrypt("ABCDE1234F");

        assertArrayEquals("ABCDE1234F".getBytes(java.nio.charset.StandardCharsets.US_ASCII),
                encryption.decrypt(first).getBytes(java.nio.charset.StandardCharsets.US_ASCII));
        assertFalse(java.util.Arrays.equals(first, second));
    }

    @Test
    void rejectsTamperedCiphertext() {
        byte[] encrypted = encryption.encrypt("ABCDE1234F");
        encrypted[encrypted.length - 1] ^= 1;

        assertThrows(IllegalStateException.class, () -> encryption.decrypt(encrypted));
    }
}
