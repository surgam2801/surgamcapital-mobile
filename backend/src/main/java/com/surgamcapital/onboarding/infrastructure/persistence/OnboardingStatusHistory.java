package com.surgamcapital.onboarding.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "onboarding_status_history")
public class OnboardingStatusHistory {
    @Id
    private UUID id;
    @Column(name = "application_id", nullable = false)
    private UUID applicationId;
    @Column(name = "from_status", length = 32)
    private String fromStatus;
    @Column(name = "to_status", nullable = false, length = 32)
    private String toStatus;
    @Column(name = "actor_user_id", nullable = false)
    private UUID actorUserId;
    @Column(name = "reason_code", nullable = false, length = 40)
    private String reasonCode;
    @Column(name = "occurred_at", nullable = false)
    private Instant occurredAt;

    protected OnboardingStatusHistory() {}

    public OnboardingStatusHistory(UUID applicationId, String fromStatus,
                                   String toStatus, UUID actorUserId, String reasonCode) {
        this.id = UUID.randomUUID();
        this.applicationId = applicationId;
        this.fromStatus = fromStatus;
        this.toStatus = toStatus;
        this.actorUserId = actorUserId;
        this.reasonCode = reasonCode;
        this.occurredAt = Instant.now();
    }
}
