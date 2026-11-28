package com.surgamcapital.mutualfund.infrastructure.amfi;

import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.HashSet;
import java.util.Set;

@Component
public class AmfiDataValidator {
    public String validate(
            String schemeCode, BigDecimal nav, LocalDate navDate, LocalDate today) {
        if (schemeCode == null || !schemeCode.matches("[0-9]{1,20}")) {
            return "Scheme code must contain only digits.";
        }
        if (nav == null || nav.signum() <= 0 || nav.scale() > 6
                || nav.precision() > 18) {
            return "NAV must be a positive decimal within supported precision.";
        }
        if (navDate == null || navDate.isAfter(today)) {
            return "NAV date is missing or in the future.";
        }
        return null;
    }

    public String validateDuplicate(String schemeCode, LocalDate navDate, Set<String> seen) {
        String key = schemeCode + ":" + navDate;
        return seen.add(key) ? null : "Duplicate scheme/date record in AMFI report.";
    }

    public String validateMetadataLengths(
            String schemeName, String plan, String option,
            String isinPrimary, String isinReinvestment,
            String amcName, String categoryName) {
        if (exceeds(schemeName, 240) || exceeds(plan, 20) || exceeds(option, 20)
                || exceeds(isinPrimary, 20) || exceeds(isinReinvestment, 20)
                || exceeds(amcName, 160) || exceeds(categoryName, 120)) {
            return "A source field exceeds the supported AMFI scheme metadata length.";
        }
        return null;
    }

    private boolean exceeds(String value, int maxLength) {
        return value != null && value.length() > maxLength;
    }

    public Set<String> newSeenSet() {
        return new HashSet<>();
    }
}
