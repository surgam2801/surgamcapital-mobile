package com.surgamcapital.mutualfund.infrastructure.amfi;

import com.surgamcapital.mutualfund.application.port.MutualFundDataProvider;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

@Component
public class AmfiSchemeMapper {
    public MutualFundDataProvider.ProviderSnapshot toLatestSnapshot(
            List<AmfiNavRecord> records) {
        return toSnapshot(records, true);
    }

    public MutualFundDataProvider.ProviderSnapshot toSchemesOnlySnapshot(
            List<AmfiNavRecord> records) {
        return toSnapshot(records, false);
    }

    private MutualFundDataProvider.ProviderSnapshot toSnapshot(
            List<AmfiNavRecord> records, boolean includeNavs) {
        var schemes = new LinkedHashMap<String, MutualFundDataProvider.SchemeRecord>();
        var navs = new java.util.ArrayList<MutualFundDataProvider.NavRecord>();
        for (AmfiNavRecord row : records) {
            String amcCode = internalCode("AMC", row.amcName());
            String categoryCode = internalCode("CATEGORY",
                    row.schemeType() + ":" + row.categoryName());
            var scheme = new MutualFundDataProvider.SchemeRecord(
                    row.schemeCode(), firstNonNull(row.isinDivPayoutOrGrowth(),
                    row.isinDivReinvestment()), row.isinDivPayoutOrGrowth(),
                    row.isinDivReinvestment(), row.schemeName(),
                    amcCode, row.amcName(), categoryCode, row.categoryName(),
                    "UNKNOWN", null, schemeType(row.schemeType()),
                    planType(row.plan()), optionType(row.option()), null, null,
                    null, null, null, null, null, null, null, null, null, "UNKNOWN");
            schemes.putIfAbsent(row.schemeCode(), scheme);
            if (includeNavs) {
                navs.add(new MutualFundDataProvider.NavRecord(
                        row.schemeCode(), row.navDate(), row.nav(),
                        "AMFI:NAVAll.txt:" + row.lineNumber()));
            }
        }
        return new MutualFundDataProvider.ProviderSnapshot(
                List.copyOf(schemes.values()), List.copyOf(navs));
    }

    private String schemeType(String value) {
        return switch (value) {
            case "OPEN_ENDED" -> "Open Ended";
            case "CLOSE_ENDED" -> "Close Ended";
            case "INTERVAL" -> "Interval";
            default -> "Unknown";
        };
    }

    private String planType(String value) {
        String normalized = value == null ? "" : value.toLowerCase(Locale.ROOT);
        if (normalized.contains("direct")) return "DIRECT";
        if (normalized.contains("regular")) return "REGULAR";
        return "UNKNOWN";
    }

    private String optionType(String value) {
        String normalized = value == null ? "" : value.toLowerCase(Locale.ROOT);
        if (normalized.contains("growth")) return "GROWTH";
        if (normalized.contains("idcw") || normalized.contains("dividend")) {
            return "IDCW";
        }
        return "UNKNOWN";
    }

    private String firstNonNull(String first, String second) {
        return first == null ? second : first;
    }

    private String internalCode(String type, String sourceName) {
        return type + "-" + UUID.nameUUIDFromBytes(
                sourceName.getBytes(StandardCharsets.UTF_8))
                .toString().replace("-", "").substring(0, 20);
    }
}
