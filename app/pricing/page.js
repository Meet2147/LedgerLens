import { PricingSection } from "@/components/pricing-section";

export default function PricingPage() {
  return (
    <main className="page-shell pricing-page">
      <section className="hero compact-hero">
        <div className="section-header">
          <div className="eyebrow">Pricing</div>
          <h1>Choose the plan, then choose monthly or annual billing.</h1>
          <p className="hero-copy">
            Personal is for solo operators. Professional is for repeat finance workflows and small
            teams. The pricing page now focuses only on your plans in INR, not competitor pricing.
          </p>
          <p className="section-copy">
            Across all plans, uploaded bank statements and parsed transaction data are not stored as
            customer records after conversion.
          </p>
        </div>
      </section>

      <PricingSection showHeader={false} />
    </main>
  );
}
