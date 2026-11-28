CREATE TABLE onboarding_applications (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL UNIQUE REFERENCES users(id),
    application_reference VARCHAR(24) NOT NULL UNIQUE,
    onboarding_status VARCHAR(32) NOT NULL DEFAULT 'DRAFT',
    kyc_workflow_status VARCHAR(32) NOT NULL DEFAULT 'NOT_STARTED',
    kyc_provider_status VARCHAR(32) NOT NULL DEFAULT 'UNKNOWN',
    pan_verification_status VARCHAR(32) NOT NULL DEFAULT 'NOT_STARTED',
    pan_lookup_hash VARCHAR(64),
    pan_encrypted BYTEA,
    masked_pan VARCHAR(10),
    pan_provider_reference VARCHAR(120),
    kyc_provider_reference VARCHAR(120),
    first_name VARCHAR(80),
    middle_name VARCHAR(80),
    last_name VARCHAR(80),
    date_of_birth DATE,
    gender VARCHAR(24),
    address_line_1 VARCHAR(160),
    address_line_2 VARCHAR(160),
    city VARCHAR(80),
    state VARCHAR(80),
    postal_code VARCHAR(10),
    country_code VARCHAR(2),
    tax_resident_in_india BOOLEAN,
    tax_country_code VARCHAR(2),
    tax_declaration_version VARCHAR(32),
    tax_declared_at TIMESTAMPTZ,
    submitted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT onboarding_status_check CHECK (onboarding_status IN (
        'DRAFT', 'IN_PROGRESS', 'PENDING_VERIFICATION', 'PENDING_MANUAL_REVIEW',
        'ACTION_REQUIRED', 'SUBMITTED', 'APPROVED', 'REJECTED', 'CANCELLED'
    )),
    CONSTRAINT onboarding_kyc_status_check CHECK (kyc_workflow_status IN (
        'NOT_STARTED', 'PENDING', 'VERIFIED', 'ACTION_REQUIRED', 'MANUAL_REVIEW'
    )),
    CONSTRAINT onboarding_kyc_provider_status_check CHECK (kyc_provider_status IN (
        'VALIDATED', 'REGISTERED', 'ON_HOLD', 'REJECTED', 'PENDING', 'UNKNOWN'
    )),
    CONSTRAINT onboarding_pan_status_check CHECK (pan_verification_status IN (
        'NOT_STARTED', 'PENDING', 'VERIFIED', 'FAILED', 'MANUAL_REVIEW_REQUIRED'
    ))
);
CREATE INDEX onboarding_applications_user_idx ON onboarding_applications(user_id);
CREATE INDEX onboarding_applications_status_idx ON onboarding_applications(onboarding_status);
CREATE UNIQUE INDEX onboarding_applications_pan_hash_uq
    ON onboarding_applications(pan_lookup_hash) WHERE pan_lookup_hash IS NOT NULL;

CREATE TABLE onboarding_status_history (
    id UUID PRIMARY KEY,
    application_id UUID NOT NULL REFERENCES onboarding_applications(id),
    from_status VARCHAR(32),
    to_status VARCHAR(32) NOT NULL,
    actor_user_id UUID NOT NULL REFERENCES users(id),
    reason_code VARCHAR(40) NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX onboarding_status_history_application_time_idx
    ON onboarding_status_history(application_id, occurred_at DESC);
