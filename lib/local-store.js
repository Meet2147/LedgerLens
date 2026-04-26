import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";

const DATA_DIR = path.join(process.cwd(), "data");
const USERS_FILE = path.join(DATA_DIR, "users.json");
const USAGE_FILE = path.join(DATA_DIR, "usage.json");

async function readJson(filePath, fallback) {
  try {
    const raw = await readFile(filePath, "utf8");
    return JSON.parse(raw);
  } catch (error) {
    if (error && error.code === "ENOENT") {
      return fallback;
    }

    throw error;
  }
}

async function writeJson(filePath, payload) {
  await mkdir(DATA_DIR, { recursive: true });
  await writeFile(filePath, `${JSON.stringify(payload, null, 2)}\n`, "utf8");
}

export async function readUsersStore() {
  return readJson(USERS_FILE, { users: [] });
}

export async function writeUsersStore(payload) {
  return writeJson(USERS_FILE, payload);
}

export async function readUsageStore() {
  return readJson(USAGE_FILE, { monthly: {}, trial: {} });
}

export async function writeUsageStore(payload) {
  return writeJson(USAGE_FILE, payload);
}
