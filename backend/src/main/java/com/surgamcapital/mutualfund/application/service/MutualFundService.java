package com.surgamcapital.mutualfund.application.service;

import com.surgamcapital.mutualfund.application.dto.MutualFundDtos;
import com.surgamcapital.mutualfund.application.dto.SchemeSearch;
import com.surgamcapital.mutualfund.domain.model.MutualFundScheme;
import com.surgamcapital.mutualfund.domain.model.NavPoint;
import com.surgamcapital.mutualfund.infrastructure.persistence.MutualFundReadRepository;
import com.surgamcapital.mutualfund.infrastructure.persistence.MutualFundReadRepository.SchemeFilters;
import com.surgamcapital.shared.exception.AuthException;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class MutualFundService {
    private static final String PAST_PERFORMANCE_DISCLOSURE =
            "Past performance is not indicative of future returns.";
    private static final String RISK_DISCLOSURE =
            "Mutual Fund investments are subject to market risks. Please read all scheme related documents carefully.";

    private final MutualFundReadRepository repository;
    private final PerformanceCalculationService performance;
    private final JdbcTemplate jdbc;

    public MutualFundService(MutualFundReadRepository repository,
                             PerformanceCalculationService performance,
                             JdbcTemplate jdbc) {
        this.repository = repository;
        this.performance = performance;
        this.jdbc = jdbc;
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = "mutual-fund-schemes", key = "#request.toString()")
    public MutualFundDtos.SchemePage search(SchemeSearch request) {
        validateExpenseRange(request);
        int page = request.page() == null ? 0 : request.page();
        int size = request.size() == null ? 20 : request.size();
        String sortBy = normalizeSort(request.sortBy());
        String direction = request.sortDirection() == null
                ? "ASC" : request.sortDirection().toUpperCase(java.util.Locale.ROOT);
        if (!direction.equals("ASC") && !direction.equals("DESC")) {
            throw badRequest("INVALID_SORT_DIRECTION", "Sort direction must be ASC or DESC.");
        }
        Sort sort = Sort.by(Sort.Direction.fromString(direction), sortBy);
        var pageRequest = PageRequest.of(page, size, sort);
        String planType = request.planType() == null || request.planType().isBlank()
                ? "REGULAR" : request.planType().toUpperCase(java.util.Locale.ROOT);
        if (!List.of("REGULAR", "DIRECT", "UNKNOWN").contains(planType)) {
            throw badRequest("INVALID_PLAN_TYPE",
                    "Plan type must be REGULAR, DIRECT, or UNKNOWN.");
        }
        SchemeFilters filters = new SchemeFilters(request.search(), request.amcId(),
                request.amcIds(), request.category(), request.categories(),
                request.subCategory(), request.riskLevel(),
                planType, request.optionType(), request.schemeStatus(),
                request.minExpenseRatio(), request.maxExpenseRatio());
        List<MutualFundScheme> schemes = repository.search(filters, pageRequest);
        List<MutualFundDtos.SchemeCard> cards = schemes.stream()
                .map(scheme -> MutualFundDtos.SchemeCard.from(scheme,
                        performance.calculate(scheme).stream()
                                .filter(metric -> metric.period().equals("1Y"))
                                .findFirst().orElse(null)))
                .toList();
        long total = repository.count(filters);
        return new MutualFundDtos.SchemePage(cards, page, size, total,
                (int) Math.ceil((double) total / size), sortBy, direction);
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = "mutual-fund-scheme-details", key = "#schemeId")
    public MutualFundDtos.SchemeDetails details(UUID schemeId) {
        return details(findScheme(schemeId));
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = "mutual-fund-categories", key = "'all'")
    public List<MutualFundDtos.Category> categories() {
        return repository.categories().stream()
                .map(row -> new MutualFundDtos.Category(
                        (String) row.get("code"), (String) row.get("name"),
                        (String) row.get("assetClass"))).toList();
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = "mutual-fund-amcs", key = "'all'")
    public List<MutualFundDtos.Amc> amcs() {
        return repository.amcs().stream()
                .map(row -> new MutualFundDtos.Amc((String) row.get("code"),
                        (String) row.get("name"))).toList();
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = "mutual-fund-nav-history",
            key = "#schemeId + ':' + #from + ':' + #to + ':' + #interval")
    public MutualFundDtos.NavHistory navHistory(UUID schemeId, LocalDate from,
                                                LocalDate to, String interval) {
        MutualFundScheme scheme = findScheme(schemeId);
        if (from == null || to == null || from.isAfter(to) || to.isAfter(LocalDate.now())) {
            throw badRequest("INVALID_NAV_RANGE",
                    "NAV date range must be valid and cannot include future dates.");
        }
        if (!List.of("DAILY", "WEEKLY", "MONTHLY").contains(
                interval.toUpperCase(java.util.Locale.ROOT))) {
            throw badRequest("INVALID_NAV_INTERVAL", "NAV interval must be daily, weekly, or monthly.");
        }
        List<NavPoint> raw = repository.navHistory(schemeId, from, to);
        List<NavPoint> points = downsample(raw, interval.toUpperCase(java.util.Locale.ROOT), 500);
        OffsetDateTime importedAt = repository.lastImportedAt(schemeId).orElse(null);
        return new MutualFundDtos.NavHistory(schemeId, from, to,
                raw.isEmpty() ? null : raw.get(raw.size() - 1).date(),
                importedAt, scheme.providerCode(), scheme.mockData(), points);
    }

    @Transactional(readOnly = true)
    @Cacheable(cacheNames = "mutual-fund-performance", key = "#schemeId")
    public MutualFundDtos.Performance performance(UUID schemeId) {
        MutualFundScheme scheme = findScheme(schemeId);
        return new MutualFundDtos.Performance(performance.calculate(scheme),
                scheme.optionType().equals("IDCW")
                        ? "NAV-based returns exclude IDCW distributions and are not total returns. "
                                + PAST_PERFORMANCE_DISCLOSURE
                        : "Returns are NAV-based. " + PAST_PERFORMANCE_DISCLOSURE);
    }

    @Transactional(readOnly = true)
    public MutualFundDtos.Comparison compare(List<UUID> schemeIds) {
        if (schemeIds == null || schemeIds.isEmpty() || schemeIds.size() > 4
                || schemeIds.stream().distinct().count() != schemeIds.size()) {
            throw badRequest("INVALID_COMPARISON",
                    "Select between one and four unique schemes to compare.");
        }
        List<MutualFundScheme> schemes = repository.findByIds(schemeIds);
        if (schemes.size() != schemeIds.size()) {
            throw new AuthException(HttpStatus.NOT_FOUND, "SCHEME_NOT_FOUND",
                    "One or more selected schemes were not found.");
        }
        var byId = schemes.stream().collect(java.util.stream.Collectors.toMap(
                MutualFundScheme::id, scheme -> scheme));
        List<MutualFundDtos.SchemeDetails> details = schemeIds.stream()
                .map(byId::get).map(this::details).toList();
        List<String> warnings = new ArrayList<>();
        if (schemes.stream().map(MutualFundScheme::categoryCode).distinct().count() > 1) {
            warnings.add("Selected schemes belong to different categories; compare with care.");
        }
        if (schemes.stream().map(MutualFundScheme::optionType).distinct().count() > 1) {
            warnings.add("Growth and IDCW options are not equivalent; IDCW NAV returns exclude distributions.");
        }
        warnings.add(PAST_PERFORMANCE_DISCLOSURE);
        return new MutualFundDtos.Comparison(details, warnings, RISK_DISCLOSURE);
    }

    @Transactional(readOnly = true)
    public MutualFundDtos.Watchlist watchlist(UUID investorId) {
        return new MutualFundDtos.Watchlist(repository.watchlist(investorId).stream()
                .map(scheme -> MutualFundDtos.SchemeCard.from(scheme,
                        performance.calculate(scheme).stream()
                                .filter(metric -> metric.period().equals("1Y"))
                                .findFirst().orElse(null)))
                .toList());
    }

    @Transactional
    public void addToWatchlist(UUID investorId, UUID schemeId) {
        findScheme(schemeId);
        jdbc.update("""
                INSERT INTO investor_scheme_watchlist (id, investor_id, scheme_id)
                VALUES (?, ?, ?) ON CONFLICT (investor_id, scheme_id) DO NOTHING
                """, UUID.randomUUID(), investorId, schemeId);
    }

    @Transactional
    public void removeFromWatchlist(UUID investorId, UUID schemeId) {
        jdbc.update("""
                DELETE FROM investor_scheme_watchlist
                WHERE investor_id = ? AND scheme_id = ?
                """, investorId, schemeId);
    }

    private MutualFundDtos.SchemeDetails details(MutualFundScheme scheme) {
        var metrics = performance.calculate(scheme);
        MutualFundDtos.SchemeCard card = MutualFundDtos.SchemeCard.from(scheme,
                metrics.stream()
                        .filter(metric -> metric.period().equals("1Y"))
                        .findFirst().orElse(null));
        return new MutualFundDtos.SchemeDetails(card, scheme.schemeType(),
                scheme.benchmarkName(), scheme.inceptionDate(), scheme.aum(),
                scheme.exitLoad(), scheme.minimumLumpsum(), scheme.minimumSip(),
                scheme.investmentObjective(), scheme.schemeDescription(),
                scheme.fundManager(), scheme.sourceUpdatedAt(), metrics,
                scheme.optionType().equals("IDCW")
                        ? "NAV-based returns exclude IDCW distributions."
                        : "Returns are NAV-based; distributions are not included.",
                RISK_DISCLOSURE);
    }

    private MutualFundScheme findScheme(UUID id) {
        return repository.findById(id).orElseThrow(() ->
                new AuthException(HttpStatus.NOT_FOUND, "SCHEME_NOT_FOUND",
                        "The requested scheme was not found."));
    }

    private String normalizeSort(String requested) {
        String sort = requested == null || requested.isBlank()
                ? "schemeName" : requested;
        if (!List.of("schemeName", "latestNavDate", "expenseRatio", "aum").contains(sort)) {
            throw badRequest("INVALID_SORT", "Unsupported scheme sort field.");
        }
        return sort;
    }

    private void validateExpenseRange(SchemeSearch request) {
        if (request.minExpenseRatio() != null && request.minExpenseRatio().signum() < 0
                || request.maxExpenseRatio() != null && request.maxExpenseRatio().signum() < 0
                || request.minExpenseRatio() != null && request.maxExpenseRatio() != null
                && request.minExpenseRatio().compareTo(request.maxExpenseRatio()) > 0) {
            throw badRequest("INVALID_EXPENSE_RANGE", "Expense ratio range is invalid.");
        }
    }

    private List<NavPoint> downsample(List<NavPoint> points, String interval, int maximum) {
        if (points.size() <= 2) return points;
        List<NavPoint> selected = switch (interval) {
            case "WEEKLY" -> points.stream()
                    .filter(point -> point.date().getDayOfWeek()
                            == java.time.DayOfWeek.FRIDAY).toList();
            case "MONTHLY" -> {
                var byMonth = new java.util.LinkedHashMap<java.time.YearMonth, NavPoint>();
                for (NavPoint point : points) {
                    byMonth.put(java.time.YearMonth.from(point.date()), point);
                }
                yield List.copyOf(byMonth.values());
            }
            default -> points;
        };
        if (selected.isEmpty()) selected = points;
        if (selected.size() <= maximum) return selected;
        int stride = (int) Math.ceil((double) (selected.size() - 1) / (maximum - 1));
        List<NavPoint> sampled = new ArrayList<>();
        for (int i = 0; i < selected.size(); i += stride) sampled.add(selected.get(i));
        if (!sampled.get(sampled.size() - 1).equals(selected.get(selected.size() - 1))) {
            sampled.add(selected.get(selected.size() - 1));
        }
        return List.copyOf(sampled);
    }

    private AuthException badRequest(String code, String message) {
        return new AuthException(HttpStatus.BAD_REQUEST, code, message);
    }
}
