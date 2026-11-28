package com.surgamcapital.mutualfund.infrastructure.amfi;

import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeFormatterBuilder;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
public class AmfiNavParser {
    private static final List<String> HEADER = List.of(
            "Scheme Code", "ISIN Div Payout/ ISIN Growth",
            "ISIN Div Reinvestment", "Scheme Name", "Plan", "Option",
            "Net Asset Value", "Date");
    private static final Pattern CATEGORY = Pattern.compile(
            "^(Open|Close|Interval) Ended Schemes\\s*(?:\\((.*)\\))?$",
            Pattern.CASE_INSENSITIVE);
    private static final DateTimeFormatter DATE = new DateTimeFormatterBuilder()
            .parseCaseInsensitive()
            .appendPattern("d-MMM-uuuu")
            .toFormatter(Locale.ENGLISH);

    private final AmfiDataValidator validator;

    public AmfiNavParser(AmfiDataValidator validator) {
        this.validator = validator;
    }

    public AmfiParseResult parse(String report) {
        if (report == null || report.isBlank()) {
            throw new IllegalArgumentException("AMFI latest NAV report is empty.");
        }
        String[] lines = report.split("\\R", -1);
        if (lines.length == 0 || !headerMatches(lines[0], HEADER)) {
            throw new IllegalArgumentException("AMFI latest NAV report header is unexpected.");
        }

        List<AmfiNavRecord> records = new ArrayList<>();
        List<AmfiRejectedRecord> rejected = new ArrayList<>();
        String amcName = null;
        String categoryName = null;
        String schemeType = null;
        var seen = validator.newSeenSet();

        for (int index = 1; index < lines.length; index++) {
            String raw = lines[index];
            String line = raw.trim();
            if (line.isEmpty()) continue;
            if (line.indexOf(';') < 0) {
                Matcher category = CATEGORY.matcher(line);
                if (category.matches()) {
                    schemeType = switch (category.group(1).toLowerCase(Locale.ROOT)) {
                        case "open" -> "OPEN_ENDED";
                        case "close" -> "CLOSE_ENDED";
                        case "interval" -> "INTERVAL";
                        default -> "UNKNOWN";
                    };
                    categoryName = blankToNull(category.group(2));
                } else if (line.endsWith("Mutual Fund")) {
                    amcName = line;
                } else {
                    rejected.add(new AmfiRejectedRecord(index + 1, raw,
                            "Unrecognized non-data row in latest NAV report."));
                }
                continue;
            }

            String[] fields = raw.split(";", -1);
            if (fields.length != HEADER.size()) {
                rejected.add(new AmfiRejectedRecord(index + 1, raw,
                        "Latest NAV row must contain exactly eight columns."));
                continue;
            }
            String code = clean(fields[0]);
            String name = clean(fields[3]);
            String plan = clean(fields[4]);
            String option = clean(fields[5]);
            BigDecimal nav = decimal(fields[6]);
            LocalDate date = date(fields[7]);
            String reason = validator.validate(code, nav, date,
                    LocalDate.now(ZoneOffset.UTC));
            if (reason == null) {
                reason = validator.validateDuplicate(code, date, seen);
            }
            if (amcName == null || categoryName == null || schemeType == null) {
                reason = first(reason,
                        "Latest NAV row is missing its AMFI AMC/category heading context.");
            }
            if (name == null || plan == null) {
                reason = first(reason, "Scheme name or plan is missing.");
            }
            reason = first(reason, validator.validateMetadataLengths(
                    name, plan, option, clean(fields[1]), clean(fields[2]),
                    amcName, categoryName));
            if (reason != null) {
                rejected.add(new AmfiRejectedRecord(index + 1, raw, reason));
                continue;
            }
            records.add(new AmfiNavRecord(
                    code, amcName, categoryName, schemeType,
                    clean(fields[1]), clean(fields[2]), name, plan, option,
                    nav, date, raw, index + 1));
        }
        if (records.isEmpty() && rejected.isEmpty()) {
            throw new IllegalArgumentException("AMFI latest NAV report contained no scheme rows.");
        }
        return new AmfiParseResult(records, rejected);
    }

    static boolean headerMatches(String line, List<String> expected) {
        String[] actual = line.split(";", -1);
        if (actual.length != expected.size()) return false;
        for (int i = 0; i < actual.length; i++) {
            String value = actual[i].trim();
            if (i == 0) value = value.replace("\uFEFF", "");
            if (!value.equalsIgnoreCase(expected.get(i))) return false;
        }
        return true;
    }

    static String clean(String value) {
        if (value == null) return null;
        String cleaned = value.trim();
        return cleaned.isEmpty() || cleaned.equals("-") ? null : cleaned;
    }

    static BigDecimal decimal(String value) {
        try {
            String cleaned = value == null ? "" : value.trim();
            return cleaned.isEmpty() ? null : new BigDecimal(cleaned);
        } catch (NumberFormatException exception) {
            return null;
        }
    }

    static LocalDate date(String value) {
        try {
            String cleaned = value == null ? "" : value.trim();
            return cleaned.isEmpty() ? null : LocalDate.parse(cleaned, DATE);
        } catch (DateTimeParseException exception) {
            return null;
        }
    }

    static String first(String first, String next) {
        return first == null ? next : first;
    }

    static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
