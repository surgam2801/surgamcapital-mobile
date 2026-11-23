import type { CreateExpressContextOptions } from "@trpc/server/adapters/express";
import type { User } from "../../drizzle/schema";
import { sdk } from "./sdk";
import type { Investor } from "../../shared/mf/types";
import { investorFromAuthHeader } from "../mf/auth";

export type TrpcContext = {
  req: CreateExpressContextOptions["req"];
  res: CreateExpressContextOptions["res"];
  user: User | null;
  investor: Investor | null;
};

export async function createContext(opts: CreateExpressContextOptions): Promise<TrpcContext> {
  let user: User | null = null;

  try {
    user = await sdk.authenticateRequest(opts.req);
  } catch (error) {
    // Authentication is optional for public procedures.
    user = null;
  }

  const investor = await investorFromAuthHeader(opts.req.headers.authorization);

  return {
    req: opts.req,
    res: opts.res,
    user,
    investor,
  };
}
