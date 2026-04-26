import { cookies } from "next/headers";
import { ensureDatabase, pool } from "@/lib/db";

const SESSION_COOKIE = "ledgerlens_session";
const TRIAL_DAYS = 7;

function normalizeEmail(email = "") {
  return email.trim().toLowerCase();
}

function ensureTrialWindow(user) {
  if (!user) {
    return user;
  }

  const startedAt = user.trialStartedAt || user.createdAt || new Date().toISOString();
  const endsAt =
    user.trialEndsAt ||
    new Date(new Date(startedAt).getTime() + TRIAL_DAYS * 24 * 60 * 60 * 1000).toISOString();

  return {
    workspaceMembers: [],
    ...user,
    trialStartedAt: startedAt,
    trialEndsAt: endsAt,
    workspaceMembers: Array.isArray(user.workspaceMembers) ? user.workspaceMembers : []
  };
}

function mapUserRow(row, workspaceMembers = []) {
  if (!row) {
    return null;
  }

  return ensureTrialWindow({
    email: row.email,
    name: row.name,
    tier: row.tier,
    billingCycle: row.billing_cycle,
    paymentStatus: row.payment_status,
    razorpayOrderId: row.razorpay_order_id,
    razorpayPaymentId: row.razorpay_payment_id,
    workspaceMembers,
    trialStartedAt: row.trial_started_at?.toISOString?.() || row.trial_started_at,
    trialEndsAt: row.trial_ends_at?.toISOString?.() || row.trial_ends_at,
    createdAt: row.created_at?.toISOString?.() || row.created_at,
    updatedAt: row.updated_at?.toISOString?.() || row.updated_at
  });
}

async function getWorkspaceMembersForEmail(email) {
  const result = await pool.query(
    `
      SELECT member_email
      FROM workspace_members
      WHERE owner_email = $1
      ORDER BY member_email ASC
    `,
    [email]
  );

  return result.rows.map((row) => row.member_email);
}

export async function getUserByEmail(email) {
  const normalizedEmail = normalizeEmail(email);

  if (!normalizedEmail) {
    return null;
  }

  await ensureDatabase();
  const result = await pool.query(
    `
      SELECT *
      FROM users
      WHERE email = $1
      LIMIT 1
    `,
    [normalizedEmail]
  );

  if (result.rowCount === 0) {
    return null;
  }

  const workspaceMembers = await getWorkspaceMembersForEmail(normalizedEmail);
  return mapUserRow(result.rows[0], workspaceMembers);
}

export async function upsertUser({
  email,
  tier = "personal",
  name = "",
  billingCycle = "monthly",
  paymentStatus = "pending",
  razorpayOrderId = "",
  razorpayPaymentId = "",
  workspaceMembers
}) {
  const normalizedEmail = normalizeEmail(email);

  if (!normalizedEmail) {
    throw new Error("Email is required");
  }

  await ensureDatabase();

  const normalizedTier = (tier || "personal").toLowerCase();
  const now = new Date().toISOString();
  const existing = await getUserByEmail(normalizedEmail);
  const trialStartedAt = existing?.trialStartedAt || existing?.createdAt || now;
  const trialEndsAt =
    existing?.trialEndsAt ||
    new Date(new Date(trialStartedAt).getTime() + TRIAL_DAYS * 24 * 60 * 60 * 1000).toISOString();
  const mergedWorkspaceMembers = Array.isArray(workspaceMembers)
    ? workspaceMembers
    : existing?.workspaceMembers || [];

  const saved = await pool.query(
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
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $10)
      ON CONFLICT (email)
      DO UPDATE SET
        name = CASE WHEN EXCLUDED.name <> '' THEN EXCLUDED.name ELSE users.name END,
        tier = EXCLUDED.tier,
        billing_cycle = EXCLUDED.billing_cycle,
        payment_status = EXCLUDED.payment_status,
        razorpay_order_id = CASE
          WHEN EXCLUDED.razorpay_order_id <> '' THEN EXCLUDED.razorpay_order_id
          ELSE users.razorpay_order_id
        END,
        razorpay_payment_id = CASE
          WHEN EXCLUDED.razorpay_payment_id <> '' THEN EXCLUDED.razorpay_payment_id
          ELSE users.razorpay_payment_id
        END,
        trial_started_at = COALESCE(users.trial_started_at, EXCLUDED.trial_started_at),
        trial_ends_at = COALESCE(users.trial_ends_at, EXCLUDED.trial_ends_at),
        updated_at = EXCLUDED.updated_at
      RETURNING *
    `,
    [
      normalizedEmail,
      name.trim(),
      normalizedTier,
      billingCycle,
      paymentStatus,
      razorpayOrderId,
      razorpayPaymentId,
      trialStartedAt,
      trialEndsAt,
      now
    ]
  );

  await pool.query("DELETE FROM workspace_members WHERE owner_email = $1", [normalizedEmail]);

  for (const memberEmail of mergedWorkspaceMembers.map(normalizeEmail).filter(Boolean)) {
    await pool.query(
      `
        INSERT INTO workspace_members (owner_email, member_email)
        VALUES ($1, $2)
        ON CONFLICT (owner_email, member_email) DO NOTHING
      `,
      [normalizedEmail, memberEmail]
    );
  }

  return mapUserRow(saved.rows[0], mergedWorkspaceMembers);
}

export async function getCurrentUser() {
  const cookieStore = await cookies();
  const sessionEmail = cookieStore.get(SESSION_COOKIE)?.value;

  if (!sessionEmail) {
    return null;
  }

  return getUserByEmail(sessionEmail);
}

export async function getCurrentUserFromRequest(request) {
  const headerEmail = normalizeEmail(request?.headers?.get("x-ledgerlens-email") || "");

  if (headerEmail) {
    return getUserByEmail(headerEmail);
  }

  return getCurrentUser();
}

export function getSessionCookieName() {
  return SESSION_COOKIE;
}

export function isTrialActive(user) {
  if (!user || user.paymentStatus === "paid" || !user.trialEndsAt) {
    return false;
  }

  return new Date(user.trialEndsAt) >= new Date();
}

export async function addWorkspaceMember(ownerEmail, memberEmail, maxWorkspaceUsers) {
  const normalizedOwner = normalizeEmail(ownerEmail);
  const normalizedMember = normalizeEmail(memberEmail);

  if (!normalizedOwner || !normalizedMember) {
    throw new Error("Both owner and member email are required");
  }

  if (normalizedOwner === normalizedMember) {
    throw new Error("The account owner is already part of the workspace");
  }

  const owner = await getUserByEmail(normalizedOwner);

  if (!owner) {
    throw new Error("Workspace owner not found");
  }

  const currentMembers = owner.workspaceMembers || [];

  if (currentMembers.includes(normalizedMember)) {
    throw new Error("This member is already in the workspace");
  }

  if (currentMembers.length + 1 >= maxWorkspaceUsers) {
    throw new Error(`This plan supports up to ${maxWorkspaceUsers} users in the workspace`);
  }

  await ensureDatabase();
  await pool.query(
    `
      INSERT INTO workspace_members (owner_email, member_email)
      VALUES ($1, $2)
      ON CONFLICT (owner_email, member_email) DO NOTHING
    `,
    [normalizedOwner, normalizedMember]
  );

  await pool.query("UPDATE users SET updated_at = $2 WHERE email = $1", [
    normalizedOwner,
    new Date().toISOString()
  ]);

  return getUserByEmail(normalizedOwner);
}
