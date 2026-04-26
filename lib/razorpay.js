import crypto from "node:crypto";
import { getTierAmount, getTierBySlug } from "@/lib/pricing";

const RAZORPAY_BASE_URL = "https://api.razorpay.com/v1/orders";

export function getRazorpayConfig() {
  return {
    keyId: process.env.RAZORPAY_KEY_ID || "",
    keySecret: process.env.RAZORPAY_KEY_SECRET || ""
  };
}

export function isRazorpayConfigured() {
  const { keyId, keySecret } = getRazorpayConfig();
  return Boolean(keyId && keySecret);
}

export function getRazorpayWebhookSecret() {
  return process.env.RAZORPAY_WEBHOOK_SECRET || "";
}

export async function createRazorpayOrder({ email, tier, billingCycle }) {
  const { keyId, keySecret } = getRazorpayConfig();

  if (!keyId || !keySecret) {
    throw new Error("Razorpay keys are not configured");
  }

  const selectedTier = getTierBySlug(tier);
  const amount = getTierAmount(selectedTier.slug, billingCycle);
  const receipt = `${selectedTier.slug}-${billingCycle}-${Date.now()}`;
  const authHeader = Buffer.from(`${keyId}:${keySecret}`).toString("base64");

  const response = await fetch(RAZORPAY_BASE_URL, {
    method: "POST",
    headers: {
      Authorization: `Basic ${authHeader}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      amount,
      currency: "INR",
      receipt,
      notes: {
        email,
        tier: selectedTier.slug,
        billingCycle
      }
    })
  });

  if (!response.ok) {
    const errorBody = await response.text();
    throw new Error(`Razorpay order creation failed: ${errorBody}`);
  }

  const order = await response.json();
  return {
    order,
    tier: selectedTier,
    amount
  };
}

export function verifyRazorpaySignature({ orderId, paymentId, signature }) {
  const { keySecret } = getRazorpayConfig();

  if (!keySecret) {
    return false;
  }

  const payload = `${orderId}|${paymentId}`;
  const expected = crypto.createHmac("sha256", keySecret).update(payload).digest("hex");
  return expected === signature;
}

export function verifyRazorpayWebhookSignature({ rawBody, signature }) {
  const secret = getRazorpayWebhookSecret();

  if (!secret || !signature) {
    return false;
  }

  const expected = crypto.createHmac("sha256", secret).update(rawBody).digest("hex");
  return expected === signature;
}
