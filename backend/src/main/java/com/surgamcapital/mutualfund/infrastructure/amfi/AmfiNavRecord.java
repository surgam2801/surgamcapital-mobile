package com.surgamcapital.mutualfund.infrastructure.amfi;

import java.math.BigDecimal;
import java.time.LocalDate;

public record AmfiNavRecord(
        String schemeCode,
        String amcName,
        String categoryName,
        String schemeType,
        String isinDivPayoutOrGrowth,
        String isinDivReinvestment,
        String schemeName,
        String plan,
        String option,
        BigDecimal nav,
        LocalDate navDate,
        String rawRecord,
        int lineNumber) {}
