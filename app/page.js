import Link from "next/link";
import { PricingSection } from "@/components/pricing-section";

const productPillars = [
  "Password-protected PDFs supported",
  "Spreadsheet-ready CSV and XLSX exports",
  "Made for finance ops, bookkeepers, and founders",
  "Built to grow into a paid workflow product"
];

export default function HomePage() {
  return (
    <main className="page-shell">
      <section className="hero">
        <div className="hero-grid">
          <div>
            <div className="eyebrow">Micro SaaS for statement conversion</div>
            <h1>Turn messy bank statements into usable spreadsheet data.</h1>
            <p className="hero-copy">
              LedgerLens is a focused finance tool for one painful job: take a bank statement PDF,
              unlock it if needed, and convert it into clean rows your team can review in Excel or
              CSV.
            </p>
            <div className="cta-row">
              <Link className="primary-button" href="/converter">
                Try the converter
              </Link>
              <Link className="secondary-button" href="/pricing">
                See pricing
              </Link>
            </div>
            <div className="feature-list">
              {productPillars.map((feature) => (
                <div className="feature-pill" key={feature}>
                  {feature}
                </div>
              ))}
            </div>
          </div>

          <div className="hero-card">
            <div className="hero-stat">
              <span>What the product does</span>
              <strong>Converts bank statements into tabular data you can actually use</strong>
            </div>
            <div className="hero-stat">
              <span>Why it matters</span>
              <strong>Manual copy-paste from statements is slow, error-prone, and expensive</strong>
            </div>
            <div className="hero-stat">
              <span>Where it grows</span>
              <strong>Batch uploads, team seats, billing, limits, and API access</strong>
            </div>
          </div>
        </div>
      </section>

      <section className="section-block">
        <div className="section-header">
          <div className="eyebrow">Product structure</div>
          <h2>A simpler flow: landing page, converter workspace, pricing, and account tracking.</h2>
          <p className="section-copy">
            The product now separates discovery from usage. The landing page explains the app, the
            converter page handles uploads and previews, the pricing page sells the plans, and the
            account system tracks the user by email and tier.
          </p>
        </div>

        <div className="insight-grid">
          <article className="insight-card">
            <h3>Home page</h3>
            <p>
              A cleaner landing page that explains the problem, the promise, and the next step
              without mixing in the workbench itself.
            </p>
          </article>
          <article className="insight-card">
            <h3>Converter page</h3>
            <p>
              The file upload, password input, parsed preview, and CSV/XLSX export all live in one
              dedicated workspace.
            </p>
          </article>
          <article className="insight-card">
            <h3>User accounts</h3>
            <p>
              Email-based signup and login now store the selected tier so future billing and usage
              controls have a real account record to attach to.
            </p>
          </article>
          <article className="insight-card">
            <h3>Privacy-first processing</h3>
            <p>
              LedgerLens does not store the bank statement PDFs you upload or the transaction data
              extracted from them. Files are processed for conversion and returned as exports only.
            </p>
          </article>
        </div>
      </section>

      <PricingSection />
    </main>
  );
}
