import { promises as fs } from "node:fs";
import path from "node:path";
import { cookies } from "next/headers";

const SESSION_COOKIE = "ledgerlens_session";
const DATA_DIR = path.join(process.cwd(), "data");
const USERS_FILE = path.join(DATA_DIR, "users.json");
const TRIAL_DAYS = 7;

function normalizeEmail(email = "") {
  return email.trim().toLowerCase();
}

async function ensureUsersFile() {
  await fs.mkdir(DATA_DIR, { recursive: true });

  try {
    await fs.access(USERS_FILE);
  } catch {
    await fs.writeFile(USERS_FILE, JSON.stringify({ users: [] }, null, 2));
  }
}

async function readUsers() {
  await ensureUsersFile();
  const raw = await fs.readFile(USERS_FILE, "utf8");

  try {
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed.users) ? parsed.users : [];
  } catch {
    return [];
  }
}

async function writeUsers(users) {
  await ensureUsersFile();
  await fs.writeFile(USERS_FILE, JSON.stringify({ users }, null, 2));
}

export async function getUserByEmail(email) {
  const normalizedEmail = normalizeEmail(email);

  if (!normalizedEmail) {
    return null;
  }

  const users = await readUsers();
  return users.find((user) => user.email === normalizedEmail) ?? null;
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

  const normalizedTier = (tier || "personal").toLowerCase();
  const users = await readUsers();
  const now = new Date().toISOString();
  const existingIndex = users.findIndex((user) => user.email === normalizedEmail);
  const trialStartedAt =
    existingIndex >= 0 && users[existingIndex].trialStartedAt
      ? users[existingIndex].trialStartedAt
      : now;
  const trialEndsAt =
    existingIndex >= 0 && users[existingIndex].trialEndsAt
      ? users[existingIndex].trialEndsAt
      : new Date(Date.now() + TRIAL_DAYS * 24 * 60 * 60 * 1000).toISOString();
  const nextUser = {
    email: normalizedEmail,
    name: name.trim(),
    tier: normalizedTier,
    billingCycle,
    paymentStatus,
    razorpayOrderId,
    razorpayPaymentId,
    workspaceMembers: Array.isArray(workspaceMembers) ? workspaceMembers : [],
    trialStartedAt,
    trialEndsAt,
    updatedAt: now,
    createdAt: existingIndex >= 0 ? users[existingIndex].createdAt : now
  };

  if (existingIndex >= 0) {
    users[existingIndex] = {
      ...users[existingIndex],
      ...nextUser,
      name: name.trim() || users[existingIndex].name || "",
      razorpayOrderId: razorpayOrderId || users[existingIndex].razorpayOrderId || "",
      razorpayPaymentId: razorpayPaymentId || users[existingIndex].razorpayPaymentId || "",
      workspaceMembers: Array.isArray(workspaceMembers)
        ? workspaceMembers
        : users[existingIndex].workspaceMembers || []
    };
  } else {
    users.push(nextUser);
  }

  await writeUsers(users);
  return existingIndex >= 0 ? users[existingIndex] : nextUser;
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

  const users = await readUsers();
  const ownerIndex = users.findIndex((user) => user.email === normalizedOwner);

  if (ownerIndex < 0) {
    throw new Error("Workspace owner not found");
  }

  const currentMembers = users[ownerIndex].workspaceMembers || [];

  if (currentMembers.includes(normalizedMember)) {
    throw new Error("This member is already in the workspace");
  }

  if (currentMembers.length + 1 >= maxWorkspaceUsers) {
    throw new Error(`This plan supports up to ${maxWorkspaceUsers} users in the workspace`);
  }

  users[ownerIndex] = {
    ...users[ownerIndex],
    workspaceMembers: [...currentMembers, normalizedMember],
    updatedAt: new Date().toISOString()
  };

  await writeUsers(users);
  return users[ownerIndex];
}
