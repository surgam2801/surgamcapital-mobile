package com.surgamcapital.mutualfund.infrastructure.amfi;

import com.surgamcapital.mutualfund.application.service.MutualFundSyncService;
import com.surgamcapital.shared.exception.AuthException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Service
public class AmfiDataSyncService {
    private static final Logger LOGGER =
            LoggerFactory.getLogger(AmfiDataSyncService.class);
    private static final String PROVIDER_CODE = "AMFI";

    private final AmfiNavClient latestClient;
    private final AmfiHistoricalNavClient historicalClient;
    private final AmfiNavParser latestParser;
    private final AmfiHistoricalNavParser historicalParser;
    private final AmfiHistoricalNavImportService historicalImport;
    private final AmfiSchemeMapper mapper;
    private final MutualFundSyncService schemeSync;
    private final JdbcTemplate jdbc;
    private final int chunkDays;

    public AmfiDataSyncService(
            AmfiNavClient latestClient,
            AmfiHistoricalNavClient historicalClient,
            AmfiNavParser latestParser,
            AmfiHistoricalNavParser historicalParser,
            AmfiHistoricalNavImportService historicalImport,
            AmfiSchemeMapper mapper,
            MutualFundSyncService schemeSync,
            JdbcTemplate jdbc,
            @Value("${surgam.mutual-fund.amfi.backfill-chunk-days:7}")
            int chunkDays) {
        if (chunkDays < 1 || chunkDays > 31) {
            throw new IllegalArgumentException(
                    "AMFI backfill chunks must be between 1 and 31 days.");
        }
        this.latestClient = latestClient;
        this.historicalClient = historicalClient;
        this.latestParser = latestParser;
        this.historicalParser = historicalParser;
        this.historicalImport = historicalImport;
        this.mapper = mapper;
        this.schemeSync = schemeSync;
        this.jdbc = jdbc;
        this.chunkDays = chunkDays;
    }

    @CacheEvict(cacheNames = {
            "mutual-fund-schemes", "mutual-fund-scheme-details",
            "mutual-fund-categories", "mutual-fund-amcs",
            "mutual-fund-nav-history", "mutual-fund-performance"
    }, allEntries = true)
    public SyncSummary synchronizeLatest() {
        UUID executionId = startExecution("LATEST_NAV", null, null);
        int received = 0;
        int rejected = 0;
        int imported = 0;
        try {
            String body = latestClient.fetchLatestReport();
            AmfiParseResult parsed = latestParser.parse(body);
            received = parsed.records().size();
            rejected = parsed.rejectedRecords().size();
            if (parsed.records().isEmpty()) {
                audit(executionId, parsed);
                throw new IllegalStateException(
                        "AMFI latest NAV report contained no valid NAV records.");
            }
            audit(executionId, parsed);
            var result = schemeSync.synchronize(
                    mapper.toLatestSnapshot(parsed.records()), PROVIDER_CODE,
                    false, executionId, "LATEST_NAV");
            imported = result.navsImported();
            rejected += result.recordsRejected();
            String status = rejected == 0 ? "SUCCEEDED" : "PARTIAL";
            finishExecution(executionId, status, parsed.records().size(),
                    imported, rejected, null);
            LOGGER.info("AMFI latest NAV sync completed: execution={}, imported={}, rejected={}",
                    executionId, imported, rejected);
            return new SyncSummary(executionId, "LATEST_NAV", status,
                    parsed.records().size(), imported, rejected);
        } catch (RuntimeException exception) {
            failExecution(executionId, exception, received, imported, rejected);
            throw new AuthException(HttpStatus.BAD_GATEWAY, "AMFI_SYNC_FAILED",
                    "AMFI latest NAV synchronization failed; the last imported NAV data remains available.");
        }
    }

    @CacheEvict(cacheNames = {
            "mutual-fund-schemes", "mutual-fund-scheme-details",
            "mutual-fund-categories", "mutual-fund-amcs",
            "mutual-fund-nav-history", "mutual-fund-performance"
    }, allEntries = true)
    public BackfillSummary backfill(LocalDate from, LocalDate to) {
        if (from == null || to == null || from.isAfter(to)
                || to.isAfter(LocalDate.now(ZoneOffset.UTC))) {
            throw new AuthException(HttpStatus.BAD_REQUEST, "INVALID_AMFI_DATE_RANGE",
                    "AMFI backfill dates must be valid and cannot include future dates.");
        }
        List<SyncSummary> executions = new ArrayList<>();
        LocalDate chunkFrom = from;
        while (!chunkFrom.isAfter(to)) {
            LocalDate chunkTo = chunkFrom.plusDays(chunkDays - 1L);
            if (chunkTo.isAfter(to)) chunkTo = to;
            for (AmfiReportType type : AmfiReportType.values()) {
                executions.add(backfillChunk(type, chunkFrom, chunkTo));
            }
            chunkFrom = chunkTo.plusDays(1);
        }
        return new BackfillSummary(from, to, chunkDays, List.copyOf(executions));
    }

    private SyncSummary backfillChunk(
            AmfiReportType type, LocalDate from, LocalDate to) {
        String reportName = "HISTORICAL_" + type.schemeType();
        UUID executionId = startExecution(reportName, from, to);
        int received = 0;
        int imported = 0;
        int rejectedCount = 0;
        try {
            String body = historicalClient.fetch(type, from, to);
            AmfiParseResult parsed = historicalParser.parse(body, type);
            received = parsed.records().size();
            List<AmfiRejectedRecord> rejected =
                    new ArrayList<>(parsed.rejectedRecords());
            rejectedCount = rejected.size();
            List<AmfiNavRecord> inRange = new ArrayList<>();
            for (AmfiNavRecord row : parsed.records()) {
                if (row.navDate().isBefore(from) || row.navDate().isAfter(to)) {
                    rejected.add(new AmfiRejectedRecord(row.lineNumber(),
                            row.rawRecord(), "NAV date is outside the requested backfill range."));
                } else {
                    inRange.add(row);
                }
            }
            rejectedCount = rejected.size();
            List<AmfiNavRecord> missingSchemes = missingSchemes(inRange);
            schemeSync.synchronize(mapper.toSchemesOnlySnapshot(missingSchemes),
                    PROVIDER_CODE, false, executionId, reportName);
            var importResult = historicalImport.importHistorical(
                    executionId, reportName, inRange);
            imported = importResult.recordsImported();
            rejected.addAll(importResult.rejectedRecords());
            rejectedCount = rejected.size();
            audit(executionId, new AmfiParseResult(inRange, rejected));
            String status = rejected.isEmpty() ? "SUCCEEDED" : "PARTIAL";
            finishExecution(executionId, status, inRange.size(),
                    imported,
                    rejected.size(), null);
            return new SyncSummary(executionId, reportName, status,
                    inRange.size(), imported, rejected.size());
        } catch (RuntimeException exception) {
            failExecution(executionId, exception, received, imported, rejectedCount);
            return new SyncSummary(executionId, reportName, "FAILED",
                    received, imported, rejectedCount);
        }
    }

    private UUID startExecution(String reportType, LocalDate from, LocalDate to) {
        UUID id = UUID.randomUUID();
        jdbc.update("""
                INSERT INTO amfi_sync_execution (
                  id, report_type, requested_from, requested_to, status, started_at
                ) VALUES (?, ?, ?, ?, 'RUNNING', ?)
                """, id, reportType, from, to, OffsetDateTime.now(ZoneOffset.UTC));
        return id;
    }

    private List<AmfiNavRecord> missingSchemes(List<AmfiNavRecord> records) {
        List<String> codes = records.stream().map(AmfiNavRecord::schemeCode)
                .distinct().toList();
        if (codes.isEmpty()) return List.of();
        Set<String> existing = Set.copyOf(jdbc.queryForList("""
                SELECT scheme_code FROM mutual_fund_scheme
                WHERE scheme_code IN (%s)
                """.formatted(String.join(",", java.util.Collections.nCopies(
                        codes.size(), "?"))), String.class, codes.toArray()));
        Map<String, AmfiNavRecord> missing = new LinkedHashMap<>();
        for (AmfiNavRecord record : records) {
            if (!existing.contains(record.schemeCode())) {
                missing.putIfAbsent(record.schemeCode(), record);
            }
        }
        return List.copyOf(missing.values());
    }

    private void audit(UUID executionId, AmfiParseResult parsed) {
        for (AmfiNavRecord row : parsed.records()) {
            jdbc.update("""
                    INSERT INTO amfi_source_record_audit (
                      execution_id, line_number, raw_record, source_scheme_code,
                      nav_date, nav_value, accepted
                    ) VALUES (?, ?, ?, ?, ?, ?, true)
                    """, executionId, row.lineNumber(), row.rawRecord(),
                    row.schemeCode(), row.navDate(), row.nav());
        }
        for (AmfiRejectedRecord row : parsed.rejectedRecords()) {
            jdbc.update("""
                    INSERT INTO amfi_source_record_audit (
                      execution_id, line_number, raw_record, accepted, rejection_reason
                    ) VALUES (?, ?, ?, false, ?)
                    """, executionId, row.lineNumber(), row.rawRecord(), row.reason());
        }
    }

    private void finishExecution(UUID id, String status, int received,
                                 int imported, int rejected, String errorCode) {
        jdbc.update("""
                UPDATE amfi_sync_execution SET status = ?, completed_at = now(),
                  records_received = ?, records_imported = ?, records_rejected = ?,
                  error_code = ? WHERE id = ?
                """, status, received, imported, rejected, errorCode, id);
    }

    private void failExecution(UUID id, RuntimeException exception,
                               int received, int imported, int rejected) {
        finishExecution(id, "FAILED", received, imported, rejected,
                exception.getClass().getSimpleName());
        LOGGER.error("AMFI synchronization failed: execution={}", id, exception);
    }

    public record SyncSummary(UUID executionId, String reportType, String status,
                              int recordsReceived, int recordsImported,
                              int recordsRejected) {}

    public record BackfillSummary(LocalDate from, LocalDate to, int chunkDays,
                                  List<SyncSummary> executions) {}
}
