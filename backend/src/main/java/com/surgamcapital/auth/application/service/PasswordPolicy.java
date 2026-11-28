package com.surgamcapital.auth.application.service;

import com.surgamcapital.shared.exception.AuthException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Locale;

@Component
public class PasswordPolicy {
    private static final List<String> COMMON_FRAGMENTS =
            List.of("password", "qwerty", "letmein", "welcome", "123456");

    public void validate(String password) {
        if (password.length() < 12 || password.length() > 128) {
            throw new AuthException(HttpStatus.BAD_REQUEST, "WEAK_PASSWORD",
                    "Password must be between 12 and 128 characters.");
        }
        String normalized = password.toLowerCase(Locale.ROOT);
        boolean repeatedCharacter = password.chars().distinct().count() < 4;
        if (repeatedCharacter || COMMON_FRAGMENTS.stream().anyMatch(normalized::contains)) {
            throw new AuthException(HttpStatus.BAD_REQUEST, "WEAK_PASSWORD",
                    "Choose a less common password with more character variety.");
        }
    }
}
