export const pricingTiers = [
  {
    name: "Personal",
    slug: "personal",
    monthlyPrice: "INR 1,499",
    annualPrice: "INR 13,499",
    annualOriginalPrice: "INR 14,999",
    monthlyAmount: 149900,
    annualAmount: 1349900,
    annualNote: "10% annual discount",
    description: "For freelancers and founders cleaning statements a few times per month.",
    badge: "Best for solo users",
    billingNote: "Ideal for solo finance workflows",
    limits: {
      pagesPerMonth: 250,
      maxFilesPerUpload: 1,
      maxWorkspaceUsers: 1,
      exports: ["csv", "xlsx"],
      processingPriority: "standard",
      supportLevel: "Email support"
    },
    features: [
      "250 pages / month",
      "Optional password for protected PDFs",
      "CSV and XLSX exports",
      "Single PDF conversion flow",
      "Email support"
    ]
  },
  {
    name: "Professional",
    slug: "professional",
    monthlyPrice: "INR 1,999",
    annualPrice: "INR 17,999",
    annualOriginalPrice: "INR 19,999",
    monthlyAmount: 199900,
    annualAmount: 1799900,
    annualNote: "10% annual discount",
    description: "For bookkeepers, finance teams, and agencies converting statements every week.",
    badge: "Most popular",
    billingNote: "Built for repeat team usage",
    limits: {
      pagesPerMonth: 1500,
      maxFilesPerUpload: 25,
      maxWorkspaceUsers: 3,
      exports: ["csv", "xlsx", "json"],
      processingPriority: "priority",
      supportLevel: "Priority support"
    },
    features: [
      "1,500 pages / month",
      "Multiple PDFs support up to 25 files",
      "Unlocked batch PDFs merged into one export",
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

export function getTierLimits(tierSlug = "personal") {
  return getTierBySlug(tierSlug).limits;
}
