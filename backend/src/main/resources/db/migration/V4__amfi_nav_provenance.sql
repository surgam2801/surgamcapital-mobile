ALTER TABLE mutual_fund_scheme
    DROP CONSTRAINT mutual_fund_plan_check;
ALTER TABLE mutual_fund_scheme
    ADD CONSTRAINT mutual_fund_plan_check
        CHECK (plan_type IN ('REGULAR', 'DIRECT', 'UNKNOWN'));

CREATE TABLE amfi_sync_execution (
    id UUID PRIMARY KEY,
    report_type VARCHAR(40) NOT NULL,
    requested_from DATE,
    requested_to DATE,
    status VARCHAR(16) NOT NULL,
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ,
    records_received INTEGER NOT NULL DEFAULT 0,
    records_imported INTEGER NOT NULL DEFAULT 0,
    records_rejected INTEGER NOT NULL DEFAULT 0,
    error_code VARCHAR(80),
    CONSTRAINT amfi_sync_execution_status_check
        CHECK (status IN ('RUNNING', 'SUCCEEDED', 'PARTIAL', 'FAILED'))
);
CREATE INDEX amfi_sync_execution_started_idx
    ON amfi_sync_execution(started_at DESC);

CREATE TABLE amfi_source_record_audit (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    execution_id UUID NOT NULL REFERENCES amfi_sync_execution(id),
    line_number INTEGER NOT NULL,
    raw_record TEXT NOT NULL,
    source_scheme_code VARCHAR(80),
    nav_date DATE,
    nav_value NUMERIC(18, 6),
    accepted BOOLEAN NOT NULL,
    rejection_reason VARCHAR(500),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (execution_id, line_number)
);
CREATE INDEX amfi_source_record_scheme_idx
    ON amfi_source_record_audit(source_scheme_code, nav_date);

ALTER TABLE scheme_nav_history
    ADD COLUMN source_scheme_code VARCHAR(80),
    ADD COLUMN source_report_type VARCHAR(40),
    ADD COLUMN source_execution_id UUID REFERENCES amfi_sync_execution(id);
ALTER TABLE mutual_fund_scheme
    ADD COLUMN isin_div_payout_or_growth VARCHAR(20),
    ADD COLUMN isin_div_reinvestment VARCHAR(20);
CREATE INDEX scheme_nav_history_source_execution_idx
    ON scheme_nav_history(source_execution_id)
    WHERE source_execution_id IS NOT NULL;
