package com.surgamcapital.onboarding.domain;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class OnboardingStatusesTest {
    @Test
    void allowsOnlyDefinedInvestorAndVerificationTransitions() {
        assertTrue(OnboardingStatuses.canTransition("DRAFT", "IN_PROGRESS"));
        assertTrue(OnboardingStatuses.canTransition("IN_PROGRESS", "PENDING_VERIFICATION"));
        assertFalse(OnboardingStatuses.canTransition("DRAFT", "APPROVED"));
        assertFalse(OnboardingStatuses.canTransition("APPROVED", "IN_PROGRESS"));
    }
}
