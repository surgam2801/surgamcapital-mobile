package com.surgamcapital.auth.domain.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "user_credentials")
public class UserCredential {
    @Id
    @Column(name = "user_id")
    private UUID userId;
    @Column(name = "password_hash", nullable = false)
    private String passwordHash;
    @Column(name = "password_changed_at", nullable = false)
    private Instant passwordChangedAt;
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected UserCredential() {}

    public UserCredential(UUID userId, String passwordHash) {
        this.userId = userId;
        this.passwordHash = passwordHash;
        this.passwordChangedAt = Instant.now();
        this.updatedAt = this.passwordChangedAt;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public void updatePasswordHash(String newHash) {
        this.passwordHash = newHash;
        this.passwordChangedAt = Instant.now();
        this.updatedAt = this.passwordChangedAt;
    }
}
