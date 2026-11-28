package com.surgamcapital.mutualfund.application.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.util.List;

public record SchemeSearch(
        String search,
        String amcId,
        String category,
        String subCategory,
        String riskLevel,
        String planType,
        String optionType,
        String schemeStatus,
        BigDecimal minExpenseRatio,
        BigDecimal maxExpenseRatio,
        String sortBy,
        String sortDirection,
        @Min(0) Integer page,
        @Min(1) @Max(100) Integer size,
        @Size(max = 100) List<String> amcIds,
        @Size(max = 200) List<String> categories) {}
