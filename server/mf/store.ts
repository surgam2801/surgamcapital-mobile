// Persistence for investors, orders, SIPs and goals.
// Local default: a JSON file in .data/ so the app runs without a database server.
// Production: implement the same Store interface on MySQL with the Drizzle schema in drizzle/schema.ts.
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import type { Goal, Investor, Order, SipPlan } from "../../shared/mf/types";

type Data = { investors: Investor[]; orders: Order[]; sips: SipPlan[]; goals: Goal[] };

const FILE = path.resolve(process.cwd(), ".data", "store.json");

function load(): Data {
  try {
    return JSON.parse(fs.readFileSync(FILE, "utf8")) as Data;
  } catch {
    return { investors: [], orders: [], sips: [], goals: [] };
  }
}

let data = load();
let writeTimer: NodeJS.Timeout | null = null;

function save() {
  if (writeTimer) return;
  writeTimer = setTimeout(() => {
    writeTimer = null;
    fs.mkdirSync(path.dirname(FILE), { recursive: true });
    const tmp = `${FILE}.tmp`;
    fs.writeFileSync(tmp, JSON.stringify(data, null, 2));
    fs.renameSync(tmp, FILE);
  }, 50);
}

export const newId = (prefix: string) => `${prefix}_${crypto.randomUUID().replace(/-/g, "").slice(0, 16)}`;

export const store = {
  findInvestorByPhone(phone: string) {
    return data.investors.find((i) => i.phone === phone) ?? null;
  },
  getInvestor(id: string) {
    return data.investors.find((i) => i.id === id) ?? null;
  },
  createInvestor(phone: string): Investor {
    const inv: Investor = { id: newId("inv"), phone, createdAt: new Date().toISOString() };
    data.investors.push(inv);
    save();
    return inv;
  },
  updateInvestor(id: string, patch: Partial<Pick<Investor, "name">>) {
    const inv = data.investors.find((i) => i.id === id);
    if (inv) Object.assign(inv, patch);
    save();
    return inv ?? null;
  },

  addOrder(o: Order) {
    data.orders.push(o);
    save();
    return o;
  },
  ordersFor(investorId: string) {
    return data.orders.filter((o) => o.investorId === investorId).sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1));
  },
  updateOrder(id: string, investorId: string, patch: Partial<Order>) {
    const o = data.orders.find((x) => x.id === id && x.investorId === investorId);
    if (o) Object.assign(o, patch);
    save();
    return o ?? null;
  },

  addSip(s: SipPlan) {
    data.sips.push(s);
    save();
    return s;
  },
  sipsFor(investorId: string) {
    return data.sips.filter((s) => s.investorId === investorId);
  },
  updateSip(id: string, investorId: string, patch: Partial<SipPlan>) {
    const s = data.sips.find((x) => x.id === id && x.investorId === investorId);
    if (s) Object.assign(s, patch);
    save();
    return s ?? null;
  },

  addGoal(g: Goal) {
    data.goals.push(g);
    save();
    return g;
  },
  goalsFor(investorId: string) {
    return data.goals.filter((g) => g.investorId === investorId);
  },
  deleteGoal(id: string, investorId: string) {
    const before = data.goals.length;
    data.goals = data.goals.filter((g) => !(g.id === id && g.investorId === investorId));
    save();
    return data.goals.length < before;
  },
};
