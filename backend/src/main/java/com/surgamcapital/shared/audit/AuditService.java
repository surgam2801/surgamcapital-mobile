package com.surgamcapital.shared.audit;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class AuditService {
    private final JdbcTemplate jdbc;

    public AuditService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Transactional
    public void record(String eventType, UUID userId) {
        jdbc.update("""
                INSERT INTO audit_events (id, event_type, user_id, correlation_id)
                VALUES (?, ?, ?, ?)
                """, UUID.randomUUID(), eventType, userId, null);
    }
}
