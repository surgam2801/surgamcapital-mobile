package com.surgamcapital.auth.domain.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "users", uniqueConstraints = {
        @UniqueConstraint(name = "users_normalized_username_key", columnNames = "normalized_username"),
        @UniqueConstraint(name = "users_normalized_email_key", columnNames = "normalized_email"),
        @UniqueConstraint(name = "users_mobile_e164_key", columnNames = "mobile_e164")
})
public class UserAccount {
    @Id
    private UUID id;
    @Column(nullable = false, length = 40)
    private String username;
    @Column(name = "normalized_username", nullable = false, length = 40)
    private String normalizedUsername;
    @Column(name = "normalized_email", nullable = false, length = 254)
    private String normalizedEmail;
    @Column(name = "mobile_e164", nullable = false, length = 16)
    private String mobileE164;
    @Column(name = "email_verified", nullable = false)
    private boolean emailVerified;
    @Column(name = "mobile_verified", nullable = false)
    private boolean mobileVerified;
    @Column(nullable = false, length = 24)
    private String status;
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected UserAccount() {}

    public UserAccount(String username, String email, String mobileE164) {
        this.id = UUID.randomUUID();
        this.username = username.trim();
        this.normalizedUsername = username.trim().toLowerCase(java.util.Locale.ROOT);
        this.normalizedEmail = email.trim().toLowerCase(java.util.Locale.ROOT);
        this.mobileE164 = mobileE164;
        this.status = "PENDING_VERIFICATION";
        this.createdAt = Instant.now();
        this.updatedAt = this.createdAt;
    }

    public UUID getId() { return id; }
    public String getUsername() { return username; }
    public String getNormalizedUsername() { return normalizedUsername; }
    public String getNormalizedEmail() { return normalizedEmail; }
    public String getMobileE164() { return mobileE164; }
    public String getStatus() { return status; }
    public void activate() {
        this.status = "ACTIVE";
        this.mobileVerified = true;
        this.updatedAt = Instant.now();
    }
}
