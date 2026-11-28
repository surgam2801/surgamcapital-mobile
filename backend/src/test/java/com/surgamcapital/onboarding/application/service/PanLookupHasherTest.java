package com.surgamcapital.onboarding.application.service;

import org.junit.jupiter.api.Test;

import java.util.Base64;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;

class PanLookupHasherTest {
    @Test
    void producesDeterministicKeyedLookupAndMaskedValue() {
        String secret = Base64.getEncoder().encodeToString(new byte[32]);
        PanLookupHasher hasher = new PanLookupHasher(secret);
        String normalized = "ABCDE1234F";

        assertEquals(hasher.hash(normalized), hasher.hash(normalized));
        assertNotEquals(normalized, hasher.hash(normalized));
        assertEquals("*****1234F", PanLookupHasher.mask(normalized));
    }
}
