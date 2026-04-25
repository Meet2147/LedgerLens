"use client";

import { useMemo, useState, useTransition } from "react";
import ExcelJS from "exceljs";

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

  rows.forEach((row) => {
    worksheet.addRow(row);
  });

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

export function UploadWorkbench({ capabilities, currentUser }) {
  const [files, setFiles] = useState([]);
  const [password, setPassword] = useState("");
  const [result, setResult] = useState(null);
  const [error, setError] = useState("");
  const [isPending, startTransition] = useTransition();
  const columns = useMemo(
    () => getColumns((result?.rows || []).some((row) => row.sourceFile)),
    [result]
  );

  const previewRows = useMemo(() => result?.rows?.slice(0, 8) ?? [], [result]);
  const isProfessional = capabilities.maxFilesPerUpload > 1;

  function handleSubmit(event) {
    event.preventDefault();
    setError("");
    setResult(null);

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

        const data = await response.json();

        if (!response.ok) {
          throw new Error(data.error || "We could not convert that statement yet.");
        }

        setResult(data);
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
          <span>{capabilities.pagesPerMonth} pages / month</span>
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
              placeholder="Leave blank if the PDF is unlocked"
              type="password"
              value={password}
            />
          </label>
          <button className="primary-button" disabled={isPending} type="submit">
            {isPending ? "Converting..." : "Convert statement"}
          </button>
        </form>
        {error ? <p className="error-text">{error}</p> : null}
      </div>

      <div className="panel result-panel">
        <div className="eyebrow">Preview</div>
        {result ? (
          <>
            <div className="result-summary">
              <div>
                <strong>{result.rows.length}</strong>
                <span>rows detected</span>
              </div>
              <div>
                <strong>{result.pageCount}</strong>
                <span>pages processed</span>
              </div>
            </div>
            {currentUser ? (
              <p className="muted usage-line">
                {result.pagesUsedThisMonth} pages used this month · {result.pagesRemainingThisMonth} pages
                remaining · {result.queuePriority} processing
              </p>
            ) : (
              <p className="muted usage-line">
                Guest conversions use Personal plan defaults. Sign up to track usage and unlock Pro
                features.
              </p>
            )}
            <div className="download-actions">
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
              {capabilities.exportFormats.includes("json") ? (
                <button
                  className="secondary-button"
                  onClick={() => downloadJson(result.rows, result.fileStem)}
                  type="button"
                >
                  Download JSON
                </button>
              ) : null}
            </div>
            <div className="table-wrap">
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
                  {previewRows.map((row) => (
                    <tr key={`${row.sourceFile || "single"}-${row.id}`}>
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
          </>
        ) : (
          <div className="empty-state">
            <p>Preview rows will appear here after a successful conversion.</p>
            <p className="muted">
              {isProfessional
                ? `Professional includes up to ${capabilities.maxFilesPerUpload} files per upload and JSON exports.`
                : "Personal stays focused on single-file spreadsheet conversion and CSV/XLSX exports."}
            </p>
          </div>
        )}
      </div>
    </section>
  );
}
