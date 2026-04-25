import { NextResponse } from "next/server";
import { upsertUser } from "@/lib/auth";
import { getTierBySlug } from "@/lib/pricing";
import { createRazorpayOrder, getRazorpayConfig, isRazorpayConfigured } from "@/lib/razorpay";

export async function POST(request) {
  try {
    if (!isRazorpayConfigured()) {
      return NextResponse.json(
        { error: "Razorpay is not configured on the server yet." },
        { status: 500 }
      );
    }

    const body = await request.json();
    const email = String(body.email || "").trim().toLowerCase();
    const tier = getTierBySlug(String(body.tier || "personal").trim().toLowerCase());
    const billingCycle = String(body.billingCycle || "monthly").trim().toLowerCase();

    if (!email) {
      return NextResponse.json({ error: "Email is required for payment." }, { status: 400 });
    }

    const { order, amount } = await createRazorpayOrder({
      email,
      tier: tier.slug,
      billingCycle
    });

    await upsertUser({
      email,
      tier: tier.slug,
      billingCycle,
      paymentStatus: "pending",
      razorpayOrderId: order.id
    });

    return NextResponse.json({
      amount,
      orderId: order.id,
      keyId: getRazorpayConfig().keyId,
      tierName: tier.name
    });
  } catch (error) {
    return NextResponse.json(
      { error: error.message || "Could not create the payment order." },
      { status: 500 }
    );
  }
}
