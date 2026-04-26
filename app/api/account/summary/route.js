import { NextResponse } from "next/server";
import { getCurrentUserFromRequest } from "@/lib/auth";
import { buildAccountSummary } from "@/lib/account-summary";
import { getMonthlyUsage, getTrialUsage } from "@/lib/usage";

export async function GET(request) {
  const currentUser = await getCurrentUserFromRequest(request);

  if (!currentUser) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const monthlyPagesUsed = await getMonthlyUsage(currentUser.email);
  const trialUsage = await getTrialUsage(currentUser.email);

  return NextResponse.json(
    buildAccountSummary({
      user: currentUser,
      monthlyPagesUsed,
      trialUsage
    })
  );
}
