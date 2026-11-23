import { TRPCError } from "@trpc/server";
import { z } from "zod";
import { middleware, publicProcedure, router } from "../_core/trpc";
import { allSchemes, dataStatus, getScheme } from "./amfi";
import { downsample, navHistory, returnsFor, trimRange } from "./history";
import { devOtpMode, normalisePhone, requestOtp, verifyOtp } from "./auth";
import { newId, store } from "./store";
import { SAMPLE_NFOS, TOP_LISTS, WAYS_TO_INVEST } from "../../shared/mf/content";
import { lumpsumBacktest, sipBacktest } from "../../shared/mf/calc";
import type { BroadCategory, Scheme, SchemeWithReturns } from "../../shared/mf/types";

const investorProcedure = publicProcedure.use(
  middleware(({ ctx, next }) => {
    if (!ctx.investor) throw new TRPCError({ code: "UNAUTHORIZED", message: "Please sign in to continue." });
    return next({ ctx: { ...ctx, investor: ctx.investor } });
  }),
);

const CATEGORIES: BroadCategory[] = ["Equity", "Debt", "Hybrid", "Solution", "Index & ETF", "Other"];
const rangeSchema = z.enum(["1M", "6M", "1Y", "3Y", "5Y", "MAX"]);

function matches(s: Scheme, opts: { categories?: BroadCategory[]; subCategoryIncludes?: string[] }) {
  if (opts.categories && !opts.categories.includes(s.category)) return false;
  if (opts.subCategoryIncludes && !opts.subCategoryIncludes.some((k) => s.subCategory.toLowerCase().includes(k.toLowerCase()))) return false;
  return true;
}

async function withReturns(schemes: Scheme[]): Promise<SchemeWithReturns[]> {
  const rets = await returnsFor(schemes.map((s) => s.code));
  const byCode = new Map(rets.map((r) => [r.code, r]));
  return schemes.map((s) => ({ ...s, returns: byCode.get(s.code) }));
}

/** Large AMCs first keeps on-demand return calculation bounded and the lists relevant. */
function rankByAmcSize(schemes: Scheme[], all: Scheme[]) {
  const amcSize = new Map<string, number>();
  for (const s of all) amcSize.set(s.amc, (amcSize.get(s.amc) ?? 0) + 1);
  return [...schemes].sort((a, b) => (amcSize.get(b.amc) ?? 0) - (amcSize.get(a.amc) ?? 0));
}

function nextRunDate(day: number) {
  const now = new Date();
  const d = new Date(now.getFullYear(), now.getMonth(), day);
  if (d <= now) d.setMonth(d.getMonth() + 1);
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

export const mfRouter = router({
  status: publicProcedure.query(async () => {
    await allSchemes();
    return dataStatus();
  }),

  categories: publicProcedure.query(async () => {
    const all = await allSchemes();
    const map = new Map<string, { category: BroadCategory; subCategory: string; count: number }>();
    for (const s of all) {
      const k = `${s.category}|${s.subCategory}`;
      const e = map.get(k) ?? { category: s.category, subCategory: s.subCategory, count: 0 };
      e.count++;
      map.set(k, e);
    }
    return [...map.values()].sort((a, b) => CATEGORIES.indexOf(a.category) - CATEGORIES.indexOf(b.category) || b.count - a.count);
  }),

  search: publicProcedure
    .input(z.object({ q: z.string().max(80).optional(), category: z.string().optional(), subCategory: z.string().optional(), amc: z.string().optional(), limit: z.number().min(1).max(100).default(30) }))
    .query(async ({ input }) => {
      const all = await allSchemes();
      const terms = (input.q ?? "").toLowerCase().split(/\s+/).filter(Boolean);
      const hits = all.filter(
        (s) =>
          (!input.category || s.category === input.category) &&
          (!input.subCategory || s.subCategory === input.subCategory) &&
          (!input.amc || s.amc === input.amc) &&
          terms.every((t) => s.name.toLowerCase().includes(t) || s.amc.toLowerCase().includes(t)),
      );
      return { total: hits.length, items: rankByAmcSize(hits, all).slice(0, input.limit) };
    }),

  scheme: publicProcedure.input(z.object({ code: z.string() })).query(async ({ input }) => {
    const s = await getScheme(input.code);
    if (!s) throw new TRPCError({ code: "NOT_FOUND", message: "Fund not found" });
    const [ret] = await returnsFor([s.code]);
    return { ...s, returns: ret };
  }),

  history: publicProcedure.input(z.object({ code: z.string(), range: rangeSchema.default("1Y") })).query(async ({ input }) => {
    return downsample(trimRange(await navHistory(input.code), input.range));
  }),

  backtest: publicProcedure
    .input(z.object({ code: z.string(), mode: z.enum(["SIP", "LUMPSUM"]), amount: z.number().min(100).max(1e9), months: z.number().int().min(1).max(240) }))
    .query(async ({ input }) => {
      const series = await navHistory(input.code);
      return input.mode === "SIP" ? sipBacktest(series, input.amount, input.months) : lumpsumBacktest(series, input.amount, input.months);
    }),

  performance: publicProcedure
    .input(z.object({ subCategory: z.string(), limit: z.number().min(5).max(50).default(25) }))
    .query(async ({ input }) => {
      const all = await allSchemes();
      const pool = rankByAmcSize(all.filter((s) => s.subCategory === input.subCategory), all).slice(0, input.limit);
      return withReturns(pool);
    }),

  topList: publicProcedure.input(z.object({ slug: z.string(), limit: z.number().min(3).max(20).default(10) })).query(async ({ input }) => {
    const def = TOP_LISTS.find((t) => t.slug === input.slug);
    if (!def) throw new TRPCError({ code: "NOT_FOUND", message: "List not found" });
    const all = await allSchemes();
    const pool = rankByAmcSize(all.filter((s) => matches(s, def)), all).slice(0, 40);
    const rows = await withReturns(pool);
    return {
      list: def,
      items: rows
        .filter((r) => r.returns?.[def.sortBy] != null)
        .sort((a, b) => (b.returns?.[def.sortBy] ?? -999) - (a.returns?.[def.sortBy] ?? -999))
        .slice(0, input.limit),
    };
  }),

  forWay: publicProcedure.input(z.object({ slug: z.string(), limit: z.number().min(3).max(20).default(8) })).query(async ({ input }) => {
    const way = WAYS_TO_INVEST.find((w) => w.slug === input.slug);
    if (!way) throw new TRPCError({ code: "NOT_FOUND", message: "Not found" });
    const all = await allSchemes();
    const pool = rankByAmcSize(all.filter((s) => matches(s, way.match)), all).slice(0, 24);
    const rows = await withReturns(pool);
    return rows.sort((a, b) => (b.returns?.r3y ?? b.returns?.r1y ?? -999) - (a.returns?.r3y ?? a.returns?.r1y ?? -999)).slice(0, input.limit);
  }),

  industry: publicProcedure.query(async () => {
    const all = await allSchemes();
    const byCategory = CATEGORIES.map((c) => ({ category: c, schemes: all.filter((s) => s.category === c).length })).filter((x) => x.schemes > 0);
    const amcMap = new Map<string, number>();
    for (const s of all) amcMap.set(s.amc, (amcMap.get(s.amc) ?? 0) + 1);
    const amcs = [...amcMap.entries()].map(([amc, schemes]) => ({ amc, schemes })).sort((a, b) => b.schemes - a.schemes);
    const subMap = new Map<string, { subCategory: string; category: BroadCategory; schemes: number }>();
    for (const s of all) {
      const e = subMap.get(s.subCategory) ?? { subCategory: s.subCategory, category: s.category, schemes: 0 };
      e.schemes++;
      subMap.set(s.subCategory, e);
    }
    return { total: all.length, amcCount: amcs.length, byCategory, topAmcs: amcs.slice(0, 15), subCategories: [...subMap.values()].sort((a, b) => b.schemes - a.schemes) };
  }),

  debt: publicProcedure.query(async () => {
    const all = await allSchemes();
    const debt = all.filter((s) => s.category === "Debt");
    const subs = [...new Set(debt.map((s) => s.subCategory))];
    // Median returns from the 4 largest-AMC funds in each debt category.
    const rows = await Promise.all(
      subs.map(async (sub) => {
        const pool = rankByAmcSize(debt.filter((s) => s.subCategory === sub), all).slice(0, 4);
        const rets = (await returnsFor(pool.map((p) => p.code))).filter((r) => r.r1y != null);
        const med = (k: "r1y" | "r3y") => {
          const v = rets.map((r) => r[k]).filter((x): x is number => x != null).sort((a, b) => a - b);
          return v.length ? v[Math.floor(v.length / 2)] : null;
        };
        return { subCategory: sub, schemes: debt.filter((s) => s.subCategory === sub).length, medianR1y: med("r1y"), medianR3y: med("r3y"), sampleSize: rets.length };
      }),
    );
    return rows.sort((a, b) => b.schemes - a.schemes);
  }),

  nfos: publicProcedure.query(() => SAMPLE_NFOS),
});

export const investorAuthRouter = router({
  devMode: publicProcedure.query(() => devOtpMode),
  requestOtp: publicProcedure.input(z.object({ phone: z.string() })).mutation(async ({ input }) => {
    const phone = normalisePhone(input.phone);
    if (!phone) throw new TRPCError({ code: "BAD_REQUEST", message: "Enter a valid 10-digit Indian mobile number." });
    return requestOtp(phone);
  }),
  verifyOtp: publicProcedure.input(z.object({ phone: z.string(), otp: z.string().regex(/^\d{6}$/, { message: "Enter the 6-digit code from the SMS." }) })).mutation(async ({ input }) => {
    const phone = normalisePhone(input.phone);
    if (!phone) throw new TRPCError({ code: "BAD_REQUEST", message: "Enter a valid mobile number." });
    const res = await verifyOtp(phone, input.otp);
    if (!res.ok) throw new TRPCError({ code: "BAD_REQUEST", message: res.reason });
    return { token: res.token, investor: res.investor };
  }),
  me: publicProcedure.query(({ ctx }) => ctx.investor),
  updateName: investorProcedure.input(z.object({ name: z.string().min(1).max(80) })).mutation(({ ctx, input }) => store.updateInvestor(ctx.investor.id, { name: input.name })),
});

export const ordersRouter = router({
  place: investorProcedure
    .input(
      z.object({
        code: z.string(),
        kind: z.enum(["LUMPSUM", "SIP"]),
        amount: z.number({ message: "Enter an amount." }).min(100, { message: "Enter an amount of at least ₹100." }).max(1e8, { message: "For amounts above ₹10 crore, please contact us." }),
        sipDay: z.number().int().min(1).max(28).optional(),
        stepUpPct: z.number().min(0).max(50).default(0),
        // Same key = same order. Protects against double taps and network retries.
        idempotencyKey: z.string().min(8).max(80).optional(),
      }),
    )
    .mutation(async ({ ctx, input }) => {
      if (input.idempotencyKey) {
        const existing = store.findOrderByKey(ctx.investor.id, input.idempotencyKey);
        if (existing) return { order: existing, sip: store.sipsFor(ctx.investor.id).find((x) => x.orderId === existing.id) ?? null, duplicate: true };
      }
      const s = await getScheme(input.code);
      if (!s) throw new TRPCError({ code: "NOT_FOUND", message: "Fund not found" });
      const min = input.kind === "SIP" ? 500 : 1000;
      if (input.amount < min) throw new TRPCError({ code: "BAD_REQUEST", message: `Minimum ${input.kind === "SIP" ? "SIP" : "one-time"} amount is ₹${min}.` });
      const now = new Date().toISOString();
      const order = store.addOrder({
        id: newId("ord"),
        investorId: ctx.investor.id,
        code: s.code,
        schemeName: s.name,
        kind: input.kind,
        amount: input.amount,
        sipDay: input.sipDay,
        status: "PENDING_PAYMENT",
        createdAt: now,
        idempotencyKey: input.idempotencyKey,
      });
      let sip = null;
      if (input.kind === "SIP") {
        const day = input.sipDay ?? 5;
        sip = store.addSip({ id: newId("sip"), investorId: ctx.investor.id, orderId: order.id, code: s.code, schemeName: s.name, amount: input.amount, day, stepUpPct: input.stepUpPct, status: "ACTIVE", nextRun: nextRunDate(day), createdAt: now });
      }
      return { order, sip, duplicate: false };
    }),
  // Simulated payment until a payment gateway / exchange is connected.
  confirmPayment: investorProcedure.input(z.object({ id: z.string() })).mutation(({ ctx, input }) => {
    // Idempotent: paying an order twice never changes it twice.
    const current = store.ordersFor(ctx.investor.id).find((o) => o.id === input.id);
    if (current && current.status !== "PENDING_PAYMENT") return current;
    const o = store.updateOrder(input.id, ctx.investor.id, { status: "SUBMITTED" });
    if (!o) throw new TRPCError({ code: "NOT_FOUND", message: "Order not found" });
    return o;
  }),
  cancel: investorProcedure.input(z.object({ id: z.string() })).mutation(({ ctx, input }) => {
    const o = store.updateOrder(input.id, ctx.investor.id, { status: "CANCELLED" });
    if (!o) throw new TRPCError({ code: "NOT_FOUND", message: "Order not found" });
    return o;
  }),
  list: investorProcedure.query(({ ctx }) => store.ordersFor(ctx.investor.id)),
  sips: investorProcedure.query(({ ctx }) => store.sipsFor(ctx.investor.id)),
  setSipStatus: investorProcedure.input(z.object({ id: z.string(), status: z.enum(["ACTIVE", "PAUSED", "STOPPED"]) })).mutation(({ ctx, input }) => {
    const s = store.updateSip(input.id, ctx.investor.id, { status: input.status });
    if (!s) throw new TRPCError({ code: "NOT_FOUND", message: "SIP not found" });
    return s;
  }),
});

export const goalsRouter = router({
  list: investorProcedure.query(({ ctx }) => store.goalsFor(ctx.investor.id)),
  add: investorProcedure
    .input(z.object({ name: z.string().min(1).max(60), kind: z.string().max(40), targetToday: z.number().min(1000).max(1e10), years: z.number().min(1).max(50), inflationPct: z.number().min(0).max(20), returnPct: z.number().min(0).max(25) }))
    .mutation(({ ctx, input }) => store.addGoal({ id: newId("goal"), investorId: ctx.investor.id, createdAt: new Date().toISOString(), ...input })),
  remove: investorProcedure.input(z.object({ id: z.string() })).mutation(({ ctx, input }) => store.deleteGoal(input.id, ctx.investor.id)),
});
