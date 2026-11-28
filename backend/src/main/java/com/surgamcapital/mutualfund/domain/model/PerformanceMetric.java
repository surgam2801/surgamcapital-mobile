package com.surgamcapital.mutualfund.domain.model;

import java.math.BigDecimal;
import java.time.LocalDate;

public record PerformanceMetric(
        String period,
        BigDecimal value,
        String status,
        String methodology,
        LocalDate startDate,
        LocalDate endDate,
        LocalDate asOfDate,
        boolean dataComplete,
        boolean distributionsIncluded,
        String dataSource) {

    public static PerformanceMetric unavailable(String period, LocalDate asOfDate, String source) {
        return new PerformanceMetric(period, null, "UNAVAILABLE", "NAV_BASED",
                null, null, asOfDate, false, false, source);
    }
}
