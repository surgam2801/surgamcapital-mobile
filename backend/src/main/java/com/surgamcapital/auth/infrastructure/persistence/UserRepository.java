package com.surgamcapital.auth.infrastructure.persistence;

import com.surgamcapital.auth.domain.model.UserAccount;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<UserAccount, UUID> {
    Optional<UserAccount> findByNormalizedUsername(String username);
    Optional<UserAccount> findByNormalizedEmail(String email);
    Optional<UserAccount> findByMobileE164(String mobileE164);
    boolean existsByNormalizedUsername(String username);
    boolean existsByNormalizedEmail(String email);
    boolean existsByMobileE164(String mobileE164);
}
