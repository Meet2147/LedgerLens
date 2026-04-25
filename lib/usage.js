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
    await fs.writeFile(USAGE_FILE, JSON.stringify({ usage: {} }, null, 2));
  }
}

async function readUsage() {
  await ensureUsageFile();
  const raw = await fs.readFile(USAGE_FILE, "utf8");

  try {
    const parsed = JSON.parse(raw);
    return parsed.usage || {};
  } catch {
    return {};
  }
}

async function writeUsage(usage) {
  await ensureUsageFile();
  await fs.writeFile(USAGE_FILE, JSON.stringify({ usage }, null, 2));
}

export async function getMonthlyUsage(email) {
  if (!email) {
    return 0;
  }

  const usage = await readUsage();
  return usage[currentUsageKey()]?.[email] ?? 0;
}

export async function addMonthlyUsage(email, pages) {
  if (!email) {
    return 0;
  }

  const usage = await readUsage();
  const periodKey = currentUsageKey();
  const periodUsage = usage[periodKey] ?? {};
  periodUsage[email] = (periodUsage[email] ?? 0) + pages;
  usage[periodKey] = periodUsage;
  await writeUsage(usage);
  return periodUsage[email];
}
