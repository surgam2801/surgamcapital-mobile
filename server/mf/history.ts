// NAV history by AMFI scheme code.
// Source: the free public NAV history service at api.mfapi.in (an open mirror of AMFI data).
// Swap MF_HISTORY_URL for your own AMFI-history importer later; the function signature stays the same.
import type { NavPoint, Returns } from "../../shared/mf/types";
import { computeReturns } from "../../shared/mf/calc";

const HISTORY_URL = process.env.MF_HISTORY_URL ?? "https://api.mfapi.in/mf";
const TTL_MS = 6 * 60 * 60 * 1000;
const MAX_ENTRIES = 600;

const cache = new Map<string, { at: number; series: NavPoint[] }>();

function syntheticSeries(code: string): NavPoint[] {
  // Deterministic random walk for sample schemes (offline / demo only).
  let seed = [...code].reduce((a, c) => a * 31 + c.charCodeAt(0), 7) >>> 0;
  const rand = () => ((seed = (seed * 1664525 + 1013904223) >>> 0) / 2 ** 32);
  const out: NavPoint[] = [];
  const end = new Date();
  let nav = 10 + rand() * 20;
  for (let d = 365 * 6; d >= 0; d--) {
    const day = new Date(end);
    day.setDate(end.getDate() - d);
    if (day.getDay() === 0 || day.getDay() === 6) continue;
    nav *= 1 + (rand() - 0.47) * 0.018;
    out.push({ date: day.toISOString().slice(0, 10), nav: Math.round(nav * 10000) / 10000 });
  }
  return out;
}

// Keep outbound requests to the public history service polite.
const MAX_CONCURRENT = 4;
let active = 0;
const waiters: (() => void)[] = [];
async function acquire() {
  if (active < MAX_CONCURRENT) {
    active++;
    return;
  }
  await new Promise<void>((r) => waiters.push(r));
  active++;
}
function release() {
  active--;
  waiters.shift()?.();
}

const inflight = new Map<string, Promise<NavPoint[]>>();

export async function navHistory(code: string): Promise<NavPoint[]> {
  if (code.startsWith("S")) return syntheticSeries(code);
  const hit = cache.get(code);
  if (hit && Date.now() - hit.at < TTL_MS) return hit.series;
  const pending = inflight.get(code);
  if (pending) return pending;
  const p = fetchHistory(code, hit?.series).finally(() => inflight.delete(code));
  inflight.set(code, p);
  return p;
}

async function fetchHistory(code: string, stale?: NavPoint[]): Promise<NavPoint[]> {
  await acquire();
  try {
    let res: Response | null = null;
    for (let attempt = 0; attempt < 4; attempt++) {
      res = await fetch(`${HISTORY_URL}/${encodeURIComponent(code)}`, { signal: AbortSignal.timeout(20_000) });
      if (res.status !== 429) break;
      await new Promise((r) => setTimeout(r, 1000 * 2 ** attempt)); // back off when rate-limited
    }
    if (!res || !res.ok) throw new Error(`history ${res?.status}`);
    const json = (await res.json()) as { data?: { date: string; nav: string }[] };
    const series = (json.data ?? [])
      .map((p) => {
        const [dd, mm, yyyy] = p.date.split("-");
        return { date: `${yyyy}-${mm}-${dd}`, nav: Number(p.nav) };
      })
      .filter((p) => Number.isFinite(p.nav) && p.nav > 0)
      .sort((a, b) => (a.date < b.date ? -1 : 1));
    if (cache.size >= MAX_ENTRIES) cache.delete(cache.keys().next().value as string);
    cache.set(code, { at: Date.now(), series });
    return series;
  } catch (err) {
    console.warn(`[mf] history for ${code} failed:`, (err as Error).message);
    return stale ?? [];
  } finally {
    release();
  }
}

export function trimRange(series: NavPoint[], range: "1M" | "6M" | "1Y" | "3Y" | "5Y" | "MAX") {
  if (range === "MAX" || series.length === 0) return series;
  const months = { "1M": 1, "6M": 6, "1Y": 12, "3Y": 36, "5Y": 60 }[range];
  const end = new Date(series[series.length - 1].date);
  end.setMonth(end.getMonth() - months);
  const from = end.toISOString().slice(0, 10);
  return series.filter((p) => p.date >= from);
}

/** Thin a long series to at most `max` points for charts. */
export function downsample(series: NavPoint[], max = 240) {
  if (series.length <= max) return series;
  const step = series.length / max;
  const out: NavPoint[] = [];
  for (let i = 0; i < max; i++) out.push(series[Math.floor(i * step)]);
  out[out.length - 1] = series[series.length - 1];
  return out;
}

export async function returnsFor(codes: string[], concurrency = 8): Promise<Returns[]> {
  const out: Returns[] = [];
  let i = 0;
  async function worker() {
    while (i < codes.length) {
      const code = codes[i++];
      const series = await navHistory(code);
      // Ignore histories that stopped updating (merged or wound-up schemes).
      const last = series[series.length - 1];
      const fresh = last && Date.now() - new Date(last.date).getTime() < 15 * 24 * 3600 * 1000;
      out.push(fresh || code.startsWith("S") ? computeReturns(code, series) : { code, r1m: null, r6m: null, r1y: null, r3y: null, r5y: null });
    }
  }
  await Promise.all(Array.from({ length: Math.min(concurrency, codes.length) }, worker));
  return out;
}
