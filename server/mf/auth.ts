// Phone + OTP sign-in for investors, with a signed bearer token.
// Without an SMS provider configured (SMS_PROVIDER unset), the server runs in dev mode and
// returns the OTP in the response so the flow can be tested locally. Never ship that to production.
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { SignJWT, jwtVerify } from "jose";
import { store } from "./store";

const OTP_TTL_MS = 5 * 60 * 1000;
const RESEND_MS = 30 * 1000;
const MAX_ATTEMPTS = 5;

type Pending = { hash: string; expires: number; sentAt: number; attempts: number };
const pending = new Map<string, Pending>();

export const devOtpMode = !process.env.SMS_PROVIDER;

function secretKey() {
  let secret = process.env.INVESTOR_JWT_SECRET;
  if (!secret) {
    const file = path.resolve(process.cwd(), ".data", "dev-jwt-secret");
    try {
      secret = fs.readFileSync(file, "utf8").trim();
    } catch {
      secret = crypto.randomBytes(32).toString("hex");
      fs.mkdirSync(path.dirname(file), { recursive: true });
      fs.writeFileSync(file, secret);
    }
  }
  return new TextEncoder().encode(secret);
}
const KEY = secretKey();

const hash = (phone: string, otp: string) => crypto.createHash("sha256").update(`${phone}:${otp}`).digest("hex");

export function normalisePhone(input: string) {
  const digits = input.replace(/\D/g, "").replace(/^91(?=\d{10}$)/, "");
  return /^[6-9]\d{9}$/.test(digits) ? digits : null;
}

export async function requestOtp(phone: string) {
  const prev = pending.get(phone);
  if (prev && Date.now() - prev.sentAt < RESEND_MS) {
    return { ok: false as const, retryInSec: Math.ceil((RESEND_MS - (Date.now() - prev.sentAt)) / 1000) };
  }
  const otp = crypto.randomInt(0, 1_000_000).toString().padStart(6, "0");
  pending.set(phone, { hash: hash(phone, otp), expires: Date.now() + OTP_TTL_MS, sentAt: Date.now(), attempts: 0 });
  if (!devOtpMode) {
    // TODO: send via the configured SMS/WhatsApp provider.
    console.log(`[auth] OTP requested for ******${phone.slice(-4)}`);
  }
  return { ok: true as const, devOtp: devOtpMode ? otp : undefined };
}

export async function verifyOtp(phone: string, otp: string) {
  const p = pending.get(phone);
  if (!p || Date.now() > p.expires) return { ok: false as const, reason: "The code has expired. Ask for a new one." };
  p.attempts += 1;
  if (p.attempts > MAX_ATTEMPTS) {
    pending.delete(phone);
    return { ok: false as const, reason: "Too many tries. Ask for a new code." };
  }
  if (p.hash !== hash(phone, otp.trim())) return { ok: false as const, reason: "That code does not match." };
  pending.delete(phone);
  const investor = store.findInvestorByPhone(phone) ?? store.createInvestor(phone);
  const token = await new SignJWT({ sub: investor.id, typ: "investor" })
    .setProtectedHeader({ alg: "HS256" })
    .setIssuedAt()
    .setExpirationTime("30d")
    .sign(KEY);
  return { ok: true as const, token, investor };
}

export async function investorFromAuthHeader(header: string | undefined) {
  if (!header?.startsWith("Bearer ")) return null;
  try {
    const { payload } = await jwtVerify(header.slice(7), KEY);
    if (payload.typ !== "investor" || typeof payload.sub !== "string") return null;
    return store.getInvestor(payload.sub);
  } catch {
    return null;
  }
}
