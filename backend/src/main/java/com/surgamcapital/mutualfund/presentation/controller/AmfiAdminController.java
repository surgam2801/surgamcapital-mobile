package com.surgamcapital.mutualfund.presentation.controller;

import com.surgamcapital.mutualfund.infrastructure.amfi.AmfiDataSyncService;
import com.surgamcapital.shared.exception.AuthException;
import com.surgamcapital.shared.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.Arrays;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/admin/mutual-funds/amfi")
public class AmfiAdminController {
    private final AmfiDataSyncService sync;
    private final Set<UUID> adminUserIds;

    public AmfiAdminController(
            AmfiDataSyncService sync,
            @Value("${surgam.mutual-fund.amfi.admin-user-ids:}") String configuredIds) {
        this.sync = sync;
        this.adminUserIds = Arrays.stream(configuredIds.split(","))
                .map(String::trim)
                .filter(value -> !value.isEmpty())
                .map(UUID::fromString)
                .collect(Collectors.toUnmodifiableSet());
    }

    @Operation(summary = "Manually refresh the official AMFI NAV report (configured admins only)")
    @PostMapping("/refresh")
    public ApiResponse<AmfiDataSyncService.SyncSummary> refresh(
            @AuthenticationPrincipal Jwt jwt) {
        requireAdmin(jwt);
        return ApiResponse.success("AMFI NAV synchronization completed.",
                sync.synchronizeLatest());
    }

    @Operation(summary = "Backfill official AMFI historical NAV data (configured admins only)")
    @PostMapping("/backfill")
    public ApiResponse<AmfiDataSyncService.BackfillSummary> backfill(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        requireAdmin(jwt);
        return ApiResponse.success("AMFI historical NAV backfill completed.",
                sync.backfill(from, to));
    }

    private void requireAdmin(Jwt jwt) {
        if (jwt == null || adminUserIds.isEmpty()
                || !adminUserIds.contains(UUID.fromString(jwt.getSubject()))) {
            throw new AuthException(HttpStatus.FORBIDDEN, "ADMIN_REQUIRED",
                    "This AMFI operation is restricted to configured administrators.");
        }
    }
}
