import { describe, expect, it } from "vitest";
import { computeReturns, formatINR, fvSip, planGoal, planHarvest, sipForTarget } from "../shared/mf/calc";
import { parseNavAll } from "../server/mf/amfi";

describe("SIP maths", () => {
  it("future value of ₹5,000/month for 15 years at 12% is about ₹25 lakh", () => {
    const v = fvSip(5000, 12, 15);
    expect(v).toBeGreaterThan(2_480_000);
    expect(v).toBeLessThan(2_540_000);
  });
  it("sipForTarget inverts fvSip", () => {
    const sip = sipForTarget(1_000_000, 10, 8);
    expect(fvSip(sip, 10, 8)).toBeCloseTo(1_000_000, 0);
  });
  it("goal planner subtracts existing savings", () => {
    const a = planGoal({ years: 10, costToday: 1_000_000, inflationPct: 6, existing: 0, existingReturnPct: 7, newReturnPct: 12, lumpsum: 0 });
    const b = planGoal({ years: 10, costToday: 1_000_000, inflationPct: 6, existing: 300_000, existingReturnPct: 7, newReturnPct: 12, lumpsum: 0 });
    expect(b.monthlySip).toBeLessThan(a.monthlySip);
    expect(a.futureCost).toBeCloseTo(1_790_847.7, 0);
  });
});

describe("returns", () => {
  it("computes 1Y absolute and 3Y CAGR", () => {
    const series = [
      { date: "2023-01-02", nav: 100 },
      { date: "2025-01-02", nav: 120 },
      { date: "2026-01-02", nav: 133.1 },
    ];
    const r = computeReturns("x", series);
    expect(r.r1y).toBeCloseTo(10.92, 1);
    expect(r.r3y).toBeCloseTo(10, 0);
    expect(r.r5y).toBeNull();
  });
});

describe("tax harvest", () => {
  it("never books more than the yearly exemption", () => {
    const p = planHarvest([{ name: "A", units: 10_000, avgCost: 10, nav: 50, heldMonths: 24 }], 25_000);
    expect(p.harvested).toBeCloseTo(100_000, 2);
  });
  it("ignores short-term holdings", () => {
    expect(planHarvest([{ name: "A", units: 100, avgCost: 10, nav: 50, heldMonths: 6 }], 0).harvested).toBe(0);
  });
});

describe("AMFI parser", () => {
  const sample = [
    "Scheme Code;ISIN Div Payout/ ISIN Growth;ISIN Div Reinvestment;Scheme Name;Plan;Option;Net Asset Value;Date",
    "",
    "Open Ended Schemes(Equity Scheme - Large Cap Fund)",
    "",
    "Example Mutual Fund",
    "",
    "1001;INF000A01;-;Example Bluechip Fund;Regular Plan;Growth Option;55.1234;20-Nov-2026",
    "1002;INF000A02;-;Example Bluechip Fund;Direct Plan;Growth Option;60.0000;20-Nov-2026",
    "1003;INF000A03;-;Example Bluechip Fund;Regular Plan;IDCW Option;20.0000;20-Nov-2026",
    "Close Ended Schemes(Debt Scheme - FMP)",
    "2001;INF000B01;-;Example FMP;Regular Plan;Growth Option;11.0000;20-Nov-2026",
  ].join("\n");
  it("keeps only open-ended Regular Growth rows", () => {
    const rows = parseNavAll(sample);
    expect(rows).toHaveLength(1);
    expect(rows[0]).toMatchObject({ code: "1001", amc: "Example", category: "Equity", subCategory: "Large Cap Fund", navDate: "2026-11-20" });
  });
});

describe("formatINR", () => {
  it("uses Indian grouping", () => {
    expect(formatINR(1234567)).toBe("₹12,34,567");
    expect(formatINR(25_00_000, { compact: true })).toBe("₹25.00 L");
  });
});
