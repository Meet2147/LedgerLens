"use client";

import { useMemo, useState, useTransition } from "react";
import ExcelJS from "exceljs";

const columns = ["date", "description", "debit", "credit", "balance"];

function downloadCsv(rows, fileName) {
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

async function downloadXlsx(rows, fileName) {
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

export function UploadWorkbench() {
  const [file, setFile] = useState(null);
  const [password, setPassword] = useState("");
  const [result, setResult] = useState(null);
  const [error, setError] = useState("");
  const [isPending, startTransition] = useTransition();

  const previewRows = useMemo(() => result?.rows?.slice(0, 8) ?? [], [result]);

  function handleSubmit(event) {
    event.preventDefault();
    setError("");
    setResult(null);

    if (!file) {
      setError("Choose a bank statement PDF first.");
      return;
    }

    startTransition(async () => {
      try {
        const payload = new FormData();
        payload.append("statement", file);
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
          This MVP supports PDF statements and lets the user provide a password for protected files.
          The parser extracts transaction-like rows into a spreadsheet-ready table.
        </p>
        <p className="privacy-note">
          We do not store your uploaded PDF or the extracted transaction data.
        </p>
        <form className="upload-form" onSubmit={handleSubmit}>
          <label className="input-group">
            <span>Bank statement PDF</span>
            <input
              accept="application/pdf"
              onChange={(event) => setFile(event.target.files?.[0] ?? null)}
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
            <div className="download-actions">
              <button
                className="secondary-button"
                onClick={() => downloadCsv(result.rows, result.fileStem)}
                type="button"
              >
                Download CSV
              </button>
              <button
                className="secondary-button"
                onClick={() => downloadXlsx(result.rows, result.fileStem)}
                type="button"
              >
                Download XLSX
              </button>
            </div>
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>Date</th>
                    <th>Description</th>
                    <th>Debit</th>
                    <th>Credit</th>
                    <th>Balance</th>
                  </tr>
                </thead>
                <tbody>
                  {previewRows.map((row) => (
                    <tr key={row.id}>
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
              Good next milestone: statement-specific templates, confidence scores, and accounting
              exports like QBO/OFX.
            </p>
          </div>
        )}
      </div>
    </section>
  );
}
