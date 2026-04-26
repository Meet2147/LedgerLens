import Link from "next/link";
import { UploadWorkbench } from "@/components/upload-workbench";
import { getCurrentUser, isTrialActive } from "@/lib/auth";
import { getTierBySlug } from "@/lib/pricing";
import { getMonthlyUsage, getTrialUsage } from "@/lib/usage";

export const metadata = {
  title: "Converter | LedgerLens"
};

export default async function ConverterPage() {
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

  return (
    <main className="page-shell">
      <section className="hero compact-hero">
        <div className="section-header">
          <div className="eyebrow">Converter</div>
          <h1>Upload, convert, preview, and export.</h1>
          <p className="hero-copy">
            This is the working conversion workspace. Upload a PDF statement, enter a password if
            it is protected, inspect the preview, then export the result as CSV or XLSX.
          </p>
          <p className="section-copy">
            Privacy note: we do not store your uploaded PDFs or the transaction data parsed from
            them. The file is processed only for conversion.
          </p>
          {currentUser ? (
            <div className="status-banner">
              Signed in as <strong>{currentUser.email}</strong> on the <strong>{currentUser.tier}</strong>{" "}
              tier.{" "}
              {currentUser.paymentStatus === "paid"
                ? `${pagesUsed}/${tier.limits.pagesPerMonth} pages used this month.`
                : `Trial: ${trialUsage.pdfsUsed}/5 PDFs and ${trialUsage.pagesUsed}/50 pages used.`}
            </div>
          ) : (
            <div className="status-banner muted-banner">
              Sign up or log in to start your 7-day trial and sync access across web and mobile.
              <Link href="/signup" className="inline-link">
                Create an account
              </Link>
            </div>
          )}
        </div>
      </section>

      <UploadWorkbench capabilities={capabilities} currentUser={currentUser} />
    </main>
  );
}
