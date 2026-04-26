import { NextResponse } from "next/server";
import { getUserByEmail, upsertUser } from "@/lib/auth";
import { verifyRazorpayWebhookSignature } from "@/lib/razorpay";

export async function POST(request) {
  try {
    const rawBody = await request.text();
    const signature = request.headers.get("x-razorpay-signature") || "";

    if (!verifyRazorpayWebhookSignature({ rawBody, signature })) {
      return NextResponse.json({ error: "Invalid webhook signature." }, { status: 400 });
    }

    const payload = JSON.parse(rawBody);
    const event = String(payload.event || "");

    if (event === "payment.captured" || event === "order.paid") {
      const paymentEntity = payload.payload?.payment?.entity;
      const orderEntity = payload.payload?.order?.entity;
      const email = String(
        paymentEntity?.notes?.email || orderEntity?.notes?.email || ""
      ).trim().toLowerCase();
      const tier = String(
        paymentEntity?.notes?.tier || orderEntity?.notes?.tier || "personal"
      ).trim().toLowerCase();
      const billingCycle = String(
        paymentEntity?.notes?.billingCycle || orderEntity?.notes?.billingCycle || "monthly"
      )
        .trim()
        .toLowerCase();

      if (email) {
        const existingUser = await getUserByEmail(email);

        await upsertUser({
          email,
          name: existingUser?.name || "",
          tier,
          billingCycle,
          paymentStatus: "paid",
          razorpayOrderId: String(paymentEntity?.order_id || orderEntity?.id || existingUser?.razorpayOrderId || ""),
          razorpayPaymentId: String(paymentEntity?.id || existingUser?.razorpayPaymentId || "")
        });
      }
    }

    if (event === "payment.failed") {
      const paymentEntity = payload.payload?.payment?.entity;
      const email = String(paymentEntity?.notes?.email || "").trim().toLowerCase();

      if (email) {
        const existingUser = await getUserByEmail(email);

        if (existingUser) {
          await upsertUser({
            email,
            name: existingUser.name || "",
            tier: existingUser.tier || "personal",
            billingCycle: existingUser.billingCycle || "monthly",
            paymentStatus: "pending",
            razorpayOrderId: String(paymentEntity?.order_id || existingUser.razorpayOrderId || ""),
            razorpayPaymentId: String(paymentEntity?.id || existingUser.razorpayPaymentId || "")
          });
        }
      }
    }

    return NextResponse.json({ ok: true });
  } catch (error) {
    return NextResponse.json(
      { error: error.message || "Could not process Razorpay webhook." },
      { status: 500 }
    );
  }
}
