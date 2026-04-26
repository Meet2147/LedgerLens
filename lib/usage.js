import { ensureDatabase, pool } from "@/lib/db";
import { readUsageStore, writeUsageStore } from "@/lib/local-store";

function currentUsageKey(date = new Date()) {
  return `${date.getUTCFullYear()}-${String(date.getUTCMonth() + 1).padStart(2, "0")}`;
}

async function getLocalUsagePayload() {
  return readUsageStore();
}

export async function getMonthlyUsage(email) {
  if (!email) {
    return 0;
  }

  try {
    await ensureDatabase();
    const result = await pool.query(
      `
        SELECT pages_used
        FROM monthly_usage
        WHERE period_key = $1 AND email = $2
        LIMIT 1
      `,
      [currentUsageKey(), email]
    );

    return result.rows[0]?.pages_used ?? 0;
  } catch (error) {
    console.warn("Falling back to local usage store:", error.message);
    const payload = await getLocalUsagePayload();
    return payload.monthly?.[currentUsageKey()]?.[email] ?? 0;
  }
}

export async function addMonthlyUsage(email, pages) {
  if (!email) {
    return 0;
  }

  try {
    await ensureDatabase();
    const periodKey = currentUsageKey();
    const result = await pool.query(
      `
        INSERT INTO monthly_usage (period_key, email, pages_used, updated_at)
        VALUES ($1, $2, $3, NOW())
        ON CONFLICT (period_key, email)
        DO UPDATE SET
          pages_used = monthly_usage.pages_used + EXCLUDED.pages_used,
          updated_at = NOW()
        RETURNING pages_used
      `,
      [periodKey, email, pages]
    );

    return result.rows[0]?.pages_used ?? 0;
  } catch (error) {
    console.warn("Falling back to local usage store:", error.message);
    const payload = await getLocalUsagePayload();
    const periodKey = currentUsageKey();
    const currentValue = payload.monthly?.[periodKey]?.[email] ?? 0;
    const nextValue = currentValue + pages;
    payload.monthly = payload.monthly || {};
    payload.monthly[periodKey] = payload.monthly[periodKey] || {};
    payload.monthly[periodKey][email] = nextValue;
    await writeUsageStore(payload);
    return nextValue;
  }
}

export async function getTrialUsage(email) {
  if (!email) {
    return { pdfsUsed: 0, pagesUsed: 0 };
  }

  try {
    await ensureDatabase();
    const result = await pool.query(
      `
        SELECT pdfs_used, pages_used
        FROM trial_usage
        WHERE email = $1
        LIMIT 1
      `,
      [email]
    );

    return {
      pdfsUsed: result.rows[0]?.pdfs_used ?? 0,
      pagesUsed: result.rows[0]?.pages_used ?? 0
    };
  } catch (error) {
    console.warn("Falling back to local usage store:", error.message);
    const payload = await getLocalUsagePayload();
    return {
      pdfsUsed: payload.trial?.[email]?.pdfsUsed ?? 0,
      pagesUsed: payload.trial?.[email]?.pagesUsed ?? 0
    };
  }
}

export async function addTrialUsage(email, pdfCount, pageCount) {
  if (!email) {
    return { pdfsUsed: 0, pagesUsed: 0 };
  }

  try {
    await ensureDatabase();
    const result = await pool.query(
      `
        INSERT INTO trial_usage (email, pdfs_used, pages_used, updated_at)
        VALUES ($1, $2, $3, NOW())
        ON CONFLICT (email)
        DO UPDATE SET
          pdfs_used = trial_usage.pdfs_used + EXCLUDED.pdfs_used,
          pages_used = trial_usage.pages_used + EXCLUDED.pages_used,
          updated_at = NOW()
        RETURNING pdfs_used, pages_used
      `,
      [email, pdfCount, pageCount]
    );

    return {
      pdfsUsed: result.rows[0]?.pdfs_used ?? 0,
      pagesUsed: result.rows[0]?.pages_used ?? 0
    };
  } catch (error) {
    console.warn("Falling back to local usage store:", error.message);
    const payload = await getLocalUsagePayload();
    const current = payload.trial?.[email] || { pdfsUsed: 0, pagesUsed: 0 };
    const nextValue = {
      pdfsUsed: current.pdfsUsed + pdfCount,
      pagesUsed: current.pagesUsed + pageCount
    };
    payload.trial = payload.trial || {};
    payload.trial[email] = nextValue;
    await writeUsageStore(payload);
    return nextValue;
  }
}
