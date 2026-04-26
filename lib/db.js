import { Pool } from "pg";

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error("DATABASE_URL is required. Set it to your Supabase Postgres connection string.");
}

const globalForDb = globalThis;

function createPool() {
  return new Pool({
    connectionString,
    ssl: {
      rejectUnauthorized: false
    }
  });
}

export const pool = globalForDb.__ledgerlensPool || createPool();

if (!globalForDb.__ledgerlensPool) {
  globalForDb.__ledgerlensPool = pool;
}

let initPromise;

export async function ensureDatabase() {
  if (!initPromise) {
    initPromise = initialize();
  }

  return initPromise;
}

async function initialize() {
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
