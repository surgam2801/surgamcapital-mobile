package com.surgamcapital.mutualfund.domain.model;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

public record MutualFundScheme(
        UUID id,
        String schemeCode,
        String isin,
        String isinDivPayoutOrGrowth,
        String isinDivReinvestment,
        String schemeName,
        String amcCode,
        String amcName,
        String category,
        String categoryCode,
        String assetClass,
        String subCategory,
        String schemeType,
        String planType,
        String optionType,
        String benchmarkName,
        LocalDate inceptionDate,
        BigDecimal latestNav,
        LocalDate latestNavDate,
        BigDecimal expenseRatio,
        BigDecimal aum,
        String exitLoad,
        BigDecimal minimumLumpsum,
        BigDecimal minimumSip,
        String riskometer,
        String investmentObjective,
        String schemeDescription,
        String fundManager,
        String schemeStatus,
        String providerCode,
        boolean mockData,
        OffsetDateTime sourceUpdatedAt,
        OffsetDateTime updatedAt) {}
