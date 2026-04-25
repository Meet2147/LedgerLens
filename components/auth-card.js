import Link from "next/link";
import { getTierBySlug } from "@/lib/pricing";

const tierOptions = [
  { value: "personal", label: "Personal" },
  { value: "professional", label: "Professional" }
];

function formatTitle(mode) {
  return mode === "signup" ? "Create your account" : "Log in with your email";
}

function formatCopy(mode) {
  return mode === "signup"
    ? "Choose a plan and create a lightweight account so we can track which tier you belong to."
    : "This MVP uses email-only login so returning users can recover their saved tier and continue testing.";
}

export function AuthCard({
  mode,
  selectedTier = "personal",
  selectedBilling = "monthly",
  error = "",
  email = ""
}) {
  const isSignup = mode === "signup";
  const selectedPlan = getTierBySlug(selectedTier);

  return (
    <section className="auth-shell">
      <div className="auth-panel">
        <div className="eyebrow">{isSignup ? "Sign up" : "Log in"}</div>
        <h1>{formatTitle(mode)}</h1>
        <p className="hero-copy">{formatCopy(mode)}</p>

        <form
          action={isSignup ? "/api/auth/signup" : "/api/auth/login"}
          className="auth-form"
          method="post"
        >
          <label className="input-group">
            <span>Email address</span>
            <input defaultValue={email} name="email" placeholder="you@example.com" required type="email" />
          </label>

          {isSignup ? (
            <>
              <label className="input-group">
                <span>Name</span>
                <input name="name" placeholder="Optional" type="text" />
              </label>
              <label className="input-group">
                <span>Selected tier</span>
                <select className="tier-select" defaultValue={selectedTier} name="tier">
                  {tierOptions.map((option) => (
                    <option key={option.value} value={option.value}>
                      {option.label}
                    </option>
                  ))}
                </select>
              </label>
              <label className="input-group">
                <span>Billing cycle</span>
                <select className="tier-select" defaultValue={selectedBilling} name="billingCycle">
                  <option value="monthly">Monthly</option>
                  <option value="annual">Annually</option>
                </select>
              </label>
            </>
          ) : null}

          <button className="primary-button" type="submit">
            {isSignup ? "Continue to payment" : "Log in"}
          </button>
        </form>

        {error ? <p className="error-text">{error}</p> : null}

        <p className="auth-switch">
          {isSignup ? "Already registered?" : "Need an account?"}{" "}
          <Link
            href={
              isSignup ? "/login" : `/signup?tier=${selectedTier}&billing=${selectedBilling}`
            }
          >
            {isSignup ? "Log in" : "Sign up"}
          </Link>
        </p>
      </div>

      <div className="auth-panel auth-side">
        <div className="eyebrow">What gets tracked</div>
        <h2>Email, plan, billing, and payment status.</h2>
        <p className="section-copy">
          This first version stores the user email and the selected plan details so billing and
          access can stay in sync after checkout.
        </p>
        <p className="privacy-note">
          We store the account email, plan, billing cycle, and payment status only. Uploaded PDFs
          and parsed transactions are not stored.
        </p>
        <ul className="bullet-list">
          <li>`Personal` for solo users testing occasional conversions</li>
          <li>`Professional` for repeat finance workflows and teams</li>
        </ul>
        <div className="auth-plan-summary">
          <strong>{selectedPlan.name}</strong>
          <span>
            {selectedBilling === "annual" ? selectedPlan.annualPrice : selectedPlan.monthlyPrice}
          </span>
        </div>
      </div>
    </section>
  );
}
