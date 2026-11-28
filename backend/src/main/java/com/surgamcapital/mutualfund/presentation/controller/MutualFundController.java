package com.surgamcapital.mutualfund.presentation.controller;

import com.surgamcapital.mutualfund.application.dto.MutualFundDtos;
import com.surgamcapital.mutualfund.application.dto.SchemeSearch;
import com.surgamcapital.mutualfund.application.service.MutualFundService;
import com.surgamcapital.mutualfund.presentation.request.CompareSchemesRequest;
import com.surgamcapital.shared.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
public class MutualFundController {
    private final MutualFundService mutualFunds;

    public MutualFundController(MutualFundService mutualFunds) {
        this.mutualFunds = mutualFunds;
    }

    @Operation(summary = "Search mutual fund schemes (authentication required; KYC is not required)")
    @GetMapping("/mutual-funds/schemes")
    public ApiResponse<MutualFundDtos.SchemePage> search(
            @Valid @ModelAttribute SchemeSearch request) {
        return ApiResponse.success("Schemes retrieved.", mutualFunds.search(request));
    }

    @Operation(summary = "Get scheme details and available performance")
    @GetMapping("/mutual-funds/schemes/{schemeId}")
    public ApiResponse<MutualFundDtos.SchemeDetails> details(
            @PathVariable UUID schemeId) {
        return ApiResponse.success("Scheme retrieved.", mutualFunds.details(schemeId));
    }

    @GetMapping("/mutual-funds/categories")
    public ApiResponse<java.util.List<MutualFundDtos.Category>> categories() {
        return ApiResponse.success("Categories retrieved.", mutualFunds.categories());
    }

    @GetMapping("/mutual-funds/amcs")
    public ApiResponse<java.util.List<MutualFundDtos.Amc>> amcs() {
        return ApiResponse.success("AMCs retrieved.", mutualFunds.amcs());
    }

    @GetMapping("/mutual-funds/schemes/{schemeId}/nav-history")
    public ApiResponse<MutualFundDtos.NavHistory> navHistory(
            @PathVariable UUID schemeId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fromDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate toDate,
            @RequestParam(defaultValue = "DAILY") String interval) {
        return ApiResponse.success("NAV history retrieved.",
                mutualFunds.navHistory(schemeId, fromDate, toDate, interval));
    }

    @GetMapping("/mutual-funds/schemes/{schemeId}/performance")
    public ApiResponse<MutualFundDtos.Performance> performance(
            @PathVariable UUID schemeId) {
        return ApiResponse.success("Performance retrieved.", mutualFunds.performance(schemeId));
    }

    @PostMapping("/mutual-funds/schemes/compare")
    public ApiResponse<MutualFundDtos.Comparison> compare(
            @Valid @RequestBody CompareSchemesRequest request) {
        return ApiResponse.success("Scheme comparison retrieved.",
                mutualFunds.compare(request.schemeIds()));
    }

    @GetMapping("/investors/me/watchlist")
    public ApiResponse<MutualFundDtos.Watchlist> watchlist(
            @AuthenticationPrincipal Jwt jwt) {
        return ApiResponse.success("Watchlist retrieved.",
                mutualFunds.watchlist(UUID.fromString(jwt.getSubject())));
    }

    @PostMapping("/investors/me/watchlist/{schemeId}")
    public ApiResponse<java.util.Map<String, Boolean>> addToWatchlist(
            @AuthenticationPrincipal Jwt jwt, @PathVariable UUID schemeId) {
        mutualFunds.addToWatchlist(UUID.fromString(jwt.getSubject()), schemeId);
        return ApiResponse.success("Scheme added to watchlist.",
                java.util.Map.of("saved", true));
    }

    @DeleteMapping("/investors/me/watchlist/{schemeId}")
    public ApiResponse<java.util.Map<String, Boolean>> removeFromWatchlist(
            @AuthenticationPrincipal Jwt jwt, @PathVariable UUID schemeId) {
        mutualFunds.removeFromWatchlist(UUID.fromString(jwt.getSubject()), schemeId);
        return ApiResponse.success("Scheme removed from watchlist.",
                java.util.Map.of("saved", false));
    }
}
