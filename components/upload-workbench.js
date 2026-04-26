"use client";

import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import { persistConversionResult } from "@/components/conversion-result-view";

function normalizeConversionResult(payload) {
  const rows = Array.isArray(payload?.rows) ? payload.rows : [];
  const trialPayload = payload?.trial && typeof payload.trial === "object" ? payload.trial : {};

  return {
    fileStem: typeof payload?.fileStem === "string" && payload.fileStem ? payload.fileStem : "statement",
    pageCount: Number.isFinite(payload?.pageCount) ? payload.pageCount : 0,
    rows,
    queuePriority: typeof payload?.queuePriority === "string" ? payload.queuePriority : "standard",
    pagesUsedThisMonth: Number.isFinite(payload?.pagesUsedThisMonth) ? payload.pagesUsedThisMonth : null,
    pagesRemainingThisMonth: Number.isFinite(payload?.pagesRemainingThisMonth)
      ? payload.pagesRemainingThisMonth
      : null,
    exportFormats: Array.isArray(payload?.exportFormats) ? payload.exportFormats : [],
    trial: {
      isActive: Boolean(trialPayload.isActive),
      pdfsUsed: Number.isFinite(trialPayload.pdfsUsed) ? trialPayload.pdfsUsed : 0,
      pdfLimit: Number.isFinite(trialPayload.pdfLimit) ? trialPayload.pdfLimit : 5,
      pagesUsed: Number.isFinite(trialPayload.pagesUsed) ? trialPayload.pagesUsed : 0,
      pageLimit: Number.isFinite(trialPayload.pageLimit) ? trialPayload.pageLimit : 50,
      endsAt: typeof trialPayload.endsAt === "string" ? trialPayload.endsAt : null
    }
  };
}

export function UploadWorkbench({ capabilities, currentUser }) {
  const router = useRouter();
  const [files, setFiles] = useState([]);
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [isPending, startTransition] = useTransition();
  const isProfessional = capabilities.maxFilesPerUpload > 1;
  const supportsMultiplePdfUploads = isProfessional;

  function handleSubmit(event) {
    event.preventDefault();
    setError("");

    if (!currentUser) {
      setError("Please sign up or log in to use your 7-day trial.");
      return;
    }

    if (files.length === 0) {
      setError("Choose at least one bank statement PDF first.");
      return;
    }

    if (files.length > capabilities.maxFilesPerUpload) {
      setError(
        `Your ${capabilities.tierName} plan supports up to ${capabilities.maxFilesPerUpload} file${capabilities.maxFilesPerUpload === 1 ? "" : "s"} per upload.`
      );
      return;
    }

    startTransition(async () => {
      try {
        const payload = new FormData();
        files.forEach((file) => {
          payload.append("statement", file);
        });
        payload.append("password", password);

        const response = await fetch("/api/convert", {
          method: "POST",
          body: payload
        });

        const rawText = await response.text();
        let data = {};

        try {
          data = rawText ? JSON.parse(rawText) : {};
        } catch {
          data = { error: rawText || "We could not convert that statement yet." };
        }

        if (!response.ok) {
          throw new Error(data.error || "We could not convert that statement yet.");
        }

        const normalized = normalizeConversionResult(data);
        persistConversionResult(normalized);
        router.push("/converter/result");
      } catch (submitError) {
        setError(submitError.message);
      }
    });
  }

  return (
    <section className="workbench" id="converter">
      <div className="panel">
        <div className="eyebrow">Upload</div>
        <h2>Upload a statement, add a password if needed, and export clean rows.</h2>
        <p className="section-copy">
          This workspace enforces your plan limits, supports password-protected PDFs, and extracts
          transaction-like rows into spreadsheet-ready data.
        </p>
        <p className="privacy-note">
          We do not store your uploaded PDF or the extracted transaction data.
        </p>
        <div className="capability-summary">
          {currentUser?.paymentStatus === "paid" ? (
            <span>{capabilities.pagesPerMonth} pages / month</span>
          ) : (
            <span>7-day trial · 5 PDFs · 50 pages total</span>
          )}
          <span>{capabilities.maxFilesPerUpload} file{capabilities.maxFilesPerUpload === 1 ? "" : "s"} per upload</span>
          <span>{capabilities.supportLevel}</span>
          <span>{capabilities.processingPriority} processing</span>
        </div>
        <form className="upload-form" onSubmit={handleSubmit}>
          <label className="input-group">
            <span>Bank statement PDF{capabilities.maxFilesPerUpload > 1 ? "s" : ""}</span>
            <input
              accept="application/pdf"
              multiple={capabilities.maxFilesPerUpload > 1}
              onChange={(event) => setFiles(Array.from(event.target.files ?? []))}
              type="file"
            />
          </label>
          <label className="input-group">
            <span>Password for protected PDFs</span>
            <input
              onChange={(event) => setPassword(event.target.value)}
              placeholder={
                supportsMultiplePdfUploads
                  ? "Only single-file uploads can use a password"
                  : "Leave blank if the PDF is unlocked"
              }
              type="password"
              value={password}
            />
          </label>
          {supportsMultiplePdfUploads ? (
            <p className="muted">
              Professional batch uploads combine multiple PDFs into one export, but those PDFs must
              already be unlocked. Locked statements need to be converted one at a time.
            </p>
          ) : null}
          <button className="primary-button" disabled={isPending} type="submit">
            {isPending ? "Converting..." : "Convert statement"}
          </button>
        </form>
        {error ? <p className="error-text">{error}</p> : null}
      </div>

      <div className="panel result-panel">
        <div className="eyebrow">Review flow</div>
        <div className="empty-state">
          <p>The converted table now opens on a dedicated results page after upload.</p>
          <p className="muted">
            {isProfessional
              ? `Professional combines multiple unlocked PDFs into one export and opens the full merged table on its own review screen.`
              : "Personal keeps single-file conversion focused, then opens a separate results screen for review and export."}
          </p>
        </div>
      </div>
    </section>
  );
}
