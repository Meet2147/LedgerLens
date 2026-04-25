"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { pricingTiers } from "@/lib/pricing";

function getDisplayedPrice(tier, billingCycle) {
  return billingCycle === "annual" ? tier.annualPrice : tier.monthlyPrice;
}

function getPeriodLabel(billingCycle) {
  return billingCycle === "annual" ? "/year" : "/month";
}

export function PricingToggleSection() {
  const [billingCycle, setBillingCycle] = useState("monthly");

  const ctaHref = useMemo(
    () => (slug) => `/signup?tier=${slug}&billing=${billingCycle}`,
    [billingCycle]
  );

  return (
    <section className="pricing-shell revamp-shell">
      <div className="pricing-toggle-wrap">
        <div className="eyebrow">Billing</div>
        <div className="billing-toggle" role="tablist" aria-label="Billing cycle">
          <button
            className={billingCycle === "monthly" ? "toggle-chip active" : "toggle-chip"}
            onClick={() => setBillingCycle("monthly")}
            type="button"
          >
            Monthly
          </button>
          <button
            className={billingCycle === "annual" ? "toggle-chip active" : "toggle-chip"}
            onClick={() => setBillingCycle("annual")}
            type="button"
          >
            Annually
          </button>
        </div>
      </div>

      <div className="pricing-grid two-col-grid">
        {pricingTiers.map((tier) => (
          <article className="pricing-card premium-card" key={tier.slug}>
            <div className="pricing-topline">{tier.badge}</div>
            <h3>{tier.name}</h3>
            <p>{tier.description}</p>

            <div className="price-stack">
              <div className="price-line">
                <span>{getDisplayedPrice(tier, billingCycle)}</span>
                <small>{getPeriodLabel(billingCycle)}</small>
              </div>
              <div className="annual-line">
                <strong>{tier.billingNote}</strong>
              </div>
              {billingCycle === "annual" && tier.annualNote ? (
                <div className="discount-pill">{tier.annualNote}</div>
              ) : null}
            </div>

            <ul>
              {tier.features.map((feature) => (
                <li key={feature}>{feature}</li>
              ))}
            </ul>

            <Link className="primary-button" href={ctaHref(tier.slug)}>
              Choose {tier.name}
            </Link>
          </article>
        ))}
      </div>
    </section>
  );
}
