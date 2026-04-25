import { cookies } from "next/headers";
import { NextResponse } from "next/server";
import { getSessionCookieName, upsertUser } from "@/lib/auth";
import { buildAbsoluteUrl } from "@/lib/request-url";

export async function POST(request) {
  const formData = await request.formData();
  const email = String(formData.get("email") || "").trim();
  const name = String(formData.get("name") || "").trim();
  const tier = String(formData.get("tier") || "personal").trim().toLowerCase();
  const billingCycle = String(formData.get("billingCycle") || "monthly").trim().toLowerCase();

  if (!email) {
    return NextResponse.redirect(buildAbsoluteUrl(request, "/signup?error=Email+is+required"));
  }

  const user = await upsertUser({ email, name, tier, billingCycle, paymentStatus: "pending" });
  const cookieStore = await cookies();
  cookieStore.set(getSessionCookieName(), user.email, {
    httpOnly: true,
    sameSite: "lax",
    path: "/"
  });

  return NextResponse.redirect(buildAbsoluteUrl(request, `/checkout?tier=${tier}&billing=${billingCycle}`));
}
