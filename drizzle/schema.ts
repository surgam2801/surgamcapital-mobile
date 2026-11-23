import {
  boolean,
  decimal,
  int,
  json,
  mysqlEnum,
  mysqlTable,
  text,
  timestamp,
  varchar,
} from "drizzle-orm/mysql-core";
import { relations } from "drizzle-orm";

// ============================================================================
// 1. IDENTITY, USERS & ROLES (FND-01, FND-02, FND-03)
// ============================================================================

export const users = mysqlTable("users", {
  id: int("id").autoincrement().primaryKey(),
  openId: varchar("open_id", { length: 64 }).unique(),
  mobile: varchar("mobile", { length: 15 }).notNull().unique(),
  email: varchar("email", { length: 320 }).unique(),
  name: varchar("name", { length: 255 }),
  role: mysqlEnum("role", [
    "INVESTOR",
    "PARTNER_MFD",
    "PARTNER_STAFF",
    "SURGAM_RM",
    "OPS_EXECUTIVE",
    "COMPLIANCE_OFFICER",
    "PRINCIPAL_OFFICER",
    "FINANCE_CONTROLLER",
    "PLATFORM_ADMIN",
  ]).default("INVESTOR").notNull(),
  status: mysqlEnum("status", ["ACTIVE", "SUSPENDED", "BLOCKED"]).default("ACTIVE").notNull(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().onUpdateNow().notNull(),
  lastSignedIn: timestamp("last_signed_in"),
});

export const familyGroups = mysqlTable("family_groups", {
  id: int("id").autoincrement().primaryKey(),
  primaryInvestorId: int("primary_investor_id").notNull(),
  groupName: varchar("group_name", { length: 100 }).notNull(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

export const partnerProfiles = mysqlTable("partner_profiles", {
  id: int("id").autoincrement().primaryKey(),
  userId: int("user_id").notNull().unique(),
  partnerCode: varchar("partner_code", { length: 32 }).notNull().unique(), // e.g., PTR_MUM_042
  businessName: varchar("business_name", { length: 255 }).notNull(),
  arn: varchar("arn", { length: 32 }).notNull().unique(),
  arnExpiryDate: timestamp("arn_expiry_date").notNull(),
  euin: varchar("euin", { length: 32 }).notNull(),
  nismNumber: varchar("nism_number", { length: 64 }).notNull(),
  nismExpiryDate: timestamp("nism_expiry_date").notNull(),
  modelType: mysqlEnum("model_type", ["MODEL_A", "MODEL_B"]).default("MODEL_A").notNull(), // A: Revenue Share, B: Platform Fee
  revenueSharePct: decimal("revenue_share_pct", { precision: 5, scale: 2 }).default("80.00"),
  platformFeeMonthly: decimal("platform_fee_monthly", { precision: 10, scale: 2 }).default("0.00"),
  foundingPartner: boolean("founding_partner").default(false).notNull(),
  complianceStatus: mysqlEnum("compliance_status", ["PENDING", "APPROVED", "SUSPENDED", "TERMINATED"]).default("PENDING").notNull(),
  complianceApprovedAt: timestamp("compliance_approved_at"),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

export const investorProfiles = mysqlTable("investor_profiles", {
  id: int("id").autoincrement().primaryKey(),
  userId: int("user_id").notNull().unique(),
  familyGroupId: int("family_group_id"),
  channelTag: varchar("channel_tag", { length: 64 }).default("SURGAM_DIRECT").notNull(), // "SURGAM_DIRECT" or partnerCode
  partnerId: int("partner_id"), // Foreign key to partner_profiles.id if partner client
  panNumberEncrypted: varchar("pan_number_encrypted", { length: 255 }).notNull(),
  panNumberMasked: varchar("pan_number_masked", { length: 16 }).notNull(), // e.g. "ABCDE****F"
  kraStatus: mysqlEnum("kra_status", ["VALIDATED", "REGISTERED", "ON_HOLD", "REJECTED", "NOT_CHECKED"]).default("NOT_CHECKED").notNull(),
  dateOfBirth: timestamp("date_of_birth"),
  gender: mysqlEnum("gender", ["MALE", "FEMALE", "OTHER"]),
  taxStatus: mysqlEnum("tax_status", ["RESIDENT_INDIVIDUAL", "NRI", "HUF", "MINOR"]).default("RESIDENT_INDIVIDUAL").notNull(),
  pepFlag: boolean("pep_flag").default(false).notNull(), // Politically Exposed Person
  vulnerableFlag: boolean("vulnerable_flag").default(false).notNull(), // Age > 60 or declared distress
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

// ============================================================================
// 2. COMPLIANCE, VERIFICATION & DPDP (ONB-04, ONB-08, FND-06, CMP-01)
// ============================================================================

export const bankAccounts = mysqlTable("bank_accounts", {
  id: int("id").autoincrement().primaryKey(),
  investorId: int("investor_id").notNull(),
  accountNumberEncrypted: varchar("account_number_encrypted", { length: 255 }).notNull(),
  accountNumberMasked: varchar("account_number_masked", { length: 32 }).notNull(),
  ifscCode: varchar("ifsc_code", { length: 16 }).notNull(),
  bankName: varchar("bank_name", { length: 128 }).notNull(),
  accountType: mysqlEnum("account_type", ["SAVINGS", "CURRENT", "NRE", "NRO"]).default("SAVINGS").notNull(),
  pennyDropStatus: mysqlEnum("penny_drop_status", ["PENDING", "VERIFIED", "FAILED", "MISMATCH"]).default("PENDING").notNull(),
  pennyDropNameMatchScore: decimal("penny_drop_name_match_score", { precision: 5, scale: 2 }),
  isPrimary: boolean("is_primary").default(true).notNull(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

export const nominees = mysqlTable("nominees", {
  id: int("id").autoincrement().primaryKey(),
  investorId: int("investor_id").notNull(),
  name: varchar("name", { length: 255 }).notNull(),
  relationship: varchar("relationship", { length: 64 }).notNull(),
  dateOfBirth: timestamp("date_of_birth").notNull(),
  allocationPct: decimal("allocation_pct", { precision: 5, scale: 2 }).notNull(),
  isMinor: boolean("is_minor").default(false).notNull(),
  guardianName: varchar("guardian_name", { length: 255 }),
  guardianPanMasked: varchar("guardian_pan_masked", { length: 16 }),
  optOutSigned: boolean("opt_out_signed").default(false).notNull(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

export const riskProfiles = mysqlTable("risk_profiles", {
  id: int("id").autoincrement().primaryKey(),
  investorId: int("investor_id").notNull(),
  score: int("score").notNull(), // 1 to 99 (Surgam Risk Number)
  tier: mysqlEnum("tier", ["CONSERVATIVE", "MODERATE", "GROWTH", "AGGRESSIVE"]).notNull(),
  responsesJson: json("responses_json").notNull(),
  version: int("version").default(1).notNull(),
  expiresAt: timestamp("expires_at").notNull(), // 12-month expiry (ONB-08)
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

export const dpdpConsentStore = mysqlTable("dpdp_consent_store", {
  id: int("id").autoincrement().primaryKey(),
  userId: int("user_id").notNull(),
  purpose: varchar("purpose", { length: 128 }).notNull(), // e.g. "PORTFOLIO_ANALYSIS", "MARKETING"
  consentGiven: boolean("consent_given").notNull(),
  version: varchar("version", { length: 16 }).notNull(),
  ipAddress: varchar("ip_address", { length: 45 }),
  userAgent: text("user_agent"),
  withdrawnAt: timestamp("withdrawn_at"),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

// ============================================================================
// 3. MASTER SCHEME & MARKET DATA (TXN-01, HLD-02)
// ============================================================================

export const amcs = mysqlTable("amcs", {
  id: int("id").autoincrement().primaryKey(),
  amcCode: varchar("amc_code", { length: 32 }).notNull().unique(),
  name: varchar("name", { length: 255 }).notNull(),
  rtaType: mysqlEnum("rta_type", ["CAMS", "KFINTECH"]).notNull(),
  active: boolean("active").default(true).notNull(),
});

export const schemes = mysqlTable("schemes", {
  id: int("id").autoincrement().primaryKey(),
  amcId: int("amc_id").notNull(),
  amfiCode: varchar("amfi_code", { length: 32 }).notNull().unique(),
  isin: varchar("isin", { length: 32 }).notNull(),
  schemeName: varchar("scheme_name", { length: 255 }).notNull(),
  category: mysqlEnum("category", ["EQUITY", "DEBT", "HYBRID", "SOLUTION", "OTHER"]).notNull(),
  subCategory: varchar("sub_category", { length: 64 }).notNull(), // e.g. "Large Cap", "ELSS", "Liquid"
  planType: mysqlEnum("plan_type", ["REGULAR"]).default("REGULAR").notNull(), // Distributor distributes Regular only
  optionType: mysqlEnum("option_type", ["GROWTH", "IDCW_PAYOUT", "IDCW_REINVESTMENT"]).notNull(),
  riskometerLevel: int("riskometer_level").notNull(), // 1 to 6
  minLumpsumAmount: decimal("min_lumpsum_amount", { precision: 12, scale: 2 }).notNull(),
  minSipAmount: decimal("min_sip_amount", { precision: 12, scale: 2 }).notNull(),
  cutoffTime: varchar("cutoff_time", { length: 8 }).default("14:00").notNull(), // "14:00" or "12:30"
  exitLoadJson: json("exit_load_json"),
  active: boolean("active").default(true).notNull(),
});

export const navHistory = mysqlTable("nav_history", {
  id: int("id").autoincrement().primaryKey(),
  schemeId: int("scheme_id").notNull(),
  navDate: timestamp("nav_date").notNull(),
  navValue: decimal("nav_value", { precision: 12, scale: 4 }).notNull(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

// ============================================================================
// 4. FOLIOS & HOLDINGS (HLD-01, HLD-03)
// ============================================================================

export const folios = mysqlTable("folios", {
  id: int("id").autoincrement().primaryKey(),
  folioNumber: varchar("folio_number", { length: 64 }).notNull(),
  amcId: int("amc_id").notNull(),
  investorId: int("investor_id").notNull(),
  partnerId: int("partner_id"), // Null for Surgam Direct
  holdingMode: mysqlEnum("holding_mode", ["SINGLE", "JOINT", "ANYONE_SURVIVOR"]).default("SINGLE").notNull(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

export const holdings = mysqlTable("holdings", {
  id: int("id").autoincrement().primaryKey(),
  folioId: int("folio_id").notNull(),
  schemeId: int("scheme_id").notNull(),
  investorId: int("investor_id").notNull(),
  units: decimal("units", { precision: 18, scale: 4 }).default("0.0000").notNull(),
  currentValue: decimal("current_value", { precision: 14, scale: 2 }).default("0.00").notNull(),
  investedValue: decimal("invested_value", { precision: 14, scale: 2 }).default("0.00").notNull(),
  xirr: decimal("xirr", { precision: 6, scale: 2 }),
  lastNav: decimal("last_nav", { precision: 12, scale: 4 }),
  lastSyncedAt: timestamp("last_synced_at").defaultNow().notNull(),
});

// ============================================================================
// 5. TRANSACTIONS & RECURRING PLANS (TXN-02, TXN-03, TXN-04)
// ============================================================================

export const mandates = mysqlTable("mandates", {
  id: int("id").autoincrement().primaryKey(),
  investorId: int("investor_id").notNull(),
  bankAccountId: int("bank_account_id").notNull(),
  mandateType: mysqlEnum("mandate_type", ["UPI_AUTOPAY", "E_NACH"]).notNull(),
  umrn: varchar("umrn", { length: 64 }), // NPCI Mandate identifier
  maxAmount: decimal("max_amount", { precision: 12, scale: 2 }).notNull(),
  startDate: timestamp("start_date").notNull(),
  endDate: timestamp("end_date"),
  status: mysqlEnum("status", ["PENDING", "ACTIVE", "PAUSED", "REJECTED", "CANCELLED"]).default("PENDING").notNull(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

export const orders = mysqlTable("orders", {
  id: int("id").autoincrement().primaryKey(),
  orderNumber: varchar("order_number", { length: 64 }).notNull().unique(),
  exchangeRefId: varchar("exchange_ref_id", { length: 64 }),
  investorId: int("investor_id").notNull(),
  partnerId: int("partner_id"),
  folioId: int("folio_id"),
  schemeId: int("scheme_id").notNull(),
  orderType: mysqlEnum("order_type", [
    "PURCHASE",
    "SIP",
    "REDEMPTION",
    "SWITCH",
    "STP",
    "SWP",
    "CANCELLATION",
  ]).notNull(),
  amount: decimal("amount", { precision: 14, scale: 2 }),
  units: decimal("units", { precision: 18, scale: 4 }),
  approvalStatus: mysqlEnum("approval_status", ["PENDING_APPROVAL", "APPROVED", "REJECTED", "EXPIRED"]).default("PENDING_APPROVAL").notNull(),
  approvedAt: timestamp("approved_at"),
  approvalChannel: mysqlEnum("approval_channel", ["WHATSAPP_OTP", "SMS_OTP", "APP_BIOMETRIC"]),
  suitabilityStatus: mysqlEnum("suitability_status", ["PASSED", "OVERRIDDEN_WITH_CONSENT", "BLOCKED"]).notNull(),
  exchangeStatus: mysqlEnum("exchange_status", [
    "QUEUED",
    "SUBMITTED",
    "ACCEPTED",
    "REJECTED",
    "ALLOTTED",
    "FAILED",
  ]).default("QUEUED").notNull(),
  rejectionReason: text("rejection_reason"),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

export const recurringPlans = mysqlTable("recurring_plans", {
  id: int("id").autoincrement().primaryKey(),
  planType: mysqlEnum("plan_type", ["SIP", "STP", "SWP"]).notNull(),
  investorId: int("investor_id").notNull(),
  partnerId: int("partner_id"),
  folioId: int("folio_id"),
  schemeId: int("scheme_id").notNull(),
  targetSchemeId: int("target_scheme_id"), // For STP
  mandateId: int("mandate_id"),
  frequency: mysqlEnum("frequency", ["MONTHLY", "QUARTERLY"]).default("MONTHLY").notNull(),
  executionDay: int("execution_day").notNull(), // Day of month (e.g. 15)
  amount: decimal("amount", { precision: 12, scale: 2 }).notNull(),
  stepUpPct: decimal("step_up_pct", { precision: 5, scale: 2 }).default("0.00"),
  stepUpFrequencyMonths: int("step_up_frequency_months").default(12),
  nextRunDate: timestamp("next_run_date").notNull(),
  status: mysqlEnum("status", ["ACTIVE", "PAUSED", "STOPPED"]).default("ACTIVE").notNull(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

// Investor goals used by Explore > Goal planning (mirrors the API's Goal type).
export const investmentGoals = mysqlTable("investment_goals", {
  id: int("id").autoincrement().primaryKey(),
  investorId: int("investor_id").notNull(),
  name: varchar("name", { length: 60 }).notNull(),
  kind: varchar("kind", { length: 40 }).notNull(),
  targetToday: decimal("target_today", { precision: 14, scale: 2 }).notNull(),
  years: int("years").notNull(),
  inflationPct: decimal("inflation_pct", { precision: 5, scale: 2 }).notNull(),
  returnPct: decimal("return_pct", { precision: 5, scale: 2 }).notNull(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

// ============================================================================
// 6. SURVEILLANCE, COMPLIANCE & BROKERAGE (CMP-01..07, PAY-01..06)
// ============================================================================

export const complianceAlerts = mysqlTable("compliance_alerts", {
  id: int("id").autoincrement().primaryKey(),
  alertType: mysqlEnum("alert_type", [
    "RISK_MISMATCH",
    "CHURN_SWITCH_UNDER_12M",
    "REDEMPTION_POST_BANK_CHANGE",
    "AML_HIGH_VALUE",
    "PARTNER_REGISTRATION_LAPSE",
    "CHANNEL_CONFLICT_ATTEMPT",
  ]).notNull(),
  severity: mysqlEnum("severity", ["LOW", "MEDIUM", "HIGH", "CRITICAL"]).notNull(),
  investorId: int("investor_id"),
  partnerId: int("partner_id"),
  orderId: int("order_id"),
  detailsJson: json("details_json").notNull(),
  reviewedByUserId: int("reviewed_by_user_id"),
  resolutionNote: text("resolution_note"),
  status: mysqlEnum("status", ["OPEN", "INVESTIGATING", "RESOLVED", "REPORTED_TO_PO"]).default("OPEN").notNull(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

export const partnerPayoutStatements = mysqlTable("partner_payout_statements", {
  id: int("id").autoincrement().primaryKey(),
  partnerId: int("partner_id").notNull(),
  periodMonth: varchar("period_month", { length: 7 }).notNull(), // YYYY-MM
  grossBrokerage: decimal("gross_brokerage", { precision: 14, scale: 2 }).notNull(),
  partnerSharePct: decimal("partner_share_pct", { precision: 5, scale: 2 }).notNull(),
  calculatedPayout: decimal("calculated_payout", { precision: 14, scale: 2 }).notNull(),
  platformFeeDeduction: decimal("platform_fee_deduction", { precision: 10, scale: 2 }).default("0.00"),
  tdsDeducted: decimal("tds_deducted", { precision: 10, scale: 2 }).notNull(),
  gstAmount: decimal("gst_amount", { precision: 10, scale: 2 }).default("0.00"),
  clawbackAdjustments: decimal("clawback_adjustments", { precision: 10, scale: 2 }).default("0.00"),
  netDisbursed: decimal("net_disbursed", { precision: 14, scale: 2 }).notNull(),
  disbursementBankRef: varchar("disbursement_bank_ref", { length: 64 }),
  status: mysqlEnum("status", ["CALCULATED", "DISPUTED", "CHECKED", "DISBURSED"]).default("CALCULATED").notNull(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

export const immutableAuditLogs = mysqlTable("immutable_audit_logs", {
  id: int("id").autoincrement().primaryKey(),
  actorUserId: int("actor_user_id").notNull(),
  actorRole: varchar("actor_role", { length: 32 }).notNull(),
  action: varchar("action", { length: 64 }).notNull(), // "VIEW", "ORDER_INITIATED", "CONSENT_RECORDED", "OVERRIDE"
  entityName: varchar("entity_name", { length: 64 }).notNull(),
  entityId: varchar("entity_id", { length: 64 }).notNull(),
  ipAddress: varchar("ip_address", { length: 45 }),
  userAgent: text("user_agent"),
  stateHash: varchar("state_hash", { length: 128 }).notNull(), // SHA-256 state signature
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

// ============================================================================
// RELATIONAL CONNECTIONS (Relations between Tables)
// ============================================================================

export const usersRelations = relations(users, ({ one, many }) => ({
  investorProfile: one(investorProfiles, { fields: [users.id], references: [investorProfiles.userId] }),
  partnerProfile: one(partnerProfiles, { fields: [users.id], references: [partnerProfiles.userId] }),
  auditLogs: many(immutableAuditLogs),
  consents: many(dpdpConsentStore),
}));

export const partnerProfilesRelations = relations(partnerProfiles, ({ one, many }) => ({
  user: one(users, { fields: [partnerProfiles.userId], references: [users.id] }),
  clients: many(investorProfiles),
  orders: many(orders),
  folios: many(folios),
  payouts: many(partnerPayoutStatements),
}));

export const investorProfilesRelations = relations(investorProfiles, ({ one, many }) => ({
  user: one(users, { fields: [investorProfiles.userId], references: [users.id] }),
  partner: one(partnerProfiles, { fields: [investorProfiles.partnerId], references: [partnerProfiles.id] }),
  familyGroup: one(familyGroups, { fields: [investorProfiles.familyGroupId], references: [familyGroups.id] }),
  bankAccounts: many(bankAccounts),
  nominees: many(nominees),
  riskProfiles: many(riskProfiles),
  folios: many(folios),
  orders: many(orders),
  plans: many(recurringPlans),
}));

export const schemesRelations = relations(schemes, ({ one, many }) => ({
  amc: one(amcs, { fields: [schemes.amcId], references: [amcs.id] }),
  navs: many(navHistory),
  holdings: many(holdings),
  orders: many(orders),
}));

export const foliosRelations = relations(folios, ({ one, many }) => ({
  investor: one(investorProfiles, { fields: [folios.investorId], references: [investorProfiles.id] }),
  partner: one(partnerProfiles, { fields: [folios.partnerId], references: [partnerProfiles.id] }),
  amc: one(amcs, { fields: [folios.amcId], references: [amcs.id] }),
  holdings: many(holdings),
}));

export const ordersRelations = relations(orders, ({ one }) => ({
  investor: one(investorProfiles, { fields: [orders.investorId], references: [investorProfiles.id] }),
  partner: one(partnerProfiles, { fields: [orders.partnerId], references: [partnerProfiles.id] }),
  scheme: one(schemes, { fields: [orders.schemeId], references: [schemes.id] }),
  folio: one(folios, { fields: [orders.folioId], references: [folios.id] }),
}));
