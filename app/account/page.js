import Link from "next/link";
import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";

export const metadata = {
  title: "Account | LedgerLens"
};

export default async function AccountPage() {
  const currentUser = await getCurrentUser();

  if (!currentUser) {
    redirect("/login?error=Please+log+in+first");
  }

  return (
    <main className="page-shell">
      <section className="hero compact-hero">
        <div className="section-header">
          <div className="eyebrow">Account</div>
          <h1>Your plan and sign-in details.</h1>
          <p className="hero-copy">
            This MVP keeps a simple record of the email address and selected tier so you can start
            layering usage limits and billing later.
          </p>
        </div>

        <div className="account-grid">
          <div className="panel">
            <div className="eyebrow">Email</div>
            <h3>{currentUser.email}</h3>
            <p className="muted">Created {new Date(currentUser.createdAt).toLocaleDateString("en-IN")}</p>
          </div>
          <div className="panel">
            <div className="eyebrow">Tier</div>
            <h3>{currentUser.tier}</h3>
            <p className="muted">Updated {new Date(currentUser.updatedAt).toLocaleDateString("en-IN")}</p>
          </div>
          <div className="panel">
            <div className="eyebrow">Billing</div>
            <h3>{currentUser.billingCycle || "monthly"}</h3>
            <p className="muted">Payment status: {currentUser.paymentStatus || "pending"}</p>
          </div>
        </div>

        <div className="cta-row">
          <Link className="primary-button" href={`/checkout?tier=${currentUser.tier}&billing=${currentUser.billingCycle || "monthly"}`}>
            Open checkout
          </Link>
          <Link className="primary-button" href="/converter">
            Open converter
          </Link>
          <Link className="secondary-button" href="/pricing">
            Compare plans
          </Link>
        </div>
      </section>
    </main>
  );
}
