import { NextResponse } from "next/server";
import { getCurrentUserFromRequest, isTrialActive } from "@/lib/auth";
import { getTierLimits } from "@/lib/pricing";
import { convertStatement } from "@/lib/statement-parser";
import { addMonthlyUsage, addTrialUsage, getMonthlyUsage, getTrialUsage } from "@/lib/usage";

export const runtime = "nodejs";

function normalizeFileStem(filename = "statement.pdf") {
  const stem = filename.replace(/\.pdf$/i, "").replace(/[^a-z0-9-_]+/gi, "-").toLowerCase();
  return stem.replace(/^-+|-+$/g, "") || "statement";
}

export async function POST(request) {
  try {
    const currentUser = await getCurrentUserFromRequest(request);

    if (!currentUser) {
      return NextResponse.json(
        { error: "Please sign up or log in to start your 7-day trial." },
        { status: 401 }
      );
    }

    const tier = currentUser.tier || "personal";
    const limits = getTierLimits(tier);
    const formData = await request.formData();
    const statements = formData
      .getAll("statement")
      .filter((file) => file && typeof file.arrayBuffer === "function");
    const password = String(formData.get("password") || "");

    if (statements.length === 0) {
      return NextResponse.json({ error: "Upload at least one PDF bank statement first." }, { status: 400 });
    }

    if (statements.length > limits.maxFilesPerUpload) {
      return NextResponse.json(
        {
          error: `Your ${tier} plan supports up to ${limits.maxFilesPerUpload} file${limits.maxFilesPerUpload === 1 ? "" : "s"} per upload.`
        },
        { status: 403 }
      );
    }

    for (const statement of statements) {
      if (statement.type && statement.type !== "application/pdf") {
        return NextResponse.json(
          { error: "Only PDF bank statements are supported right now." },
          { status: 400 }
        );
      }
    }

    let rows = [];
    let totalPages = 0;
    const fileNames = [];

    for (const statement of statements) {
      const buffer = Buffer.from(await statement.arrayBuffer());
      const result = await convertStatement(buffer, password);
      totalPages += result.pageCount;
      fileNames.push(statement.name);
      rows = rows.concat(
        result.rows.map((row) => ({
          ...row,
          sourceFile: statement.name
        }))
      );
    }

    const trialActive = isTrialActive(currentUser);
    const pagesUsed = await getMonthlyUsage(currentUser.email);

    if (currentUser.paymentStatus === "paid") {
      if (pagesUsed + totalPages > limits.pagesPerMonth) {
        return NextResponse.json(
          {
            error: `This conversion would exceed your monthly limit of ${limits.pagesPerMonth} pages. You have already used ${pagesUsed} pages this month.`
          },
          { status: 403 }
        );
      }
    } else {
      if (!trialActive) {
        return NextResponse.json(
          {
            error: "Your 7-day trial has ended. Please choose a paid plan on the web app to continue."
          },
          { status: 403 }
        );
      }

      const trialUsage = await getTrialUsage(currentUser.email);

      if (trialUsage.pdfsUsed + statements.length > 5) {
        return NextResponse.json(
          {
            error: `Your free trial includes up to 5 PDFs total. You have already used ${trialUsage.pdfsUsed}.`
          },
          { status: 403 }
        );
      }

      if (trialUsage.pagesUsed + totalPages > 50) {
        return NextResponse.json(
          {
            error: `Your free trial includes up to 50 pages total. You have already used ${trialUsage.pagesUsed} pages.`
          },
          { status: 403 }
        );
      }
    }

    if (rows.length === 0) {
      return NextResponse.json(
        {
          error:
            "We opened the file but could not detect transaction rows yet. Try a clearer statement or add the PDF password."
        },
        { status: 422 }
      );
    }

    const updatedUsage =
      currentUser.paymentStatus === "paid"
        ? await addMonthlyUsage(currentUser.email, totalPages)
        : null;
    const updatedTrialUsage =
      currentUser.paymentStatus !== "paid"
        ? await addTrialUsage(currentUser.email, statements.length, totalPages)
        : null;

    return NextResponse.json({
      fileStem: normalizeFileStem(fileNames.length === 1 ? fileNames[0] : "ledgerlens-batch"),
      pageCount: totalPages,
      rows,
      queuePriority: limits.processingPriority,
      pagesUsedThisMonth: updatedUsage,
      pagesRemainingThisMonth:
        currentUser.paymentStatus === "paid" ? Math.max(0, limits.pagesPerMonth - updatedUsage) : null,
      exportFormats: limits.exports,
      trial: updatedTrialUsage
        ? {
            isActive: true,
            pdfsUsed: updatedTrialUsage.pdfsUsed,
            pdfLimit: 5,
            pagesUsed: updatedTrialUsage.pagesUsed,
            pageLimit: 50,
            endsAt: currentUser.trialEndsAt
          }
        : {
            isActive: false
          }
    });
  } catch (error) {
    const message =
      error?.code === "INCORRECT_PDF_PASSWORD"
        ? "The PDF password is incorrect. Please re-enter it and try again."
        : error?.code === "PDFTOTEXT_NOT_INSTALLED"
          ? "PDF conversion is not configured on the server yet. Install pdftotext and try again."
          : "The statement could not be processed yet. Try another PDF or check the password.";

    return NextResponse.json({ error: message }, { status: 500 });
  }
}
