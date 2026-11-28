package com.surgamcapital.mutualfund.infrastructure.amfi;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertEquals;

class AmfiNavParserTest {
    private final AmfiNavParser parser = new AmfiNavParser(new AmfiDataValidator());

    @Test
    void parsesCapturedOfficialLatestReportSample() throws IOException {
        String report;
        try (var sample = getClass().getResourceAsStream("/amfi/NAVAll-sample.txt")) {
            if (sample == null) throw new IllegalStateException("AMFI sample fixture is missing.");
            report = new String(sample.readAllBytes(), StandardCharsets.UTF_8);
        }

        AmfiParseResult result = parser.parse(report);

        assertEquals(2, result.records().size());
        assertEquals("Axis Mutual Fund", result.records().getFirst().amcName());
        assertEquals("Children’s Fund - Childrens' Fund",
                result.records().getFirst().categoryName());
        assertEquals("DIRECT", new AmfiSchemeMapper().toLatestSnapshot(result.records())
                .schemes().getFirst().planType());
        assertEquals(0, result.rejectedRecords().size());
    }

    @Test
    void parsesLatestReportWithItsOwnColumnLayoutAndSeparateIsins() {
        String report = """
                Scheme Code;ISIN Div Payout/ ISIN Growth;ISIN Div Reinvestment;Scheme Name;Plan;Option;Net Asset Value;Date
                Example Mutual Fund
                Open Ended Schemes (Debt)
                123456;INE000A01011;INE000A01029;Example Direct Growth;Direct;Growth;12.3456;01-Jan-2020
                """;

        AmfiParseResult result = parser.parse(report);

        assertEquals(1, result.records().size());
        AmfiNavRecord row = result.records().getFirst();
        assertEquals("123456", row.schemeCode());
        assertEquals(new BigDecimal("12.3456"), row.nav());
        assertEquals("OPEN_ENDED", row.schemeType());
        assertEquals("Debt", row.categoryName());
        assertEquals("INE000A01011", row.isinDivPayoutOrGrowth());
        assertEquals("INE000A01029", row.isinDivReinvestment());
        assertEquals("123456;INE000A01011;INE000A01029;Example Direct Growth;Direct;Growth;12.3456;01-Jan-2020",
                row.rawRecord());
        assertEquals(0, result.rejectedRecords().size());
    }

    @Test
    void recordsDuplicateAndMalformedLatestRowsAsRejected() {
        String report = """
                Scheme Code;ISIN Div Payout/ ISIN Growth;ISIN Div Reinvestment;Scheme Name;Plan;Option;Net Asset Value;Date
                Example Mutual Fund
                Interval Ended Schemes (Other)
                123456;-;-;Example Growth;Regular;Growth;12.3456;01-Jan-2020
                123456;-;-;Example Growth;Regular;Growth;12.3456;01-Jan-2020
                bad;row
                """;

        AmfiParseResult result = parser.parse(report);

        assertEquals(1, result.records().size());
        assertEquals("INTERVAL", result.records().getFirst().schemeType());
        assertEquals(2, result.rejectedRecords().size());
        assertEquals("Duplicate scheme/date record in AMFI report.",
                result.rejectedRecords().getFirst().reason());
    }
}
