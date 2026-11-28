package com.surgamcapital.onboarding.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface OnboardingStatusHistoryRepository extends JpaRepository<OnboardingStatusHistory, UUID> {}
