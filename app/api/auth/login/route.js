import { cookies } from "next/headers";
import { NextResponse } from "next/server";
import { getSessionCookieName, getUserByEmail } from "@/lib/auth";
import { buildAbsoluteUrl } from "@/lib/request-url";

export async function POST(request) {
  const formData = await request.formData();
  const email = String(formData.get("email") || "").trim();

  if (!email) {
    return NextResponse.redirect(buildAbsoluteUrl(request, "/login?error=Email+is+required"));
  }

  const user = await getUserByEmail(email);

  if (!user) {
    return NextResponse.redirect(
      buildAbsoluteUrl(
        request,
        `/signup?email=${encodeURIComponent(email)}&error=No+account+found.+Create+one+first`
      )
    );
  }

  const cookieStore = await cookies();
  cookieStore.set(getSessionCookieName(), user.email, {
    httpOnly: true,
    sameSite: "lax",
    path: "/"
  });

  return NextResponse.redirect(buildAbsoluteUrl(request, "/account"));
}
