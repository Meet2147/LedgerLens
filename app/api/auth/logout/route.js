import { cookies } from "next/headers";
import { NextResponse } from "next/server";
import { getSessionCookieName } from "@/lib/auth";
import { buildAbsoluteUrl } from "@/lib/request-url";

export async function POST(request) {
  const cookieStore = await cookies();
  cookieStore.delete(getSessionCookieName());

  return NextResponse.redirect(buildAbsoluteUrl(request, "/"));
}
