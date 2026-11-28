CREATE TABLE users (
    id UUID PRIMARY KEY,
    username VARCHAR(40) NOT NULL,
    normalized_username VARCHAR(40) NOT NULL UNIQUE,
    normalized_email VARCHAR(254) NOT NULL UNIQUE,
    mobile_e164 VARCHAR(16) NOT NULL UNIQUE,
    email_verified BOOLEAN NOT NULL DEFAULT false,
    mobile_verified BOOLEAN NOT NULL DEFAULT false,
    status VARCHAR(24) NOT NULL DEFAULT 'PENDING_VERIFICATION',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT users_status_check CHECK (status IN ('PENDING_VERIFICATION', 'ACTIVE', 'LOCKED', 'DISABLED'))
);

CREATE TABLE user_credentials (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    password_hash VARCHAR(255) NOT NULL,
    password_changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE user_sessions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id),
    family_id UUID NOT NULL,
    refresh_token_hash CHAR(64) NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX user_sessions_user_id_idx ON user_sessions(user_id);
CREATE INDEX user_sessions_family_id_idx ON user_sessions(family_id);
CREATE INDEX user_sessions_expiry_idx ON user_sessions(expires_at);

CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY,
    session_id UUID NOT NULL REFERENCES user_sessions(id),
    family_id UUID NOT NULL,
    token_hash CHAR(64) NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    consumed_at TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX refresh_tokens_session_idx ON refresh_tokens(session_id);
CREATE INDEX refresh_tokens_family_idx ON refresh_tokens(family_id);

CREATE TABLE audit_events (
    id UUID PRIMARY KEY,
    event_type VARCHAR(80) NOT NULL,
    user_id UUID REFERENCES users(id),
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    correlation_id VARCHAR(64)
);
CREATE INDEX audit_events_user_time_idx ON audit_events(user_id, occurred_at DESC);
