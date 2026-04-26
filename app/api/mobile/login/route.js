import { NextResponse } from "next/server";
import { getUserByEmail, upsertUser } from "@/lib/auth";
import { buildAccountSummary } from "@/lib/account-summary";
import { getMonthlyUsage, getTrialUsage } from "@/lib/usage";

export async function POST(request) {
  const body = await request.json();
  const email = String(body.email || "").trim().toLowerCase();
  const name = String(body.name || "").trim();

  if (!email) {
    return NextResponse.json({ error: "Email is required." }, { status: 400 });
  }

  const user =
    (await getUserByEmail(email)) ||
    (await upsertUser({
      email,
      name,
      tier: "personal",
      billingCycle: "monthly",
      paymentStatus: "pending"
    }));

  const monthlyPagesUsed = await getMonthlyUsage(user.email);
  const trialUsage = await getTrialUsage(user.email);

  return NextResponse.json(
    buildAccountSummary({
      user,
      monthlyPagesUsed,
      trialUsage
    })
  );
}
