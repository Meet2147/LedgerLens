import Link from "next/link";
import { redirect } from "next/navigation";
import { PaymentLauncher } from "@/components/payment-launcher";
import { getCurrentUser } from "@/lib/auth";
import { getTierBySlug } from "@/lib/pricing";
import { isRazorpayConfigured } from "@/lib/razorpay";

export const metadata = {
  title: "Checkout | LedgerLens"
};

export default async function CheckoutPage({ searchParams }) {
  const currentUser = await getCurrentUser();

  if (!currentUser) {
    redirect("/login?error=Please+log+in+first");
  }

  const params = await searchParams;
  const tier = getTierBySlug((params?.tier || currentUser.tier || "personal").toLowerCase());
  const billingCycle = (params?.billing || currentUser.billingCycle || "monthly").toLowerCase();
  const razorpayReady = isRazorpayConfigured();

  return (
    <main className="page-shell">
      <section className="hero compact-hero">
        <div className="section-header">
          <div className="eyebrow">Checkout</div>
          <h1>Complete payment for your {tier.name} plan.</h1>
          <p className="hero-copy">
            We create a Razorpay order on the server, open Standard Checkout on the client, and
            verify the payment signature before marking the plan active.
          </p>
          <p className="privacy-note">
            Your Razorpay secret is intentionally not stored in source files. Configure it through
            environment variables only.
          </p>
        </div>

        <div className="account-grid">
          <div className="panel">
            <div className="eyebrow">Customer</div>
            <h3>{currentUser.email}</h3>
            <p className="muted">{currentUser.name || "LedgerLens user"}</p>
          </div>
          <div className="panel">
            <div className="eyebrow">Plan</div>
            <h3>
              {tier.name} · {billingCycle}
            </h3>
            <p className="muted">
              {billingCycle === "annual" ? tier.annualPrice : tier.monthlyPrice}
            </p>
          </div>
        </div>

        {razorpayReady ? (
          <PaymentLauncher
            billingCycle={billingCycle}
            email={currentUser.email}
            name={currentUser.name}
            tier={tier.slug}
          />
        ) : (
          <div className="status-banner muted-banner">
            Razorpay keys are not configured yet. Add `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET`
            to your environment, then refresh this page.
          </div>
        )}

        <div className="cta-row">
          <Link className="secondary-button" href="/pricing">
            Back to pricing
          </Link>
          <Link className="secondary-button" href="/account">
            Open account
          </Link>
        </div>
      </section>
    </main>
  );
}
