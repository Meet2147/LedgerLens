import { NextResponse } from "next/server";
import { convertStatement } from "@/lib/statement-parser";

export const runtime = "nodejs";

function normalizeFileStem(filename = "statement.pdf") {
  const stem = filename.replace(/\.pdf$/i, "").replace(/[^a-z0-9-_]+/gi, "-").toLowerCase();
  return stem.replace(/^-+|-+$/g, "") || "statement";
}

export async function POST(request) {
  try {
    const formData = await request.formData();
    const statement = formData.get("statement");
    const password = String(formData.get("password") || "");

    if (!statement || typeof statement.arrayBuffer !== "function") {
      return NextResponse.json({ error: "Upload a PDF bank statement first." }, { status: 400 });
    }

    if (statement.type && statement.type !== "application/pdf") {
      return NextResponse.json({ error: "Only PDF bank statements are supported right now." }, { status: 400 });
    }

    const buffer = Buffer.from(await statement.arrayBuffer());
    const result = await convertStatement(buffer, password);

    if (result.rows.length === 0) {
      return NextResponse.json(
        {
          error:
            "We opened the file but could not detect transaction rows yet. Try a clearer statement or add the PDF password."
        },
        { status: 422 }
      );
    }

    return NextResponse.json({
      fileStem: normalizeFileStem(statement.name),
      pageCount: result.pageCount,
      rows: result.rows
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
