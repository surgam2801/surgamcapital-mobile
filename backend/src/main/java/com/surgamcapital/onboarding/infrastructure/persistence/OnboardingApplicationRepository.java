package com.surgamcapital.onboarding.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface OnboardingApplicationRepository extends JpaRepository<OnboardingApplication, UUID> {
    Optional<OnboardingApplication> findByUserId(UUID userId);
    Optional<OnboardingApplication> findByIdAndUserId(UUID id, UUID userId);
    boolean existsByPanLookupHashAndIdNot(String panLookupHash, UUID id);
}
