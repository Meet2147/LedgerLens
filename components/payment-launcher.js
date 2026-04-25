"use client";

import { useEffect, useState } from "react";

function loadRazorpayScript() {
  return new Promise((resolve, reject) => {
    if (window.Razorpay) {
      resolve(true);
      return;
    }

    const script = document.createElement("script");
    script.src = "https://checkout.razorpay.com/v1/checkout.js";
    script.async = true;
    script.onload = () => resolve(true);
    script.onerror = () => reject(new Error("Failed to load Razorpay checkout"));
    document.body.appendChild(script);
  });
}

export function PaymentLauncher({ email, name, tier, billingCycle }) {
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [success, setSuccess] = useState("");

  useEffect(() => {
    if (!error && !success) {
      return;
    }
  }, [error, success]);

  async function openCheckout() {
    setError("");
    setSuccess("");
    setIsLoading(true);

    try {
      await loadRazorpayScript();

      const orderResponse = await fetch("/api/payments/create-order", {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          email,
          tier,
          billingCycle
        })
      });

      const orderData = await orderResponse.json();

      if (!orderResponse.ok) {
        throw new Error(orderData.error || "Could not start the payment.");
      }

      const razorpay = new window.Razorpay({
        key: orderData.keyId,
        amount: orderData.amount,
        currency: "INR",
        name: "LedgerLens",
        description: `${orderData.tierName} plan (${billingCycle})`,
        order_id: orderData.orderId,
        prefill: {
          name,
          email
        },
        theme: {
          color: "#0d6b57"
        },
        handler: async function onPaymentSuccess(response) {
          try {
            const verifyResponse = await fetch("/api/payments/verify", {
              method: "POST",
              headers: {
                "Content-Type": "application/json"
              },
              body: JSON.stringify({
                email,
                tier,
                billingCycle,
                razorpay_order_id: response.razorpay_order_id,
                razorpay_payment_id: response.razorpay_payment_id,
                razorpay_signature: response.razorpay_signature
              })
            });

            const verifyData = await verifyResponse.json();

            if (!verifyResponse.ok) {
              throw new Error(verifyData.error || "Payment verification failed.");
            }

            setSuccess("Payment captured in test mode and your account tier has been activated.");
          } catch (verificationError) {
            setError(verificationError.message);
          }
        }
      });

      razorpay.on("payment.failed", function onPaymentFailed(failure) {
        setError(failure?.error?.description || "Payment failed. Please try again.");
      });

      razorpay.open();
    } catch (checkoutError) {
      setError(checkoutError.message);
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <div className="payment-panel">
      <button className="primary-button" disabled={isLoading} onClick={openCheckout} type="button">
        {isLoading ? "Preparing payment..." : "Pay with Razorpay"}
      </button>
      {error ? <p className="error-text">{error}</p> : null}
      {success ? <p className="success-text">{success}</p> : null}
    </div>
  );
}
