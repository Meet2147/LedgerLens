import { promises as fs } from "node:fs";
import path from "node:path";
import pg from "pg";

const { Pool } = pg;
let pool;

const ROOT = process.cwd();
const USERS_FILE = path.join(ROOT, "data", "users.json");
const USAGE_FILE = path.join(ROOT, "data", "usage.json");
const TRIAL_DAYS = 7;

async function loadLocalEnv() {
  const envPath = path.join(ROOT, ".env.local");

  try {
    const raw = await fs.readFile(envPath, "utf8");

    for (const line of raw.split(/\r?\n/)) {
      const trimmed = line.trim();

      if (!trimmed || trimmed.startsWith("#")) {
        continue;
      }

      const separatorIndex = trimmed.indexOf("=");

      if (separatorIndex === -1) {
        continue;
      }

      const key = trimmed.slice(0, separatorIndex).trim();
      const value = trimmed.slice(separatorIndex + 1).trim().replace(/^"(.*)"$/, "$1");

      if (!process.env[key]) {
        process.env[key] = value;
      }
    }
  } catch {
    // Ignore missing local env file.
  }
}

function normalizeEmail(email = "") {
  return email.trim().toLowerCase();
}

async function readJson(filePath, fallback) {
  try {
    const raw = await fs.readFile(filePath, "utf8");
    return JSON.parse(raw);
  } catch {
    return fallback;
  }
}

async function ensureDatabase() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS users (
      email TEXT PRIMARY KEY,
      name TEXT NOT NULL DEFAULT '',
      tier TEXT NOT NULL DEFAULT 'personal',
      billing_cycle TEXT NOT NULL DEFAULT 'monthly',
      payment_status TEXT NOT NULL DEFAULT 'pending',
      razorpay_order_id TEXT NOT NULL DEFAULT '',
      razorpay_payment_id TEXT NOT NULL DEFAULT '',
      trial_started_at TIMESTAMPTZ NOT NULL,
      trial_ends_at TIMESTAMPTZ NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS workspace_members (
      owner_email TEXT NOT NULL REFERENCES users(email) ON DELETE CASCADE,
      member_email TEXT NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      PRIMARY KEY (owner_email, member_email)
    );
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS monthly_usage (
      period_key TEXT NOT NULL,
      email TEXT NOT NULL REFERENCES users(email) ON DELETE CASCADE,
      pages_used INTEGER NOT NULL DEFAULT 0,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      PRIMARY KEY (period_key, email)
    );
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS trial_usage (
      email TEXT PRIMARY KEY REFERENCES users(email) ON DELETE CASCADE,
      pdfs_used INTEGER NOT NULL DEFAULT 0,
      pages_used INTEGER NOT NULL DEFAULT 0,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);
}

async function migrateUsers() {
  const payload = await readJson(USERS_FILE, { users: [] });
  const users = Array.isArray(payload.users) ? payload.users : [];

  for (const user of users) {
    const email = normalizeEmail(user.email);

    if (!email) {
      continue;
    }

    const createdAt = user.createdAt || new Date().toISOString();
    const trialStartedAt = user.trialStartedAt || createdAt;
    const trialEndsAt =
      user.trialEndsAt ||
      new Date(new Date(trialStartedAt).getTime() + TRIAL_DAYS * 24 * 60 * 60 * 1000).toISOString();

    await pool.query(
      `
        INSERT INTO users (
          email,
          name,
          tier,
          billing_cycle,
          payment_status,
          razorpay_order_id,
          razorpay_payment_id,
          trial_started_at,
          trial_ends_at,
          created_at,
          updated_at
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
        ON CONFLICT (email)
        DO UPDATE SET
          name = EXCLUDED.name,
          tier = EXCLUDED.tier,
          billing_cycle = EXCLUDED.billing_cycle,
          payment_status = EXCLUDED.payment_status,
          razorpay_order_id = EXCLUDED.razorpay_order_id,
          razorpay_payment_id = EXCLUDED.razorpay_payment_id,
          trial_started_at = EXCLUDED.trial_started_at,
          trial_ends_at = EXCLUDED.trial_ends_at,
          updated_at = EXCLUDED.updated_at
      `,
      [
        email,
        user.name || "",
        user.tier || "personal",
        user.billingCycle || "monthly",
        user.paymentStatus || "pending",
        user.razorpayOrderId || "",
        user.razorpayPaymentId || "",
        trialStartedAt,
        trialEndsAt,
        createdAt,
        user.updatedAt || createdAt
      ]
    );

    const members = Array.isArray(user.workspaceMembers) ? user.workspaceMembers : [];

    for (const memberEmail of members.map(normalizeEmail).filter(Boolean)) {
      await pool.query(
        `
          INSERT INTO workspace_members (owner_email, member_email)
          VALUES ($1, $2)
          ON CONFLICT (owner_email, member_email) DO NOTHING
        `,
        [email, memberEmail]
      );
    }
  }
}

async function migrateUsage() {
  const payload = await readJson(USAGE_FILE, { monthly: {}, trial: {} });
  const monthly = payload.monthly || payload.usage || {};
  const trial = payload.trial || {};

  for (const [periodKey, emails] of Object.entries(monthly)) {
    for (const [email, pagesUsed] of Object.entries(emails || {})) {
      const normalizedEmail = normalizeEmail(email);

      if (!normalizedEmail) {
        continue;
      }

      await pool.query(
        `
          INSERT INTO monthly_usage (period_key, email, pages_used, updated_at)
          VALUES ($1, $2, $3, NOW())
          ON CONFLICT (period_key, email)
          DO UPDATE SET
            pages_used = EXCLUDED.pages_used,
            updated_at = NOW()
        `,
        [periodKey, normalizedEmail, Number(pagesUsed) || 0]
      );
    }
  }

  for (const [email, usage] of Object.entries(trial)) {
    const normalizedEmail = normalizeEmail(email);

    if (!normalizedEmail) {
      continue;
    }

    await pool.query(
      `
        INSERT INTO trial_usage (email, pdfs_used, pages_used, updated_at)
        VALUES ($1, $2, $3, NOW())
        ON CONFLICT (email)
        DO UPDATE SET
          pdfs_used = EXCLUDED.pdfs_used,
          pages_used = EXCLUDED.pages_used,
          updated_at = NOW()
      `,
      [normalizedEmail, Number(usage?.pdfsUsed) || 0, Number(usage?.pagesUsed) || 0]
    );
  }
}

await loadLocalEnv();

if (!process.env.DATABASE_URL) {
  throw new Error("DATABASE_URL is required to migrate JSON data into Supabase.");
}

pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false
  }
});

await ensureDatabase();
await migrateUsers();
await migrateUsage();
await pool.end();

console.log("Supabase migration completed.");
