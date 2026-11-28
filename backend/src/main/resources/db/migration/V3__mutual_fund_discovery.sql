CREATE TABLE amc_master (
    id UUID PRIMARY KEY,
    amc_code VARCHAR(40) NOT NULL UNIQUE,
    name VARCHAR(160) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE scheme_category_master (
    id UUID PRIMARY KEY,
    category_code VARCHAR(60) NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL,
    asset_class VARCHAR(40) NOT NULL,
    source_label VARCHAR(120),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE data_provider_master (
    id UUID PRIMARY KEY,
    provider_code VARCHAR(60) NOT NULL UNIQUE,
    name VARCHAR(160) NOT NULL,
    is_mock BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE mutual_fund_scheme (
    id UUID PRIMARY KEY,
    scheme_code VARCHAR(80) NOT NULL UNIQUE,
    isin VARCHAR(20),
    amc_id UUID NOT NULL REFERENCES amc_master(id),
    category_id UUID NOT NULL REFERENCES scheme_category_master(id),
    scheme_name VARCHAR(240) NOT NULL,
    sub_category VARCHAR(120),
    scheme_type VARCHAR(40),
    plan_type VARCHAR(20) NOT NULL,
    option_type VARCHAR(20) NOT NULL,
    benchmark_name VARCHAR(180),
    inception_date DATE,
    current_nav NUMERIC(18, 6),
    latest_nav_date DATE,
    expense_ratio NUMERIC(8, 5),
    aum NUMERIC(22, 2),
    exit_load TEXT,
    minimum_lumpsum NUMERIC(18, 2),
    minimum_sip NUMERIC(18, 2),
    riskometer VARCHAR(40),
    investment_objective TEXT,
    scheme_description TEXT,
    fund_manager VARCHAR(240),
    scheme_status VARCHAR(20) NOT NULL DEFAULT 'UNKNOWN',
    provider_id UUID NOT NULL REFERENCES data_provider_master(id),
    source_updated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT mutual_fund_plan_check CHECK (plan_type IN ('REGULAR')),
    CONSTRAINT mutual_fund_option_check CHECK (option_type IN ('GROWTH', 'IDCW', 'UNKNOWN')),
    CONSTRAINT mutual_fund_status_check CHECK (scheme_status IN (
        'ACTIVE', 'INACTIVE', 'MERGED', 'CLOSED', 'SUSPENDED', 'UNKNOWN'
    )),
    CONSTRAINT mutual_fund_expense_nonnegative CHECK (expense_ratio IS NULL OR expense_ratio >= 0),
    CONSTRAINT mutual_fund_aum_nonnegative CHECK (aum IS NULL OR aum >= 0),
    CONSTRAINT mutual_fund_nav_positive CHECK (current_nav IS NULL OR current_nav > 0),
    CONSTRAINT mutual_fund_lumpsum_nonnegative CHECK (
        minimum_lumpsum IS NULL OR minimum_lumpsum >= 0
    ),
    CONSTRAINT mutual_fund_sip_nonnegative CHECK (minimum_sip IS NULL OR minimum_sip >= 0)
);
CREATE INDEX mutual_fund_scheme_search_idx ON mutual_fund_scheme
    USING GIN (to_tsvector('simple', scheme_name || ' ' || scheme_code || ' ' || coalesce(isin, '')));
CREATE INDEX mutual_fund_scheme_filter_idx
    ON mutual_fund_scheme(category_id, amc_id, riskometer, scheme_status);
CREATE INDEX mutual_fund_scheme_option_idx ON mutual_fund_scheme(plan_type, option_type);

CREATE TABLE scheme_benchmark (
    id UUID PRIMARY KEY,
    scheme_id UUID NOT NULL REFERENCES mutual_fund_scheme(id) ON DELETE CASCADE,
    benchmark_name VARCHAR(180) NOT NULL,
    provider_id UUID NOT NULL REFERENCES data_provider_master(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (scheme_id, benchmark_name)
);

CREATE TABLE scheme_nav_history (
    id UUID PRIMARY KEY,
    scheme_id UUID NOT NULL REFERENCES mutual_fund_scheme(id),
    nav_date DATE NOT NULL,
    nav_value NUMERIC(18, 6) NOT NULL,
    provider_id UUID NOT NULL REFERENCES data_provider_master(id),
    source_record_id VARCHAR(120),
    imported_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT scheme_nav_positive CHECK (nav_value > 0),
    UNIQUE (scheme_id, nav_date)
);
CREATE INDEX scheme_nav_history_date_idx ON scheme_nav_history(scheme_id, nav_date DESC);

CREATE TABLE scheme_documents (
    id UUID PRIMARY KEY,
    scheme_id UUID NOT NULL REFERENCES mutual_fund_scheme(id) ON DELETE CASCADE,
    document_type VARCHAR(40) NOT NULL,
    title VARCHAR(240) NOT NULL,
    document_url TEXT NOT NULL,
    provider_id UUID NOT NULL REFERENCES data_provider_master(id),
    source_updated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (scheme_id, document_type, document_url)
);

CREATE TABLE scheme_performance_snapshot (
    id UUID PRIMARY KEY,
    scheme_id UUID NOT NULL REFERENCES mutual_fund_scheme(id) ON DELETE CASCADE,
    period_code VARCHAR(20) NOT NULL,
    return_value NUMERIC(12, 6),
    methodology VARCHAR(40) NOT NULL,
    start_date DATE,
    end_date DATE,
    as_of_date DATE,
    data_complete BOOLEAN NOT NULL,
    distributions_included BOOLEAN NOT NULL DEFAULT false,
    provider_id UUID NOT NULL REFERENCES data_provider_master(id),
    calculated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (scheme_id, period_code, as_of_date)
);

CREATE TABLE investor_scheme_watchlist (
    id UUID PRIMARY KEY,
    investor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    scheme_id UUID NOT NULL REFERENCES mutual_fund_scheme(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (investor_id, scheme_id)
);
CREATE INDEX investor_scheme_watchlist_investor_idx
    ON investor_scheme_watchlist(investor_id, created_at DESC);

CREATE TABLE data_sync_job (
    id UUID PRIMARY KEY,
    job_code VARCHAR(60) NOT NULL UNIQUE,
    provider_id UUID NOT NULL REFERENCES data_provider_master(id),
    enabled BOOLEAN NOT NULL DEFAULT false,
    schedule_expression VARCHAR(120),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE data_sync_execution (
    id UUID PRIMARY KEY,
    job_id UUID NOT NULL REFERENCES data_sync_job(id),
    status VARCHAR(24) NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ,
    records_imported INTEGER NOT NULL DEFAULT 0,
    records_updated INTEGER NOT NULL DEFAULT 0,
    records_rejected INTEGER NOT NULL DEFAULT 0,
    error_code VARCHAR(80),
    CONSTRAINT data_sync_execution_status_check CHECK (
        status IN ('RUNNING', 'SUCCEEDED', 'FAILED', 'PARTIAL')
    )
);

CREATE TABLE data_quality_issue (
    id UUID PRIMARY KEY,
    provider_id UUID NOT NULL REFERENCES data_provider_master(id),
    scheme_id UUID REFERENCES mutual_fund_scheme(id),
    issue_code VARCHAR(80) NOT NULL,
    description VARCHAR(500) NOT NULL,
    detected_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at TIMESTAMPTZ
);
CREATE INDEX data_quality_issue_open_idx ON data_quality_issue(detected_at DESC)
    WHERE resolved_at IS NULL;
