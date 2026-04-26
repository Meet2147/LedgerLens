import { NextResponse } from "next/server";
import { getDatabaseStatus, isLocalFallbackEnabled, pool } from "@/lib/db";

async function getTableCounts() {
  const statements = [
    { key: "users", table: "users" },
    { key: "workspaceMembers", table: "workspace_members" },
    { key: "monthlyUsage", table: "monthly_usage" },
    { key: "trialUsage", table: "trial_usage" }
  ];

  const counts = {};

  for (const statement of statements) {
    const result = await pool.query(`SELECT COUNT(*)::int AS count FROM ${statement.table}`);
    counts[statement.key] = result.rows[0]?.count ?? 0;
  }

  return counts;
}

export async function GET() {
  const status = await getDatabaseStatus();

  if (!status.ok) {
    return NextResponse.json(
      {
        ...status,
        fallbackEnabled: isLocalFallbackEnabled()
      },
      { status: 500 }
    );
  }

  const counts = await getTableCounts();

  return NextResponse.json({
    ...status,
    fallbackEnabled: isLocalFallbackEnabled(),
    counts
  });
}
