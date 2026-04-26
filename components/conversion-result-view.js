"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import ExcelJS from "exceljs";

const STORAGE_KEY = "ledgerlens_last_result";

function getColumns(includeSourceFile) {
  return includeSourceFile
    ? ["sourceFile", "date", "description", "debit", "credit", "balance"]
    : ["date", "description", "debit", "credit", "balance"];
}

function downloadCsv(rows, fileName, columns) {
  const csvRows = [
    columns.join(","),
    ...rows.map((row) =>
      columns
        .map((column) => `"${String(row[column] ?? "").replace(/"/g, '""')}"`)
        .join(",")
    )
  ];

  const blob = new Blob([csvRows.join("\n")], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = `${fileName}.csv`;
  link.click();
  URL.revokeObjectURL(url);
}

async function downloadXlsx(rows, fileName, columns) {
  const workbook = new ExcelJS.Workbook();
  const worksheet = workbook.addWorksheet("Transactions");

  worksheet.columns = columns.map((column) => ({
    header: column.charAt(0).toUpperCase() + column.slice(1),
    key: column,
    width: column === "description" ? 48 : 18
  }));

  rows.forEach((row) => worksheet.addRow(row));
  worksheet.getRow(1).font = { bold: true };

  const buffer = await workbook.xlsx.writeBuffer();
  const blob = new Blob([buffer], {
    type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = `${fileName}.xlsx`;
  link.click();
  URL.revokeObjectURL(url);
}

function downloadJson(rows, fileName) {
  const blob = new Blob([JSON.stringify(rows, null, 2)], { type: "application/json;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = `${fileName}.json`;
  link.click();
  URL.revokeObjectURL(url);
}

function formatTrialEndsAt(value) {
  if (!value) {
    return "your trial window";
  }

  const parsed = new Date(value);

  if (Number.isNaN(parsed.getTime())) {
    return "your trial window";
  }

  return parsed.toLocaleDateString("en-IN");
}

export function persistConversionResult(result) {
  if (typeof window === "undefined") {
    return;
  }

  window.sessionStorage.setItem(STORAGE_KEY, JSON.stringify(result));
}

function readPersistedResult() {
  if (typeof window === "undefined") {
    return null;
  }

  const raw = window.sessionStorage.getItem(STORAGE_KEY);

  if (!raw) {
    return null;
  }

  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

export function ConversionResultView({ currentUser, capabilities }) {
  const [result, setResult] = useState(null);
  const availableExportFormats = Array.isArray(capabilities?.exportFormats)
    ? capabilities.exportFormats
    : Array.isArray(capabilities?.exports)
      ? capabilities.exports
      : [];

  useEffect(() => {
    setResult(readPersistedResult());
  }, []);

  const columns = useMemo(
    () => getColumns((result?.rows || []).some((row) => row.sourceFile)),
    [result]
  );

  if (!result) {
    return (
      <main className="page-shell">
        <section className="hero compact-hero">
          <div className="section-header">
            <div className="eyebrow">Results</div>
            <h1>Open a converted result after upload.</h1>
            <p className="hero-copy">
              Upload a bank statement first, then LedgerLens will bring you here with the combined
              transaction preview and export actions.
            </p>
            <div className="cta-row">
              <Link className="primary-button" href="/converter">
                Back to converter
              </Link>
            </div>
          </div>
        </section>
      </main>
    );
  }

  return (
    <main className="page-shell">
      <section className="hero compact-hero">
        <div className="section-header">
          <div className="eyebrow">Results</div>
          <h1>Review the converted transactions in one place.</h1>
          <p className="hero-copy">
            This review screen keeps the upload step separate from the transaction audit step so
            batch runs feel cleaner and easier to scan before export.
          </p>
          <div className="result-summary result-summary-wide">
            <div>
              <strong>{result.rows.length}</strong>
              <span>rows detected</span>
            </div>
            <div>
              <strong>{result.pageCount}</strong>
              <span>pages processed</span>
            </div>
            <div>
              <strong>{result.queuePriority}</strong>
              <span>processing queue</span>
            </div>
          </div>
          {currentUser ? (
            <p className="muted usage-line">
              {currentUser.paymentStatus === "paid"
                ? `${result.pagesUsedThisMonth} pages used this month · ${result.pagesRemainingThisMonth} pages remaining`
                : `${result.trial.pdfsUsed}/${result.trial.pdfLimit} PDFs used · ${result.trial.pagesUsed}/${result.trial.pageLimit} pages used · Trial ends ${formatTrialEndsAt(result.trial.endsAt)}`}
            </p>
          ) : null}
          <div className="cta-row">
            <Link className="secondary-button" href="/converter">
              Convert another file
            </Link>
            <button
              className="secondary-button"
              onClick={() => downloadCsv(result.rows, result.fileStem, columns)}
              type="button"
            >
              Download CSV
            </button>
            <button
              className="secondary-button"
              onClick={() => downloadXlsx(result.rows, result.fileStem, columns)}
              type="button"
            >
              Download XLSX
            </button>
            {availableExportFormats.includes("json") ? (
              <button
                className="secondary-button"
                onClick={() => downloadJson(result.rows, result.fileStem)}
                type="button"
              >
                Download JSON
              </button>
            ) : null}
          </div>
        </div>
      </section>

      <section className="panel result-review-panel">
        <div className="eyebrow">Detected rows</div>
        <p className="section-copy result-copy">
          {columns.includes("sourceFile")
            ? "Multiple PDFs were combined into one export. The File column shows which statement each row came from."
            : "This statement was converted into a single spreadsheet-ready table."}
        </p>
        <div className="table-wrap table-wrap-large">
          <table>
            <thead>
              <tr>
                {columns.includes("sourceFile") ? <th>File</th> : null}
                <th>Date</th>
                <th>Description</th>
                <th>Debit</th>
                <th>Credit</th>
                <th>Balance</th>
              </tr>
            </thead>
            <tbody>
              {result.rows.map((row, index) => (
                <tr key={`${row.sourceFile || "single"}-${row.id || index}`}>
                  {columns.includes("sourceFile") ? <td>{row.sourceFile}</td> : null}
                  <td>{row.date}</td>
                  <td>{row.description}</td>
                  <td>{row.debit}</td>
                  <td>{row.credit}</td>
                  <td>{row.balance}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </main>
  );
}
