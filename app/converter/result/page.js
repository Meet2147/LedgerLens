import { ConversionResultView } from "@/components/conversion-result-view";
import { getCurrentUser, isTrialActive } from "@/lib/auth";
import { getTierBySlug } from "@/lib/pricing";
import { getMonthlyUsage, getTrialUsage } from "@/lib/usage";

export const metadata = {
  title: "Conversion Results | LedgerLens"
};

export default async function ConversionResultPage() {
  const currentUser = await getCurrentUser();
  const tier = getTierBySlug(currentUser?.tier || "personal");
  const pagesUsed = currentUser ? await getMonthlyUsage(currentUser.email) : 0;
  const trialUsage = currentUser ? await getTrialUsage(currentUser.email) : { pdfsUsed: 0, pagesUsed: 0 };
  const trialActive = currentUser ? isTrialActive(currentUser) : false;
  const capabilities = {
    ...tier.limits,
    tierName: tier.name,
    pagesUsed,
    trial: {
      isActive: trialActive,
      pdfsUsed: trialUsage.pdfsUsed,
      pagesUsed: trialUsage.pagesUsed,
      pdfLimit: 5,
      pageLimit: 50,
      endsAt: currentUser?.trialEndsAt || null
    }
  };

  return <ConversionResultView capabilities={capabilities} currentUser={currentUser} />;
}
