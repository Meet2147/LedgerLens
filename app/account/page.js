import Link from "next/link";
import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";
import { getTierBySlug } from "@/lib/pricing";
import { getMonthlyUsage } from "@/lib/usage";

export const metadata = {
  title: "Account | LedgerLens"
};

export default async function AccountPage({ searchParams }) {
  const currentUser = await getCurrentUser();
  const params = await searchParams;

  if (!currentUser) {
    redirect("/login?error=Please+log+in+first");
  }

  const tier = getTierBySlug(currentUser.tier);
  const pagesUsed = await getMonthlyUsage(currentUser.email);
  const workspaceMembers = currentUser.workspaceMembers || [];
  const workspaceSeatsRemaining = Math.max(0, tier.limits.maxWorkspaceUsers - 1 - workspaceMembers.length);

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
          {params?.error ? <p className="error-text">{params.error}</p> : null}
          {params?.workspace === "updated" ? (
            <p className="success-text">Workspace member added successfully.</p>
          ) : null}
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
          <div className="panel">
            <div className="eyebrow">Usage</div>
            <h3>
              {pagesUsed} / {tier.limits.pagesPerMonth} pages
            </h3>
            <p className="muted">
              {tier.limits.maxFilesPerUpload} file{tier.limits.maxFilesPerUpload === 1 ? "" : "s"} per upload ·{" "}
              {tier.limits.processingPriority} processing
            </p>
          </div>
          <div className="panel">
            <div className="eyebrow">Exports & Support</div>
            <h3>{tier.limits.exports.join(", ").toUpperCase()}</h3>
            <p className="muted">{tier.limits.supportLevel}</p>
          </div>
          <div className="panel">
            <div className="eyebrow">Workspace</div>
            <h3>{tier.limits.maxWorkspaceUsers} user plan</h3>
            <p className="muted">{workspaceSeatsRemaining} seat(s) remaining</p>
            <div className="workspace-member-list">
              <span className="workspace-member">Owner: {currentUser.email}</span>
              {workspaceMembers.map((member) => (
                <span className="workspace-member" key={member}>
                  Member: {member}
                </span>
              ))}
            </div>
            {tier.limits.maxWorkspaceUsers > 1 ? (
              <form action="/api/workspace/member" className="workspace-form" method="post">
                <label className="input-group">
                  <span>Add workspace member</span>
                  <input name="memberEmail" placeholder="member@example.com" type="email" />
                </label>
                <button className="secondary-button" type="submit">
                  Add member
                </button>
              </form>
            ) : (
              <p className="muted">Upgrade to Professional to unlock a shared workspace for 3 users.</p>
            )}
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
