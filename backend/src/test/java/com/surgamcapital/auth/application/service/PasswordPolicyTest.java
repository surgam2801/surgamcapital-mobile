package com.surgamcapital.auth.application.service;

import com.surgamcapital.shared.exception.AuthException;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;

class PasswordPolicyTest {
    private final PasswordPolicy policy = new PasswordPolicy();

    @Test
    void acceptsLongPasswordWithoutCommonFragments() {
        assertDoesNotThrow(() -> policy.validate("Cedar!River_94"));
    }

    @Test
    void rejectsCommonPasswordFragments() {
        assertThrows(AuthException.class, () -> policy.validate("Password123!Long"));
    }

    @Test
    void rejectsLowCharacterVariety() {
        assertThrows(AuthException.class, () -> policy.validate("aaaaaaaaaaaaa"));
    }
}
