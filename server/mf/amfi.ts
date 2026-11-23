// Scheme master + latest NAV from AMFI's public daily NAV file.
// Source: https://www.amfiindia.com/spages/NAVAll.txt (published by AMFI for public use).
import fs from "node:fs";
import path from "node:path";
import type { BroadCategory, DataStatus, Scheme } from "../../shared/mf/types";
import { SAMPLE_SCHEMES } from "../../shared/mf/content";

const AMFI_URL = process.env.AMFI_NAV_URL ?? "https://www.amfiindia.com/spages/NAVAll.txt";
const CACHE_DIR = path.resolve(process.cwd(), ".data");
const CACHE_FILE = path.join(CACHE_DIR, "amfi-navall.txt");
const REFRESH_MS = 6 * 60 * 60 * 1000;

const MONTHS: Record<string, string> = {
  Jan: "01", Feb: "02", Mar: "03", Apr: "04", May: "05", Jun: "06",
  Jul: "07", Aug: "08", Sep: "09", Oct: "10", Nov: "11", Dec: "12",
};

function toIso(d: string) {
  // 20-Nov-2026 -> 2026-11-20
  const [dd, mon, yyyy] = d.trim().split("-");
  return `${yyyy}-${MONTHS[mon] ?? "01"}-${dd.padStart(2, "0")}`;
}

export function broadCategory(header: string): { category: BroadCategory; subCategory: string } {
  // e.g. "Equity Scheme - Large Cap Fund", "Debt Scheme - Liquid Fund", "Other Scheme - Index Funds"
  const [group, sub = group] = header.split(" - ").map((s) => s.trim());
  const g = group.toLowerCase();
  const s = sub.toLowerCase();
  let category: BroadCategory = "Other";
  if (g.includes("equity")) category = "Equity";
  else if (g.includes("debt") || g.includes("income")) category = "Debt";
  else if (g.includes("hybrid")) category = "Hybrid";
  else if (g.includes("solution") || g.includes("children") || g.includes("retirement")) category = "Solution";
  else if (s.includes("index") || s.includes("etf")) category = "Index & ETF";
  return { category, subCategory: sub.replace(/[^\x20-\x7E]/g, "'") };
}

export function parseNavAll(text: string): Scheme[] {
  const out: Scheme[] = [];
  let header = "";
  let amc = "";
  let openEnded = false;
  for (const raw of text.split(/\r?\n/)) {
    const line = raw.trim();
    if (!line || line.startsWith("Scheme Code")) continue;
    if (!line.includes(";")) {
      const m = line.match(/^(Open Ended|Close Ended|Interval Fund)[^(]*\((.*)\)\s*$/i);
      if (m) {
        openEnded = /open ended/i.test(m[1]);
        header = m[2];
      } else {
        amc = line;
      }
      continue;
    }
    if (!openEnded) continue;
    const cols = line.split(";");
    let code: string, isin: string, name: string, plan = "", option = "", navStr: string, date: string;
    if (cols.length >= 8) {
      [code, isin, , name, plan, option, navStr, date] = cols;
    } else if (cols.length === 6) {
      [code, isin, , name, navStr, date] = cols;
    } else continue;
    const nav = Number(navStr);
    if (!Number.isFinite(nav) || nav <= 0) continue;
    const label = `${name} ${plan} ${option}`;
    // One row per fund: Regular plan, Growth option (Surgam distributes Regular plans).
    if (/direct/i.test(label)) continue;
    if (/idcw|dividend|bonus/i.test(label)) continue;
    const { category, subCategory } = broadCategory(header);
    const displayName = plan || option ? `${name.trim()}${plan ? ` - ${plan.trim()}` : ""}${option ? ` - ${option.replace(/ Option$/i, "").trim()}` : ""}` : name.trim();
    out.push({
      code: code.trim(),
      name: displayName,
      amc: amc.replace(/ Mutual Fund$/i, "").trim(),
      category,
      subCategory,
      isin: isin && isin !== "-" ? isin.trim() : undefined,
      nav,
      navDate: toIso(date),
    });
  }
  return out;
}

type State = { schemes: Scheme[]; byCode: Map<string, Scheme>; status: DataStatus; loadedAt: number };

let state: State = makeState(SAMPLE_SCHEMES, { source: "sample", schemes: SAMPLE_SCHEMES.length, lastRefreshed: null, message: "Live data not loaded yet" });
let inflight: Promise<void> | null = null;

function makeState(schemes: Scheme[], status: DataStatus): State {
  return { schemes, byCode: new Map(schemes.map((s) => [s.code, s])), status, loadedAt: Date.now() };
}

async function fetchText(): Promise<string> {
  const res = await fetch(AMFI_URL, { signal: AbortSignal.timeout(30_000) });
  if (!res.ok) throw new Error(`AMFI responded ${res.status}`);
  return res.text();
}

async function refresh() {
  try {
    const text = await fetchText();
    const schemes = parseNavAll(text);
    if (schemes.length < 100) throw new Error("AMFI file looked incomplete");
    fs.mkdirSync(CACHE_DIR, { recursive: true });
    fs.writeFileSync(CACHE_FILE, text);
    state = makeState(schemes, { source: "amfi", schemes: schemes.length, lastRefreshed: new Date().toISOString() });
    console.log(`[mf] loaded ${schemes.length} schemes from AMFI`);
  } catch (err) {
    // Fall back to the last good file on disk, then to sample data.
    if (fs.existsSync(CACHE_FILE)) {
      const schemes = parseNavAll(fs.readFileSync(CACHE_FILE, "utf8"));
      const when = fs.statSync(CACHE_FILE).mtime.toISOString();
      state = makeState(schemes, { source: "amfi", schemes: schemes.length, lastRefreshed: when, message: "Using cached AMFI file" });
    } else {
      state = makeState(SAMPLE_SCHEMES, { source: "sample", schemes: SAMPLE_SCHEMES.length, lastRefreshed: null, message: "AMFI unreachable, showing sample funds" });
    }
    console.warn("[mf] AMFI refresh failed:", (err as Error).message);
  }
}

let lastAttempt = 0;
const RETRY_MS = 10 * 60 * 1000;

export async function ensureLoaded() {
  if (inflight) return inflight;
  const wait = state.status.source === "sample" ? RETRY_MS : REFRESH_MS;
  if (lastAttempt && Date.now() - lastAttempt < wait) return;
  lastAttempt = Date.now();
  inflight = refresh().finally(() => {
    inflight = null;
  });
  return inflight;
}

export async function allSchemes() {
  await ensureLoaded();
  return state.schemes;
}

export async function getScheme(code: string) {
  await ensureLoaded();
  return state.byCode.get(code) ?? null;
}

export function dataStatus() {
  return state.status;
}
