package com.surgamcapital.mutualfund.infrastructure.persistence;

import com.surgamcapital.mutualfund.domain.model.MutualFundScheme;
import com.surgamcapital.mutualfund.domain.model.NavPoint;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Repository;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Repository
public class MutualFundReadRepository {
    private static final String FROM_SCHEME = """
            FROM mutual_fund_scheme s
            JOIN amc_master a ON a.id = s.amc_id
            JOIN scheme_category_master c ON c.id = s.category_id
            JOIN data_provider_master p ON p.id = s.provider_id
            """;
    private static final String SELECT_SCHEME = """
            SELECT s.id, s.scheme_code, s.isin, s.isin_div_payout_or_growth,
                   s.isin_div_reinvestment, s.scheme_name, a.amc_code,
                   a.name AS amc_name, c.name AS category, c.category_code,
                   c.asset_class, s.sub_category, s.scheme_type, s.plan_type,
                   s.option_type, s.benchmark_name, s.inception_date, s.current_nav,
                   s.latest_nav_date, s.expense_ratio, s.aum, s.exit_load,
                   s.minimum_lumpsum, s.minimum_sip, s.riskometer,
                   s.investment_objective, s.scheme_description, s.fund_manager,
                   s.scheme_status, p.provider_code, p.is_mock, s.source_updated_at,
                   s.updated_at
            """ + FROM_SCHEME;
    private static final RowMapper<MutualFundScheme> SCHEME_MAPPER =
            MutualFundReadRepository::mapScheme;

    private final NamedParameterJdbcTemplate jdbc;

    public MutualFundReadRepository(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<MutualFundScheme> search(SchemeFilters filters, PageRequest page) {
        var parameters = new MapSqlParameterSource();
        String where = buildWhere(filters, parameters);
        String order = orderBy(page.getSort());
        parameters.addValue("limit", page.getPageSize());
        parameters.addValue("offset", page.getOffset());
        return jdbc.query(SELECT_SCHEME + where + order + " LIMIT :limit OFFSET :offset",
                parameters, SCHEME_MAPPER);
    }

    public long count(SchemeFilters filters) {
        var parameters = new MapSqlParameterSource();
        String where = buildWhere(filters, parameters);
        Long count = jdbc.queryForObject("SELECT count(*) " + FROM_SCHEME + where,
                parameters, Long.class);
        return count == null ? 0 : count;
    }

    public Optional<MutualFundScheme> findById(UUID id) {
        return jdbc.query(SELECT_SCHEME + " WHERE s.id = :id",
                Map.of("id", id), SCHEME_MAPPER).stream().findFirst();
    }

    public List<MutualFundScheme> findByIds(List<UUID> ids) {
        return jdbc.query(SELECT_SCHEME + " WHERE s.id IN (:ids)",
                Map.of("ids", ids), SCHEME_MAPPER);
    }

    public List<MutualFundScheme> watchlist(UUID investorId) {
        return jdbc.query(SELECT_SCHEME + """
                 JOIN investor_scheme_watchlist w ON w.scheme_id = s.id
                 WHERE w.investor_id = :investorId
                 ORDER BY w.created_at DESC
                """, Map.of("investorId", investorId), SCHEME_MAPPER);
    }

    public List<NavPoint> navHistory(UUID schemeId, LocalDate from, LocalDate to) {
        return jdbc.query("""
                SELECT nav_date, nav_value FROM scheme_nav_history
                WHERE scheme_id = :schemeId AND nav_date BETWEEN :from AND :to
                ORDER BY nav_date
                """, Map.of("schemeId", schemeId, "from", from, "to", to),
                (rs, row) -> new NavPoint(rs.getObject("nav_date", LocalDate.class),
                        rs.getBigDecimal("nav_value")));
    }

    public Optional<NavPoint> latestNav(UUID schemeId) {
        return jdbc.query("""
                SELECT nav_date, nav_value FROM scheme_nav_history
                WHERE scheme_id = :schemeId ORDER BY nav_date DESC LIMIT 1
                """, Map.of("schemeId", schemeId), (rs, row) -> new NavPoint(
                rs.getObject("nav_date", LocalDate.class), rs.getBigDecimal("nav_value")))
                .stream().findFirst();
    }

    public Optional<NavPoint> navOnOrBefore(UUID schemeId, LocalDate date) {
        return jdbc.query("""
                SELECT nav_date, nav_value FROM scheme_nav_history
                WHERE scheme_id = :schemeId AND nav_date <= :date
                ORDER BY nav_date DESC LIMIT 1
                """, Map.of("schemeId", schemeId, "date", date),
                (rs, row) -> new NavPoint(rs.getObject("nav_date", LocalDate.class),
                        rs.getBigDecimal("nav_value"))).stream().findFirst();
    }

    public List<Map<String, Object>> categories() {
        return jdbc.queryForList("""
                SELECT category_code AS code, name, asset_class AS "assetClass"
                FROM scheme_category_master ORDER BY asset_class, name
                """, Map.of());
    }

    public List<Map<String, Object>> amcs() {
        return jdbc.queryForList("""
                SELECT amc_code AS code, name FROM amc_master ORDER BY name
                """, Map.of());
    }

    public Optional<OffsetDateTime> lastImportedAt(UUID schemeId) {
        return jdbc.query("""
                SELECT max(imported_at) AS imported_at FROM scheme_nav_history
                WHERE scheme_id = :schemeId
                """, Map.of("schemeId", schemeId), (rs, row) -> {
            var value = rs.getTimestamp("imported_at");
            return value == null ? null : value.toInstant().atOffset(ZoneOffset.UTC);
        }).stream().filter(java.util.Objects::nonNull).findFirst();
    }

    private String buildWhere(SchemeFilters filters, MapSqlParameterSource params) {
        var clauses = new java.util.ArrayList<String>();
        if (filters.search() != null && !filters.search().isBlank()) {
            params.addValue("search", "%" + filters.search().trim().toLowerCase() + "%");
            clauses.add("""
                    (lower(s.scheme_name) LIKE :search OR lower(s.scheme_code) LIKE :search
                     OR lower(coalesce(s.isin, '')) LIKE :search
                     OR lower(coalesce(s.isin_div_payout_or_growth, '')) LIKE :search
                     OR lower(coalesce(s.isin_div_reinvestment, '')) LIKE :search
                     OR lower(a.name) LIKE :search OR lower(c.name) LIKE :search
                     OR lower(coalesce(s.sub_category, '')) LIKE :search)
                    """);
        }
        addFilter(clauses, params, filters.amcCode(), "a.amc_code", "amcCode");
        addFilter(clauses, params, filters.category(), "c.category_code", "category");
        addInFilter(clauses, params, filters.amcIds(), "a.amc_code", "amcIds");
        addInFilter(clauses, params, filters.categories(),
                "c.category_code", "categories");
        addFilter(clauses, params, filters.subCategory(), "s.sub_category", "subCategory");
        addFilter(clauses, params, filters.riskLevel(), "s.riskometer", "riskLevel");
        addFilter(clauses, params, filters.planType(), "s.plan_type", "planType");
        addFilter(clauses, params, filters.optionType(), "s.option_type", "optionType");
        addFilter(clauses, params, filters.schemeStatus(), "s.scheme_status", "schemeStatus");
        if (filters.minExpenseRatio() != null) {
            clauses.add("s.expense_ratio >= :minExpenseRatio");
            params.addValue("minExpenseRatio", filters.minExpenseRatio());
        }
        if (filters.maxExpenseRatio() != null) {
            clauses.add("s.expense_ratio <= :maxExpenseRatio");
            params.addValue("maxExpenseRatio", filters.maxExpenseRatio());
        }
        return clauses.isEmpty() ? "" : " WHERE " + String.join(" AND ", clauses);
    }

    private void addFilter(List<String> clauses, MapSqlParameterSource params,
                           String value, String column, String name) {
        if (value != null && !value.isBlank()) {
            clauses.add("lower(" + column + ") = lower(:" + name + ")");
            params.addValue(name, value.trim());
        }
    }

    private void addInFilter(List<String> clauses, MapSqlParameterSource params,
                             Collection<String> values, String column, String name) {
        List<String> cleaned = values == null ? List.of() : values.stream()
                .filter(value -> value != null && !value.isBlank())
                .map(String::trim)
                .map(String::toLowerCase)
                .distinct()
                .toList();
        if (!cleaned.isEmpty()) {
            clauses.add("lower(" + column + ") IN (:" + name + ")");
            params.addValue(name, cleaned);
        }
    }

    private String orderBy(Sort sort) {
        Sort.Order order = sort.stream().findFirst().orElse(Sort.Order.asc("schemeName"));
        String column = switch (order.getProperty()) {
            case "latestNavDate" -> "s.latest_nav_date";
            case "expenseRatio" -> "s.expense_ratio";
            case "aum" -> "s.aum";
            case "schemeName" -> "s.scheme_name";
            default -> "s.scheme_name";
        };
        return " ORDER BY " + column + (order.isDescending() ? " DESC" : " ASC")
                + ", s.id ASC";
    }

    private static MutualFundScheme mapScheme(ResultSet rs, int row) throws SQLException {
        return new MutualFundScheme(
                rs.getObject("id", UUID.class),
                rs.getString("scheme_code"),
                rs.getString("isin"),
                rs.getString("isin_div_payout_or_growth"),
                rs.getString("isin_div_reinvestment"),
                rs.getString("scheme_name"),
                rs.getString("amc_code"),
                rs.getString("amc_name"),
                rs.getString("category"),
                rs.getString("category_code"),
                rs.getString("asset_class"),
                rs.getString("sub_category"),
                rs.getString("scheme_type"),
                rs.getString("plan_type"),
                rs.getString("option_type"),
                rs.getString("benchmark_name"),
                rs.getObject("inception_date", LocalDate.class),
                rs.getBigDecimal("current_nav"),
                rs.getObject("latest_nav_date", LocalDate.class),
                rs.getBigDecimal("expense_ratio"),
                rs.getBigDecimal("aum"),
                rs.getString("exit_load"),
                rs.getBigDecimal("minimum_lumpsum"),
                rs.getBigDecimal("minimum_sip"),
                rs.getString("riskometer"),
                rs.getString("investment_objective"),
                rs.getString("scheme_description"),
                rs.getString("fund_manager"),
                rs.getString("scheme_status"),
                rs.getString("provider_code"),
                rs.getBoolean("is_mock"),
                timestamp(rs, "source_updated_at"),
                timestamp(rs, "updated_at"));
    }

    private static OffsetDateTime timestamp(ResultSet rs, String column) throws SQLException {
        var value = rs.getTimestamp(column);
        return value == null ? null : value.toInstant().atOffset(ZoneOffset.UTC);
    }

    public record SchemeFilters(
            String search, String amcCode, List<String> amcIds,
            String category, List<String> categories, String subCategory,
            String riskLevel, String planType, String optionType, String schemeStatus,
            java.math.BigDecimal minExpenseRatio, java.math.BigDecimal maxExpenseRatio) {}
}
