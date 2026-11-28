package com.surgamcapital.mutualfund.infrastructure.provider;

import com.surgamcapital.mutualfund.application.port.MutualFundDataProvider;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Component
@Profile({"local", "test"})
public class MockMutualFundDataProvider implements MutualFundDataProvider {
    @Override
    public String providerCode() {
        return "MOCK_DEMO";
    }

    @Override
    public ProviderSnapshot fetchSnapshot() {
        List<SchemeRecord> schemes = List.of(
                new SchemeRecord("DEMO-EQ-G", null, null, null,
                        "[DEMO DATA] Illustrative Equity Growth Fund", "DEMO-AMC",
                        "Demo Asset Management Company", "DEMO-EQUITY", "Demo Equity",
                        "Equity", "Flexi Cap", "Open Ended", "REGULAR", "GROWTH",
                        "Illustrative broad market index", LocalDate.now().minusYears(5),
                        new BigDecimal("1.25000"), new BigDecimal("125000000.00"),
                        "Demo only - not an actual scheme", new BigDecimal("5000.00"),
                        new BigDecimal("500.00"), "HIGH",
                        "Illustrative purpose only. Not an actual investment scheme.",
                        "Synthetic test fixture; not a real mutual fund.", null, "ACTIVE"),
                new SchemeRecord("DEMO-DEBT-G", null, null, null,
                        "[DEMO DATA] Illustrative Short Duration Fund", "DEMO-AMC",
                        "Demo Asset Management Company", "DEMO-DEBT", "Demo Debt",
                        "Debt", "Short Duration", "Open Ended", "REGULAR", "GROWTH",
                        "Illustrative debt benchmark", LocalDate.now().minusYears(4),
                        new BigDecimal("0.65000"), new BigDecimal("85000000.00"),
                        "Demo only - not an actual scheme", new BigDecimal("5000.00"),
                        new BigDecimal("500.00"), "MODERATE",
                        "Illustrative purpose only. Not an actual investment scheme.",
                        "Synthetic test fixture; not a real mutual fund.", null, "ACTIVE"),
                new SchemeRecord("DEMO-HYBRID-IDCW", null, null, null,
                        "[DEMO DATA] Illustrative Hybrid IDCW Fund", "DEMO-AMC",
                        "Demo Asset Management Company", "DEMO-HYBRID", "Demo Hybrid",
                        "Hybrid", "Balanced Advantage", "Open Ended", "REGULAR", "IDCW",
                        "Illustrative hybrid benchmark", LocalDate.now().minusYears(3),
                        null, null, "Demo only - not an actual scheme",
                        null, null, "MODERATELY_HIGH",
                        "Illustrative purpose only. Not an actual investment scheme.",
                        "Synthetic test fixture; not a real mutual fund.", null, "ACTIVE"));
        List<NavRecord> navs = new ArrayList<>();
        for (SchemeRecord scheme : schemes) {
            BigDecimal base = scheme.schemeCode().equals("DEMO-DEBT-G")
                    ? new BigDecimal("10.000000")
                    : scheme.schemeCode().equals("DEMO-HYBRID-IDCW")
                    ? new BigDecimal("12.000000") : new BigDecimal("20.000000");
            for (int month = 36; month >= 0; month--) {
                LocalDate date = LocalDate.now().withDayOfMonth(1).minusMonths(month)
                        .withDayOfMonth(1).minusDays(1);
                BigDecimal value = base.add(new BigDecimal(36 - month)
                        .multiply(new BigDecimal("0.0731")));
                navs.add(new NavRecord(scheme.schemeCode(), date,
                        value.setScale(6, java.math.RoundingMode.HALF_UP),
                        "TEST-FIXTURE-" + scheme.schemeCode() + "-" + date));
            }
        }
        return new ProviderSnapshot(List.copyOf(schemes), List.copyOf(navs));
    }
}
