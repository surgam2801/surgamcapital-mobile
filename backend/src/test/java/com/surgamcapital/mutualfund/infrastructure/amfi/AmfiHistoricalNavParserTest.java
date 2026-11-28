package com.surgamcapital.mutualfund.infrastructure.amfi;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class AmfiHistoricalNavParserTest {
    private final AmfiHistoricalNavParser parser =
            new AmfiHistoricalNavParser(new AmfiDataValidator());

    @Test
    void parsesCapturedOfficialHistoricalReportSampleWithMissingIsins()
            throws IOException {
        String report;
        try (var sample = getClass().getResourceAsStream(
                "/amfi/History-open-ended-sample.txt")) {
            if (sample == null) throw new IllegalStateException("AMFI sample fixture is missing.");
            report = new String(sample.readAllBytes(), StandardCharsets.UTF_8);
        }

        AmfiParseResult result = parser.parse(report, AmfiReportType.OPEN_ENDED);

        assertEquals(2, result.records().size());
        assertEquals("139619", result.records().getFirst().schemeCode());
        assertEquals(new BigDecimal("10.0000"), result.records().getFirst().nav());
        assertNull(result.records().getFirst().isinDivPayoutOrGrowth());
        assertNull(result.records().getFirst().plan());
        assertEquals("UNKNOWN", new AmfiSchemeMapper().toLatestSnapshot(result.records())
                .schemes().getFirst().planType());
        assertEquals(0, result.rejectedRecords().size());
    }

    @Test
    void parsesHistoricalReportUsingItsDifferentColumnOrdering() {
        String report = """
                Scheme Code;NAV Name;Plan;Option;ISIN Div Payout/ISIN Growth;ISIN Div Reinvestment;Net Asset Value;Date
                Example Mutual Fund
                Open Ended Schemes
                123456;Example Historical Name;Direct;Growth;INE000A01011;INE000A01029;12.3456;01-Jan-2020
                """;

        AmfiParseResult result = parser.parse(report, AmfiReportType.OPEN_ENDED);

        assertEquals(1, result.records().size());
        AmfiNavRecord row = result.records().getFirst();
        assertEquals("Example Historical Name", row.schemeName());
        assertEquals(new BigDecimal("12.3456"), row.nav());
        assertEquals("INE000A01011", row.isinDivPayoutOrGrowth());
        assertEquals("OPEN_ENDED", row.schemeType());
        assertEquals(0, result.rejectedRecords().size());
    }
}
