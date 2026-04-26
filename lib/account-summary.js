import { getTierBySlug } from "@/lib/pricing";

export function buildAccountSummary({ user, monthlyPagesUsed = 0, trialUsage = null }) {
  const tier = getTierBySlug(user?.tier || "personal");
  const isPaid = user?.paymentStatus === "paid";
  const trialEndsAt = user?.trialEndsAt || null;
  const trialStartedAt = user?.trialStartedAt || null;
  const trialActive = Boolean(!isPaid && trialEndsAt && new Date(trialEndsAt) >= new Date());

  return {
    email: user?.email || "",
    name: user?.name || "",
    tier: tier.slug,
    tierName: tier.name,
    billingCycle: user?.billingCycle || "monthly",
    paymentStatus: user?.paymentStatus || "pending",
    workspaceMembers: user?.workspaceMembers || [],
    monthlyPagesUsed,
    monthlyPageLimit: tier.limits.pagesPerMonth,
    exportFormats: tier.limits.exports,
    maxFilesPerUpload: tier.limits.maxFilesPerUpload,
    maxWorkspaceUsers: tier.limits.maxWorkspaceUsers,
    supportLevel: tier.limits.supportLevel,
    processingPriority: tier.limits.processingPriority,
    trial: {
      isActive: trialActive,
      startedAt: trialStartedAt,
      endsAt: trialEndsAt,
      pdfsUsed: trialUsage?.pdfsUsed ?? 0,
      pdfLimit: 5,
      pagesUsed: trialUsage?.pagesUsed ?? 0,
      pageLimit: 50
    }
  };
}
