package com.surgamcapital.auth.infrastructure.persistence;

import com.surgamcapital.auth.domain.model.UserCredential;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface UserCredentialRepository extends JpaRepository<UserCredential, UUID> {}
