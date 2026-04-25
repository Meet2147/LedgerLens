import { NextResponse } from "next/server";
import { upsertUser } from "@/lib/auth";
import { verifyRazorpaySignature } from "@/lib/razorpay";

export async function POST(request) {
  try {
    const body = await request.json();
    const email = String(body.email || "").trim().toLowerCase();
    const tier = String(body.tier || "personal").trim().toLowerCase();
    const billingCycle = String(body.billingCycle || "monthly").trim().toLowerCase();
    const orderId = String(body.razorpay_order_id || "");
    const paymentId = String(body.razorpay_payment_id || "");
    const signature = String(body.razorpay_signature || "");

    const isValid = verifyRazorpaySignature({
      orderId,
      paymentId,
      signature
    });

    if (!isValid) {
      return NextResponse.json({ error: "Invalid Razorpay signature." }, { status: 400 });
    }

    await upsertUser({
      email,
      tier,
      billingCycle,
      paymentStatus: "paid",
      razorpayOrderId: orderId,
      razorpayPaymentId: paymentId
    });

    return NextResponse.json({ ok: true });
  } catch (error) {
    return NextResponse.json(
      { error: error.message || "Could not verify payment." },
      { status: 500 }
    );
  }
}
