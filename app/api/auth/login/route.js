import { cookies } from "next/headers";
import { NextResponse } from "next/server";
import { getSessionCookieName, getUserByEmail } from "@/lib/auth";

export async function POST(request) {
  const formData = await request.formData();
  const email = String(formData.get("email") || "").trim();

  if (!email) {
    return NextResponse.redirect(new URL("/login?error=Email+is+required", request.url));
  }

  const user = await getUserByEmail(email);

  if (!user) {
    return NextResponse.redirect(
      new URL(`/signup?email=${encodeURIComponent(email)}&error=No+account+found.+Create+one+first`, request.url)
    );
  }

  const cookieStore = await cookies();
  cookieStore.set(getSessionCookieName(), user.email, {
    httpOnly: true,
    sameSite: "lax",
    path: "/"
  });

  return NextResponse.redirect(new URL("/account", request.url));
}
