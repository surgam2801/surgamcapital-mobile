package com.surgamcapital.onboarding.domain;

import java.util.Map;
import java.util.Set;

public final class OnboardingStatuses {
    private static final Map<String, Set<String>> TRANSITIONS = Map.of(
            "DRAFT", Set.of("IN_PROGRESS", "CANCELLED"),
            "IN_PROGRESS", Set.of("PENDING_VERIFICATION", "CANCELLED"),
            "ACTION_REQUIRED", Set.of("IN_PROGRESS", "PENDING_VERIFICATION", "CANCELLED"),
            "PENDING_VERIFICATION", Set.of("ACTION_REQUIRED", "PENDING_MANUAL_REVIEW",
                    "APPROVED", "REJECTED"),
            "PENDING_MANUAL_REVIEW", Set.of("ACTION_REQUIRED", "APPROVED", "REJECTED"),
            "SUBMITTED", Set.of("PENDING_VERIFICATION", "ACTION_REQUIRED"),
            "REJECTED", Set.of("IN_PROGRESS", "CANCELLED"),
            "APPROVED", Set.of(),
            "CANCELLED", Set.of());

    private OnboardingStatuses() {}

    public static boolean canTransition(String from, String to) {
        return TRANSITIONS.getOrDefault(from, Set.of()).contains(to);
    }

    public static void requireTransition(String from, String to) {
        if (!canTransition(from, to)) {
            throw new IllegalStateException("Invalid onboarding status transition.");
        }
    }
}
