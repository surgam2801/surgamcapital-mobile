package com.surgamcapital.mutualfund.infrastructure.amfi;

import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
public class AmfiHistoricalNavParser {
    private static final List<String> HEADER = List.of(
            "Scheme Code", "NAV Name", "Plan", "Option",
            "ISIN Div Payout/ISIN Growth", "ISIN Div Reinvestment",
            "Net Asset Value", "Date");
    private static final Pattern CATEGORY = Pattern.compile(
            "^(Open|Close|Interval) Ended Schemes\\s*(?:\\((.*)\\))?$",
            Pattern.CASE_INSENSITIVE);
    private final AmfiDataValidator validator;

    public AmfiHistoricalNavParser(AmfiDataValidator validator) {
        this.validator = validator;
    }

    public AmfiParseResult parse(String report, AmfiReportType reportType) {
        if (report == null || report.isBlank()) {
            throw new IllegalArgumentException("AMFI historical NAV report is empty.");
        }
        String[] lines = report.split("\\R", -1);
        if (lines.length == 0 || !AmfiNavParser.headerMatches(lines[0], HEADER)) {
            throw new IllegalArgumentException("AMFI historical NAV report header is unexpected.");
        }

        List<AmfiNavRecord> records = new ArrayList<>();
        List<AmfiRejectedRecord> rejected = new ArrayList<>();
        String amcName = null;
        String categoryName = null;
        var seen = validator.newSeenSet();
        for (int index = 1; index < lines.length; index++) {
            String raw = lines[index];
            String line = raw.trim();
            if (line.isEmpty()) continue;
            if (line.indexOf(';') < 0) {
                Matcher category = CATEGORY.matcher(line);
                if (category.matches()) {
                    categoryName = AmfiNavParser.blankToNull(category.group(2));
                } else if (line.endsWith("Mutual Fund")) {
                    amcName = line;
                } else {
                    rejected.add(new AmfiRejectedRecord(index + 1, raw,
                            "Unrecognized non-data row in historical NAV report."));
                }
                continue;
            }
            String[] fields = raw.split(";", -1);
            if (fields.length != HEADER.size()) {
                rejected.add(new AmfiRejectedRecord(index + 1, raw,
                        "Historical NAV row must contain exactly eight columns."));
                continue;
            }
            String code = AmfiNavParser.clean(fields[0]);
            String name = AmfiNavParser.clean(fields[1]);
            String plan = AmfiNavParser.clean(fields[2]);
            String option = AmfiNavParser.clean(fields[3]);
            var nav = AmfiNavParser.decimal(fields[6]);
            LocalDate date = AmfiNavParser.date(fields[7]);
            String reason = validator.validate(code, nav, date,
                    LocalDate.now(ZoneOffset.UTC));
            if (reason == null) {
                reason = validator.validateDuplicate(code, date, seen);
            }
            if (name == null) {
                reason = AmfiNavParser.first(reason, "Historical NAV name is missing.");
            }
            if (amcName == null || categoryName == null) {
                reason = AmfiNavParser.first(reason,
                        "Historical NAV row is missing its AMFI AMC/category heading context.");
            }
            reason = AmfiNavParser.first(reason, validator.validateMetadataLengths(
                    name, plan, option, AmfiNavParser.clean(fields[4]),
                    AmfiNavParser.clean(fields[5]), amcName, categoryName));
            if (reason != null) {
                rejected.add(new AmfiRejectedRecord(index + 1, raw, reason));
                continue;
            }
            records.add(new AmfiNavRecord(
                    code, amcName, categoryName, reportType.schemeType(),
                    AmfiNavParser.clean(fields[4]), AmfiNavParser.clean(fields[5]),
                    name, plan, option, nav, date, raw, index + 1));
        }
        if (records.isEmpty() && rejected.isEmpty()) {
            throw new IllegalArgumentException("AMFI historical report contained no NAV rows.");
        }
        return new AmfiParseResult(records, rejected);
    }
}
