import Link from "next/link";
import { BrandMark } from "@/components/brand-mark";

function formatTier(tier = "") {
  if (!tier) {
    return "";
  }

  return tier.charAt(0).toUpperCase() + tier.slice(1);
}

export function SiteHeader({ currentUser }) {
  return (
    <header className="site-header">
      <div className="brand-lockup">
        <Link className="brand brand-row" href="/">
          <BrandMark />
          <span>LedgerLens</span>
        </Link>
        <span className="brand-tag">Bank statements to Excel and CSV</span>
      </div>

      <nav className="nav-links">
        <Link href="/">Home</Link>
        <Link href="/converter">Converter</Link>
        <Link href="/pricing">Pricing</Link>
        {currentUser ? <Link href="/account">Account</Link> : null}
      </nav>

      <div className="account-actions">
        {currentUser ? (
          <>
            <div className="account-chip">
              <strong>{currentUser.email}</strong>
              <span>{formatTier(currentUser.tier)} tier</span>
            </div>
            <form action="/api/auth/logout" method="post">
              <button className="secondary-button" type="submit">
                Log out
              </button>
            </form>
          </>
        ) : (
          <>
            <Link className="secondary-button" href="/login">
              Log in
            </Link>
            <Link className="primary-button" href="/signup">
              Sign up
            </Link>
          </>
        )}
      </div>
    </header>
  );
}
