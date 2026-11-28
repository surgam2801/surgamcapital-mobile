package com.surgamcapital.mutualfund.application.port;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public interface MutualFundDataProvider {
    String providerCode();
    ProviderSnapshot fetchSnapshot();

    record ProviderSnapshot(List<SchemeRecord> schemes, List<NavRecord> navs) {}

    record SchemeRecord(
            String schemeCode, String isin, String isinDivPayoutOrGrowth,
            String isinDivReinvestment, String schemeName, String amcCode,
            String amcName, String categoryCode, String categoryName, String assetClass,
            String subCategory, String schemeType, String planType, String optionType,
            String benchmarkName, LocalDate inceptionDate, BigDecimal expenseRatio,
            BigDecimal aum, String exitLoad, BigDecimal minimumLumpsum,
            BigDecimal minimumSip, String riskometer, String investmentObjective,
            String schemeDescription, String fundManager, String schemeStatus) {}

    record NavRecord(String schemeCode, LocalDate date, BigDecimal value,
                     String sourceRecordId) {}
}
