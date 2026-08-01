#!/usr/bin/env node
/**
 * Creates the LedgerLens Pro plans on Polar (idempotent — safe to re-run):
 *   - Monthly  — $7/mo   (subscription)
 *   - Yearly   — $59/yr  (subscription)
 *   - Lifetime — $99     (one-time)
 *   - Firm     — $29/mo  (subscription, 25-seat license)
 * plus License Keys benefits and a hosted checkout link per plan. Then prints the values to
 * paste into PolarConfig (macOS `PolarConfig.swift`, Windows `PolarConfig.cs`).
 *
 * Usage:
 *   POLAR_ACCESS_TOKEN=polar_oat_xxx node create-product.mjs
 *   POLAR_SERVER=sandbox POLAR_ACCESS_TOKEN=polar_oat_xxx node create-product.mjs   # test first
 *
 * Uses an Organization Access Token (Polar → Settings → Developers). The org is inferred from
 * the token — do NOT send organization_id in request bodies. Node 18+.
 */

const TOKEN = process.env.POLAR_ACCESS_TOKEN;
const SERVER = (process.env.POLAR_SERVER || "production").toLowerCase();
const BASE = SERVER === "sandbox" ? "https://sandbox-api.polar.sh" : "https://api.polar.sh";
const PAYMENT_PROCESSOR = "stripe";

const PLANS = [
  { key: "MONTHLY",  name: "LedgerLens Pro — Monthly",  cents: 700,  interval: "month", seats: 5 },
  { key: "YEARLY",   name: "LedgerLens Pro — Yearly",   cents: 5900, interval: "year",  seats: 5 },
  { key: "LIFETIME", name: "LedgerLens Pro — Lifetime", cents: 9900, interval: null,    seats: 5 },
  { key: "FIRM",     name: "LedgerLens Pro — Firm",     cents: 2900, interval: "month", seats: 25 },
];

const DESCRIPTION =
  "LedgerLens Pro — convert unlimited PDF bank statements to CSV/XLSX, fully on-device.";
const PERSONAL_BENEFIT_DESC = "LedgerLens Pro license key";
const FIRM_BENEFIT_DESC = "LedgerLens Firm license key";

if (!TOKEN) {
  console.error("✗ Set POLAR_ACCESS_TOKEN (Polar → Settings → Developers → New Token).");
  process.exit(1);
}

async function api(method, path, body) {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: { Authorization: `Bearer ${TOKEN}`, "Content-Type": "application/json" },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json;
  try { json = text ? JSON.parse(text) : {}; } catch { json = { raw: text }; }
  if (!res.ok) throw new Error(`${method} ${path} → ${res.status}\n${JSON.stringify(json, null, 2)}`);
  return json;
}

async function listAll(path) {
  const out = [];
  let page = 1;
  while (true) {
    const sep = path.includes("?") ? "&" : "?";
    const res = await api("GET", `${path}${sep}limit=100&page=${page}`);
    out.push(...(res.items || []));
    const max = res.pagination?.max_page ?? page;
    if (page >= max) break;
    page += 1;
  }
  return out;
}

async function main() {
  console.log(`→ Polar ${SERVER} (${BASE})`);

  const existingBenefits = await listAll("/v1/benefits");
  const existingProducts = await listAll("/v1/products");
  const existingLinks = await listAll("/v1/checkout-links");
  let organizationId = process.env.POLAR_ORG_ID || existingProducts[0]?.organization_id || null;

  // Benefits (reuse by description; org token infers the org).
  async function ensureBenefit(desc, limit) {
    const found = existingBenefits.find((b) => b.description === desc);
    if (found) { console.log(`• benefit exists: ${desc} (${found.id})`); return found.id; }
    console.log(`→ Creating benefit: ${desc} (${limit} seats)…`);
    const b = await api("POST", "/v1/benefits", {
      type: "license_keys",
      description: desc,
      properties: { prefix: "LLENS", activations: { limit, enable_customer_admin: true }, expires: null },
    });
    console.log(`  ✓ ${b.id}`);
    return b.id;
  }
  const personalBenefit = await ensureBenefit(PERSONAL_BENEFIT_DESC, 5);
  const firmBenefit = await ensureBenefit(FIRM_BENEFIT_DESC, 25);

  const checkoutUrls = {};
  for (const plan of PLANS) {
    // Product (reuse by name).
    let product = existingProducts.find((p) => p.name === plan.name);
    if (product) {
      console.log(`• product exists: ${plan.name} (${product.id})`);
    } else {
      console.log(`→ Creating product: ${plan.name}…`);
      product = await api("POST", "/v1/products", {
        name: plan.name,
        description: DESCRIPTION,
        recurring_interval: plan.interval, // null = one-time
        prices: [{ amount_type: "fixed", price_amount: plan.cents, price_currency: "usd" }],
      });
      console.log(`  ✓ ${product.id}`);
    }
    if (!organizationId && product.organization_id) organizationId = product.organization_id;

    // Attach the right benefit (idempotent on Polar's side).
    const benefitId = plan.seats >= 25 ? firmBenefit : personalBenefit;
    try {
      await api("POST", `/v1/products/${product.id}/benefits`, { benefits: [benefitId] });
    } catch {
      await api("PATCH", `/v1/products/${product.id}`, { benefits: [benefitId] });
    }

    // Checkout link (reuse if one already targets this product).
    const productId = product.id;
    let link = existingLinks.find((l) =>
      l.product_id === productId || (l.products || []).some((p) => (p.id || p) === productId));
    if (link) {
      console.log(`• checkout exists: ${link.url}`);
    } else {
      link = await api("POST", "/v1/checkout-links", {
        payment_processor: PAYMENT_PROCESSOR,
        products: [productId],
        label: plan.name,
      });
      console.log(`  ✓ checkout ${link.url}`);
    }
    checkoutUrls[plan.key] = link.url;
  }

  console.log("\n────────────────────────────────────────────────────────");
  console.log("Paste into macOS  Core/PolarConfig.swift:\n");
  console.log(`  static let organizationId = "${organizationId}"`);
  console.log(`  static let checkoutMonthlyURL = URL(string: "${checkoutUrls.MONTHLY}")!`);
  console.log(`  static let checkoutYearlyURL = URL(string: "${checkoutUrls.YEARLY}")!`);
  console.log(`  static let checkoutLifetimeURL = URL(string: "${checkoutUrls.LIFETIME}")!`);
  console.log(`  static let checkoutFirmURL = URL(string: "${checkoutUrls.FIRM}")!`);
  console.log(`  static let apiBase = URL(string: "${BASE}")!`);
  console.log("\nPaste into Windows  Core/PolarConfig.cs:\n");
  console.log(`  public const string OrganizationId = "${organizationId}";`);
  console.log(`  public const string CheckoutMonthlyUrl = "${checkoutUrls.MONTHLY}";`);
  console.log(`  public const string CheckoutYearlyUrl = "${checkoutUrls.YEARLY}";`);
  console.log(`  public const string CheckoutLifetimeUrl = "${checkoutUrls.LIFETIME}";`);
  console.log(`  public const string CheckoutFirmUrl = "${checkoutUrls.FIRM}";`);
  console.log(`  public const string ApiBase = "${BASE}";`);
  console.log("────────────────────────────────────────────────────────");
}

main().catch((err) => { console.error("\n✗ Failed:\n" + err.message); process.exit(1); });
