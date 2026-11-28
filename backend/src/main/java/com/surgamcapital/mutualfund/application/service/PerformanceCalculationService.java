package com.surgamcapital.mutualfund.application.service;

import com.surgamcapital.mutualfund.domain.model.NavPoint;
import com.surgamcapital.mutualfund.domain.model.PerformanceMetric;
import com.surgamcapital.mutualfund.domain.model.MutualFundScheme;
import com.surgamcapital.mutualfund.infrastructure.persistence.MutualFundReadRepository;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class PerformanceCalculationService {
    private static final List<Period> PERIODS = List.of(
            new Period("1M", 1, 0, false),
            new Period("3M", 3, 0, false),
            new Period("6M", 6, 0, false),
            new Period("1Y", 12, 330, false),
            new Period("3Y", 36, 1050, true),
            new Period("5Y", 60, 1750, true),
            new Period("10Y", 120, 3500, true));

    private final MutualFundReadRepository repository;

    public PerformanceCalculationService(MutualFundReadRepository repository) {
        this.repository = repository;
    }

    public List<PerformanceMetric> calculate(MutualFundScheme scheme) {
        Optional<NavPoint> latest = repository.latestNav(scheme.id());
        if (latest.isEmpty()) return PERIODS.stream()
                .map(p -> PerformanceMetric.unavailable(p.code(), null, scheme.providerCode()))
                .toList();
        LocalDate asOf = latest.get().date();
        List<PerformanceMetric> metrics = new ArrayList<>();
        for (Period period : PERIODS) {
            LocalDate target = asOf.minusMonths(period.months());
            Optional<NavPoint> start = repository.navOnOrBefore(scheme.id(), target);
            metrics.add(start
                    .filter(nav -> ChronoUnit.DAYS.between(nav.date(), asOf) >= period.minimumDays())
                    .map(nav -> calculatePointToPoint(period.code(), nav, latest.get(),
                            period.cagr(), scheme.optionType().equals("IDCW"), scheme.providerCode()))
                    .orElseGet(() -> PerformanceMetric.unavailable(
                            period.code(), asOf, scheme.providerCode())));
        }
        Optional<NavPoint> inception = repository.navHistory(
                scheme.id(), LocalDate.of(1900, 1, 1), asOf).stream().findFirst();
        if (inception.isEmpty() || ChronoUnit.DAYS.between(inception.get().date(), asOf) < 365) {
            metrics.add(PerformanceMetric.unavailable(
                    "SINCE_INCEPTION", asOf, scheme.providerCode()));
        } else {
            metrics.add(calculatePointToPoint("SINCE_INCEPTION", inception.get(),
                    latest.get(), true, scheme.optionType().equals("IDCW"), scheme.providerCode()));
        }
        return List.copyOf(metrics);
    }

    public static PerformanceMetric calculatePointToPoint(
            String period, NavPoint start, NavPoint end, boolean cagr,
            boolean idcw, String dataSource) {
        long days = ChronoUnit.DAYS.between(start.date(), end.date());
        if (days <= 0 || start.nav().signum() <= 0 || end.nav().signum() <= 0) {
            return PerformanceMetric.unavailable(period, end.date(), dataSource);
        }
        double ratio = end.nav().divide(start.nav(), 16, RoundingMode.HALF_UP).doubleValue();
        double value = cagr
                ? (Math.pow(ratio, 365.25 / days) - 1) * 100
                : (ratio - 1) * 100;
        if (!Double.isFinite(value)) {
            return PerformanceMetric.unavailable(period, end.date(), dataSource);
        }
        return new PerformanceMetric(period,
                BigDecimal.valueOf(value).setScale(4, RoundingMode.HALF_UP),
                "AVAILABLE", cagr ? "NAV_BASED_CAGR" : "NAV_BASED_ABSOLUTE",
                start.date(), end.date(), end.date(), true, false,
                dataSource + (idcw ? " (IDCW distributions excluded)" : ""));
    }

    private record Period(String code, int months, long minimumDays, boolean cagr) {}
}
