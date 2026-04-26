import { promises as fs } from "node:fs";
import path from "node:path";

const DATA_DIR = path.join(process.cwd(), "data");
const USAGE_FILE = path.join(DATA_DIR, "usage.json");

function currentUsageKey(date = new Date()) {
  return `${date.getUTCFullYear()}-${String(date.getUTCMonth() + 1).padStart(2, "0")}`;
}

async function ensureUsageFile() {
  await fs.mkdir(DATA_DIR, { recursive: true });

  try {
    await fs.access(USAGE_FILE);
  } catch {
    await fs.writeFile(USAGE_FILE, JSON.stringify({ monthly: {}, trial: {} }, null, 2));
  }
}

async function readUsage() {
  await ensureUsageFile();
  const raw = await fs.readFile(USAGE_FILE, "utf8");

  try {
    const parsed = JSON.parse(raw);
    return {
      monthly: parsed.monthly || parsed.usage || {},
      trial: parsed.trial || {}
    };
  } catch {
    return { monthly: {}, trial: {} };
  }
}

async function writeUsage(usage) {
  await ensureUsageFile();
  await fs.writeFile(USAGE_FILE, JSON.stringify(usage, null, 2));
}

export async function getMonthlyUsage(email) {
  if (!email) {
    return 0;
  }

  const usage = await readUsage();
  return usage.monthly[currentUsageKey()]?.[email] ?? 0;
}

export async function addMonthlyUsage(email, pages) {
  if (!email) {
    return 0;
  }

  const usage = await readUsage();
  const periodKey = currentUsageKey();
  const periodUsage = usage.monthly[periodKey] ?? {};
  periodUsage[email] = (periodUsage[email] ?? 0) + pages;
  usage.monthly[periodKey] = periodUsage;
  await writeUsage(usage);
  return periodUsage[email];
}

export async function getTrialUsage(email) {
  if (!email) {
    return { pdfsUsed: 0, pagesUsed: 0 };
  }

  const usage = await readUsage();
  return usage.trial[email] ?? { pdfsUsed: 0, pagesUsed: 0 };
}

export async function addTrialUsage(email, pdfCount, pageCount) {
  if (!email) {
    return { pdfsUsed: 0, pagesUsed: 0 };
  }

  const usage = await readUsage();
  const existing = usage.trial[email] ?? { pdfsUsed: 0, pagesUsed: 0 };
  usage.trial[email] = {
    pdfsUsed: existing.pdfsUsed + pdfCount,
    pagesUsed: existing.pagesUsed + pageCount
  };
  await writeUsage(usage);
  return usage.trial[email];
}
