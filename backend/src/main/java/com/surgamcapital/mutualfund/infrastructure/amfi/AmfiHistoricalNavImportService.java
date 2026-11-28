package com.surgamcapital.mutualfund.infrastructure.amfi;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class AmfiHistoricalNavImportService {
    private static final String PROVIDER_CODE = "AMFI";
    private final JdbcTemplate jdbc;

    public AmfiHistoricalNavImportService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Transactional
    public ImportResult importHistorical(UUID executionId, String reportType,
                                         List<AmfiNavRecord> records) {
        UUID providerId = jdbc.query("""
                SELECT id FROM data_provider_master WHERE provider_code = ?
                """, result -> result.next()
                ? result.getObject("id", UUID.class) : null, PROVIDER_CODE);
        if (providerId == null) {
            throw new IllegalStateException(
                    "AMFI provider record is unavailable for historical backfill.");
        }

        int imported = 0;
        List<AmfiRejectedRecord> rejected = new ArrayList<>();
        Map<String, UUID> schemeIds = new HashMap<>();
        for (AmfiNavRecord row : records) {
            UUID schemeId = schemeIds.get(row.schemeCode());
            if (schemeId == null) {
                schemeId = jdbc.query("""
                        SELECT id FROM mutual_fund_scheme WHERE scheme_code = ?
                        """, result -> result.next()
                        ? result.getObject("id", UUID.class) : null, row.schemeCode());
                if (schemeId != null) schemeIds.put(row.schemeCode(), schemeId);
            }
            if (schemeId == null) {
                rejected.add(new AmfiRejectedRecord(row.lineNumber(), row.rawRecord(),
                        "Scheme code has not been imported from the official AMFI scheme/NAV master."));
                continue;
            }
            imported += jdbc.update("""
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
                    """, UUID.randomUUID(), schemeId, row.navDate(), row.nav(),
                    providerId, "AMFI:DownloadNAVHistoryReport_Po.aspx:"
                            + row.lineNumber(), row.schemeCode(), reportType, executionId);
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
        return new ImportResult(imported, List.copyOf(rejected));
    }

    public record ImportResult(int recordsImported,
                               List<AmfiRejectedRecord> rejectedRecords) {}
}
