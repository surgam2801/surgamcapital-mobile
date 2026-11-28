package com.surgamcapital.mutualfund.application.dto;

import com.surgamcapital.mutualfund.domain.model.MutualFundScheme;
import com.surgamcapital.mutualfund.domain.model.NavPoint;
import com.surgamcapital.mutualfund.domain.model.PerformanceMetric;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public final class MutualFundDtos {
    private MutualFundDtos() {}

    public record SchemeCard(
            UUID id, String schemeCode, String isin,
            String isinDivPayoutOrGrowth, String isinDivReinvestment, String schemeName,
            String amcName, String category, String categoryCode, String assetClass,
            String subCategory, String planType, String optionType,
            String riskometer, String schemeStatus, java.math.BigDecimal latestNav,
            LocalDate latestNavDate, java.math.BigDecimal expenseRatio,
            PerformanceMetric oneYearReturn, boolean mockData, String dataSource) {
        public static SchemeCard from(MutualFundScheme scheme,
                                      PerformanceMetric oneYearReturn) {
            return new SchemeCard(scheme.id(), scheme.schemeCode(), scheme.isin(),
                    scheme.isinDivPayoutOrGrowth(), scheme.isinDivReinvestment(),
                    scheme.schemeName(), scheme.amcName(), scheme.category(),
                    scheme.categoryCode(), scheme.assetClass(), scheme.subCategory(),
                    scheme.planType(), scheme.optionType(), scheme.riskometer(),
                    scheme.schemeStatus(), scheme.latestNav(), scheme.latestNavDate(),
                    scheme.expenseRatio(), oneYearReturn, scheme.mockData(),
                    scheme.providerCode());
        }
    }

    public record SchemePage(
            List<SchemeCard> items, int page, int size, long totalElements,
            int totalPages, String sortBy, String sortDirection) {}

    public record SchemeDetails(
            SchemeCard scheme, String schemeType, String benchmarkName,
            LocalDate inceptionDate, java.math.BigDecimal aum, String exitLoad,
            java.math.BigDecimal minimumLumpsum, java.math.BigDecimal minimumSip,
            String investmentObjective, String description, String fundManager,
            OffsetDateTime sourceUpdatedAt, List<PerformanceMetric> performance,
            String performanceDisclosure, String riskDisclosure) {}

    public record Category(String code, String name, String assetClass) {}
    public record Amc(String code, String name) {}
    public record NavHistory(
            UUID schemeId, LocalDate fromDate, LocalDate toDate,
            LocalDate navDate, OffsetDateTime importedAt, String dataSource,
            boolean mockData, List<NavPoint> points) {}
    public record Comparison(List<SchemeDetails> schemes, List<String> comparisonWarnings,
                             String disclaimer) {}
    public record Performance(List<PerformanceMetric> metrics, String disclosure) {}
    public record Watchlist(List<SchemeCard> items) {}
}
