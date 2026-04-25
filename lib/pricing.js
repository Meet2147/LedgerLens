export const pricingTiers = [
  {
    name: "Personal",
    slug: "personal",
    monthlyPrice: "INR 1,499",
    annualPrice: "INR 14,999",
    monthlyAmount: 149900,
    annualAmount: 1499900,
    description: "For freelancers and founders cleaning statements a few times per month.",
    badge: "Best for solo users",
    billingNote: "Ideal for solo finance workflows",
    features: [
      "250 pages / month",
      "Optional password for protected PDFs",
      "CSV and XLSX exports",
      "Single file or small batch uploads",
      "Email support"
    ]
  },
  {
    name: "Professional",
    slug: "professional",
    monthlyPrice: "INR 1,999",
    annualPrice: "INR 19,999",
    monthlyAmount: 199900,
    annualAmount: 1999900,
    annualNote: "10% annual discount",
    description: "For bookkeepers, finance teams, and agencies converting statements every week.",
    badge: "Most popular",
    billingNote: "Built for repeat team usage",
    features: [
      "1,500 pages / month",
      "Bulk uploads up to 25 files",
      "CSV, XLSX, and JSON exports",
      "Shared workspace for 3 users",
      "Priority processing queue",
      "Priority support"
    ]
  }
];

export function getTierBySlug(slug = "personal") {
  return pricingTiers.find((tier) => tier.slug === slug) ?? pricingTiers[0];
}

export function getTierAmount(tierSlug, billingCycle = "monthly") {
  const tier = getTierBySlug(tierSlug);

  return billingCycle === "annual" ? tier.annualAmount : tier.monthlyAmount;
}
