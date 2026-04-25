import { cookies } from "next/headers";
import { NextResponse } from "next/server";
import { getSessionCookieName } from "@/lib/auth";

export async function POST(request) {
  const cookieStore = await cookies();
  cookieStore.delete(getSessionCookieName());

  return NextResponse.redirect(new URL("/", request.url));
}
