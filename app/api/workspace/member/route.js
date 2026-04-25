import { NextResponse } from "next/server";
import { addWorkspaceMember, getCurrentUser } from "@/lib/auth";
import { getTierLimits } from "@/lib/pricing";
import { buildAbsoluteUrl } from "@/lib/request-url";

export async function POST(request) {
  const currentUser = await getCurrentUser();

  if (!currentUser) {
    return NextResponse.redirect(buildAbsoluteUrl(request, "/login?error=Please+log+in+first"));
  }

  const formData = await request.formData();
  const memberEmail = String(formData.get("memberEmail") || "").trim();
  const limits = getTierLimits(currentUser.tier);

  try {
    await addWorkspaceMember(currentUser.email, memberEmail, limits.maxWorkspaceUsers);
    return NextResponse.redirect(buildAbsoluteUrl(request, "/account?workspace=updated"));
  } catch (error) {
    return NextResponse.redirect(
      buildAbsoluteUrl(request, `/account?error=${encodeURIComponent(error.message)}`)
    );
  }
}
