package com.surgamcapital.mutualfund.application.service;

import com.surgamcapital.mutualfund.application.port.MutualFundDataProvider;
import com.surgamcapital.shared.exception.AuthException;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
public class MutualFundSyncService {
    private final ObjectProvider<MutualFundDataProvider> providers;
    private final JdbcTemplate jdbc;

    public MutualFundSyncService(ObjectProvider<MutualFundDataProvider> providers,
                                 JdbcTemplate jdbc) {
        this.providers = providers;
        this.jdbc = jdbc;
    }

    @Transactional
    public SyncResult synchronize() {
        MutualFundDataProvider provider = providers.getIfAvailable();
        if (provider == null) {
            throw new AuthException(HttpStatus.SERVICE_UNAVAILABLE, "DATA_PROVIDER_UNAVAILABLE",
                    "No licensed mutual fund data provider is configured.");
        }
        MutualFundDataProvider.ProviderSnapshot snapshot;
        try {
            snapshot = provider.fetchSnapshot();
        } catch (RuntimeException exception) {
            throw new AuthException(HttpStatus.BAD_GATEWAY, "DATA_PROVIDER_FAILURE",
                    "The mutual fund data provider is temporarily unavailable.");
        }
        if (snapshot == null || snapshot.schemes() == null || snapshot.navs() == null) {
            throw new AuthException(HttpStatus.BAD_GATEWAY, "INVALID_PROVIDER_RESPONSE",
                    "The mutual fund data provider returned invalid data.");
        }
        return synchronize(snapshot, provider.providerCode(),
                provider.providerCode().equals("MOCK_DEMO"), null, null);
    }

    @Transactional
    public SyncResult synchronize(MutualFundDataProvider.ProviderSnapshot snapshot,
                                  String providerCode, boolean mockData,
                                  UUID executionId, String reportType) {
        if (snapshot == null || snapshot.schemes() == null || snapshot.navs() == null
                || providerCode == null || providerCode.isBlank()) {
            throw new AuthException(HttpStatus.BAD_GATEWAY, "INVALID_PROVIDER_RESPONSE",
                    "The mutual fund data provider returned invalid data.");
        }
        UUID providerId = ensureProvider(providerCode, mockData);
        Map<String, UUID> schemeIds = new HashMap<>();
        int schemes = 0;
        int rejected = 0;
        for (var record : snapshot.schemes()) {
            try {
                validate(record);
                UUID amcId = ensureAmc(record.amcCode(), record.amcName());
                UUID categoryId = ensureCategory(record.categoryCode(),
                        record.categoryName(), record.assetClass());
                UUID schemeId = UUID.nameUUIDFromBytes(
                        (providerCode + ":" + record.schemeCode())
                                .getBytes(java.nio.charset.StandardCharsets.UTF_8));
                jdbc.update("""
                        INSERT INTO mutual_fund_scheme (
                          id, scheme_code, isin, isin_div_payout_or_growth,
                          isin_div_reinvestment, amc_id, category_id, scheme_name,
                          sub_category, scheme_type, plan_type, option_type,
                          benchmark_name, inception_date, expense_ratio, aum, exit_load,
                          minimum_lumpsum, minimum_sip, riskometer, investment_objective,
                          scheme_description, fund_manager, scheme_status, provider_id,
                          source_updated_at, updated_at
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
                                  ?, ?, ?, now())
                        ON CONFLICT (scheme_code) DO UPDATE SET
                          isin = EXCLUDED.isin,
                          isin_div_payout_or_growth = EXCLUDED.isin_div_payout_or_growth,
                          isin_div_reinvestment = EXCLUDED.isin_div_reinvestment,
                          amc_id = EXCLUDED.amc_id,
                          category_id = EXCLUDED.category_id,
                          scheme_name = EXCLUDED.scheme_name,
                          sub_category = EXCLUDED.sub_category,
                          scheme_type = EXCLUDED.scheme_type,
                          plan_type = EXCLUDED.plan_type,
                          option_type = EXCLUDED.option_type,
                          benchmark_name = EXCLUDED.benchmark_name,
                          inception_date = EXCLUDED.inception_date,
                          expense_ratio = EXCLUDED.expense_ratio, aum = EXCLUDED.aum,
                          exit_load = EXCLUDED.exit_load,
                          minimum_lumpsum = EXCLUDED.minimum_lumpsum,
                          minimum_sip = EXCLUDED.minimum_sip,
                          riskometer = EXCLUDED.riskometer,
                          investment_objective = EXCLUDED.investment_objective,
                          scheme_description = EXCLUDED.scheme_description,
                          fund_manager = EXCLUDED.fund_manager,
                          scheme_status = EXCLUDED.scheme_status,
                          provider_id = EXCLUDED.provider_id,
                          source_updated_at = EXCLUDED.source_updated_at,
                          updated_at = now()
                        """, schemeId, record.schemeCode(), record.isin(),
                        record.isinDivPayoutOrGrowth(), record.isinDivReinvestment(),
                        amcId, categoryId,
                        record.schemeName(), record.subCategory(), record.schemeType(),
                        record.planType(), record.optionType(), record.benchmarkName(),
                        record.inceptionDate(), record.expenseRatio(), record.aum(),
                        record.exitLoad(), record.minimumLumpsum(), record.minimumSip(),
                        record.riskometer(), record.investmentObjective(),
                        record.schemeDescription(), record.fundManager(), record.schemeStatus(),
                        providerId, OffsetDateTime.now(ZoneOffset.UTC));
                UUID persistedId = jdbc.queryForObject("""
                        SELECT id FROM mutual_fund_scheme WHERE scheme_code = ?
                        """, UUID.class, record.schemeCode());
                schemeIds.put(record.schemeCode(), persistedId);
                schemes++;
            } catch (IllegalArgumentException exception) {
                rejected++;
            }
        }
        int importedNavs = 0;
        for (var nav : snapshot.navs()) {
            UUID schemeId = schemeIds.get(nav.schemeCode());
            if (schemeId == null || nav.date() == null || nav.value() == null
                    || nav.value().signum() <= 0) {
                rejected++;
                continue;
            }
            int inserted = jdbc.update("""
                    INSERT INTO scheme_nav_history (
                      id, scheme_id, nav_date, nav_value, provider_id, source_record_id,
                      source_scheme_code, source_report_type, source_execution_id,
                      imported_at, updated_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, now(), now())
                    ON CONFLICT (scheme_id, nav_date) DO UPDATE SET
                      nav_value = EXCLUDED.nav_value,
                      provider_id = EXCLUDED.provider_id,
                      source_record_id = EXCLUDED.source_record_id,
                      source_scheme_code = EXCLUDED.source_scheme_code,
                      source_report_type = EXCLUDED.source_report_type,
                      source_execution_id = EXCLUDED.source_execution_id,
                      imported_at = now(), updated_at = now()
                    """, UUID.randomUUID(), schemeId, nav.date(), nav.value(),
                    providerId, nav.sourceRecordId(), nav.schemeCode(), reportType,
                    executionId);
            importedNavs += inserted;
        }
        jdbc.update("""
                UPDATE mutual_fund_scheme s SET
                  current_nav = (
                    SELECT n.nav_value FROM scheme_nav_history n
                    WHERE n.scheme_id = s.id ORDER BY n.nav_date DESC LIMIT 1
                  ),
                  latest_nav_date = (
                    SELECT n.nav_date FROM scheme_nav_history n
                    WHERE n.scheme_id = s.id ORDER BY n.nav_date DESC LIMIT 1
                  ),
                  updated_at = now()
                WHERE s.provider_id = ?
                """, providerId);
        return new SyncResult(providerCode, schemes, importedNavs, rejected, mockData);
    }

    private UUID ensureProvider(String code, boolean mock) {
        UUID id = UUID.nameUUIDFromBytes(("provider:" + code)
                .getBytes(java.nio.charset.StandardCharsets.UTF_8));
        jdbc.update("""
                INSERT INTO data_provider_master (id, provider_code, name, is_mock)
                VALUES (?, ?, ?, ?) ON CONFLICT (provider_code) DO UPDATE SET
                  name = EXCLUDED.name, is_mock = EXCLUDED.is_mock
                """, id, code, code.equals("MOCK_DEMO")
                ? "Mock demo data (not market data)" : code, mock);
        return id;
    }

    private UUID ensureAmc(String code, String name) {
        UUID id = UUID.nameUUIDFromBytes(("amc:" + code)
                .getBytes(java.nio.charset.StandardCharsets.UTF_8));
        jdbc.update("""
                INSERT INTO amc_master (id, amc_code, name)
                VALUES (?, ?, ?) ON CONFLICT (amc_code) DO UPDATE SET
                  name = EXCLUDED.name, updated_at = now()
                """, id, code, name);
        return id;
    }

    private UUID ensureCategory(String code, String name, String assetClass) {
        UUID id = UUID.nameUUIDFromBytes(("category:" + code)
                .getBytes(java.nio.charset.StandardCharsets.UTF_8));
        jdbc.update("""
                INSERT INTO scheme_category_master (id, category_code, name, asset_class)
                VALUES (?, ?, ?, ?) ON CONFLICT (category_code) DO UPDATE SET
                  name = EXCLUDED.name, asset_class = EXCLUDED.asset_class
                """, id, code, name, assetClass);
        return id;
    }

    private void validate(MutualFundDataProvider.SchemeRecord record) {
        if (record == null || record.schemeCode() == null || record.schemeCode().isBlank()
                || record.schemeName() == null || record.schemeName().isBlank()
                || record.amcCode() == null || record.amcName() == null
                || record.categoryCode() == null || record.categoryName() == null
                || record.assetClass() == null
                || !java.util.Set.of("REGULAR", "DIRECT", "UNKNOWN")
                        .contains(record.planType())
                || !java.util.Set.of("GROWTH", "IDCW", "UNKNOWN")
                        .contains(record.optionType())
                || !java.util.Set.of("ACTIVE", "INACTIVE", "MERGED", "CLOSED",
                        "SUSPENDED", "UNKNOWN").contains(record.schemeStatus())
                || negative(record.expenseRatio()) || negative(record.aum())
                || negative(record.minimumLumpsum()) || negative(record.minimumSip())) {
            throw new IllegalArgumentException("Invalid mutual fund scheme record.");
        }
    }

    private boolean negative(BigDecimal value) {
        return value != null && value.signum() < 0;
    }

    public record SyncResult(String provider, int schemesProcessed, int navsImported,
                             int recordsRejected, boolean mockData) {}
}
