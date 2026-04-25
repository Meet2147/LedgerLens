import { NextResponse } from "next/server";
import { addWorkspaceMember, getCurrentUser } from "@/lib/auth";
import { getTierLimits } from "@/lib/pricing";

export async function POST(request) {
  const currentUser = await getCurrentUser();

  if (!currentUser) {
    return NextResponse.redirect(new URL("/login?error=Please+log+in+first", request.url));
  }

  const formData = await request.formData();
  const memberEmail = String(formData.get("memberEmail") || "").trim();
  const limits = getTierLimits(currentUser.tier);

  try {
    await addWorkspaceMember(currentUser.email, memberEmail, limits.maxWorkspaceUsers);
    return NextResponse.redirect(new URL("/account?workspace=updated", request.url));
  } catch (error) {
    return NextResponse.redirect(
      new URL(`/account?error=${encodeURIComponent(error.message)}`, request.url)
    );
  }
}
