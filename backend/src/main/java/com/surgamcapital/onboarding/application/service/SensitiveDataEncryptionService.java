package com.surgamcapital.onboarding.application.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.SecureRandom;
import java.util.Arrays;
import java.util.Base64;

@Component
public class SensitiveDataEncryptionService {
    private static final int NONCE_BYTES = 12;
    private static final int TAG_BITS = 128;
    private static final SecureRandom RANDOM = new SecureRandom();
    private final byte[] key;

    public SensitiveDataEncryptionService(
            @Value("${surgam.onboarding.encryption-key}") String encodedKey) {
        try {
            key = Base64.getDecoder().decode(encodedKey);
        } catch (IllegalArgumentException exception) {
            throw new IllegalStateException("PAN_ENCRYPTION_KEY must be valid Base64.", exception);
        }
        if (key.length != 32) {
            throw new IllegalStateException("PAN_ENCRYPTION_KEY must contain exactly 256 bits.");
        }
    }

    public byte[] encrypt(String value) {
        byte[] nonce = new byte[NONCE_BYTES];
        RANDOM.nextBytes(nonce);
        try {
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, new SecretKeySpec(key, "AES"),
                    new GCMParameterSpec(TAG_BITS, nonce));
            byte[] encrypted = cipher.doFinal(value.getBytes(StandardCharsets.US_ASCII));
            byte[] result = Arrays.copyOf(nonce, nonce.length + encrypted.length);
            System.arraycopy(encrypted, 0, result, nonce.length, encrypted.length);
            return result;
        } catch (GeneralSecurityException exception) {
            throw new IllegalStateException("Sensitive data encryption failed.", exception);
        }
    }

    public String decrypt(byte[] encryptedValue) {
        if (encryptedValue == null || encryptedValue.length <= NONCE_BYTES) {
            throw new IllegalStateException("Encrypted PAN data is unavailable.");
        }
        byte[] nonce = Arrays.copyOfRange(encryptedValue, 0, NONCE_BYTES);
        byte[] ciphertext = Arrays.copyOfRange(encryptedValue, NONCE_BYTES, encryptedValue.length);
        try {
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, new SecretKeySpec(key, "AES"),
                    new GCMParameterSpec(TAG_BITS, nonce));
            return new String(cipher.doFinal(ciphertext), StandardCharsets.US_ASCII);
        } catch (GeneralSecurityException exception) {
            throw new IllegalStateException("Sensitive data decryption failed.", exception);
        }
    }
}
