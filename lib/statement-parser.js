import { execFile } from "node:child_process";
import { promises as fs } from "node:fs";
import os from "node:os";
import path from "node:path";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const DATE_PATTERN = /\d{2}\/\d{2}\/\d{4}/;
const MONEY_TOKEN = /(?:-|[\d,]+\.\d{2}(?:CR|DR)?)/;
const TRANSACTION_LINE_PATTERN = new RegExp(
  `^(\\d{2}\\/\\d{2}\\/\\d{4})\\s+(\\d{2}\\/\\d{2}\\/\\d{4})\\s+(.+?)\\s+(${MONEY_TOKEN.source})\\s+(${MONEY_TOKEN.source})\\s+(${MONEY_TOKEN.source})\\s+(${MONEY_TOKEN.source})\\s*$`
);

function normalizeWhitespace(value) {
  return value.replace(/\s+/g, " ").trim();
}

function cleanMoney(value) {
  const normalized = normalizeWhitespace(value);

  if (!normalized || normalized === "-") {
    return "";
  }

  if (normalized.endsWith("DR")) {
    return `-${normalized.slice(0, -2)}`;
  }

  if (normalized.endsWith("CR")) {
    return normalized.slice(0, -2);
  }

  return normalized;
}

function isIgnorableLine(line) {
  return (
    !line ||
    line === "\f" ||
    line.startsWith("Page no.") ||
    line.startsWith("Statement Summary") ||
    line.startsWith("Please do not share your ATM") ||
    line.startsWith("If your account is operated") ||
    line.startsWith("This is a computer generated statement") ||
    line === "Balance" ||
    line === "Welcome:" ||
    line.startsWith("Account Summary") ||
    line.startsWith("STATEMENT OF ACCOUNT") ||
    line.startsWith("Brought Forward") ||
    line.startsWith("Total Debits") ||
    line.startsWith("Total Credits") ||
    line.startsWith("Closing Balance") ||
    line.startsWith("anyone via email") ||
    line.startsWith("Bank never asks for such information") ||
    (!DATE_PATTERN.test(line) && /^\d[\d,.\sA-Z()/-]+$/.test(line))
  );
}

function parseTransactionsFromLayoutText(text) {
  const lines = text
    .replace(/\f/g, "\n")
    .split("\n")
    .map((line) => line.replace(/\u0000/g, ""))
    .map((line) => line.replace(/\s+$/g, ""));

  const rows = [];
  let pending = null;
  let carryoverDescriptionParts = [];
  let awaitingNextRowAfterPageBreak = false;

  function flushPending() {
    if (!pending) {
      return;
    }

    rows.push({
      id: `row-${rows.length + 1}`,
      date: pending.date,
      valueDate: pending.valueDate,
      description: normalizeWhitespace(pending.descriptionParts.join(" ")),
      debit: pending.debit,
      credit: pending.credit,
      balance: pending.balance
    });

    pending = null;
  }

  for (let index = 0; index < lines.length; index += 1) {
    const rawLine = lines[index];
    const line = rawLine.trim();

    if (line.startsWith("Page no.")) {
      flushPending();
      awaitingNextRowAfterPageBreak = true;
      carryoverDescriptionParts = [];
      continue;
    }

    if (isIgnorableLine(line)) {
      continue;
    }

    const match = line.match(TRANSACTION_LINE_PATTERN);

    if (match) {
      flushPending();

      pending = {
        date: match[1],
        valueDate: match[2],
        descriptionParts: [...carryoverDescriptionParts, match[3]],
        debit: cleanMoney(match[5]),
        credit: cleanMoney(match[6]),
        balance: cleanMoney(match[7])
      };
      carryoverDescriptionParts = [];
      awaitingNextRowAfterPageBreak = false;

      continue;
    }

    if (awaitingNextRowAfterPageBreak && !pending) {
      carryoverDescriptionParts.push(line);
      continue;
    }

    if (!pending) {
      continue;
    }

    if (DATE_PATTERN.test(line)) {
      flushPending();
      continue;
    }

    let nextMeaningfulLine = "";

    for (let cursor = index + 1; cursor < lines.length; cursor += 1) {
      const candidate = lines[cursor].trim();

      if (!candidate || isIgnorableLine(candidate)) {
        continue;
      }

      nextMeaningfulLine = candidate;
      break;
    }

    if (nextMeaningfulLine && TRANSACTION_LINE_PATTERN.test(nextMeaningfulLine)) {
      carryoverDescriptionParts = [line];
      flushPending();
      awaitingNextRowAfterPageBreak = false;
      continue;
    }

    pending.descriptionParts.push(line);
  }

  flushPending();
  return rows;
}

async function extractTextFromPdf(buffer, password) {
  const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "ledgerlens-"));
  const pdfPath = path.join(tempDir, "statement.pdf");

  try {
    await fs.writeFile(pdfPath, buffer);

    const args = ["-layout"];

    if (password) {
      args.push("-upw", password);
    }

    args.push(pdfPath, "-");

    let stdout;

    try {
      ({ stdout } = await execFileAsync("pdftotext", args, {
        maxBuffer: 20 * 1024 * 1024
      }));
    } catch (error) {
      const stderr = `${error?.stderr || ""}`.toLowerCase();

      if (stderr.includes("incorrect password")) {
        const passwordError = new Error("Incorrect PDF password");
        passwordError.code = "INCORRECT_PDF_PASSWORD";
        throw passwordError;
      }

      if (error?.code === "ENOENT") {
        const dependencyError = new Error("pdftotext is not installed on the server");
        dependencyError.code = "PDFTOTEXT_NOT_INSTALLED";
        throw dependencyError;
      }

      throw error;
    }

    const pageCount = (stdout.match(/Page no\.\s+\d+/g) ?? []).length || 1;

    return {
      pageCount,
      text: stdout
    };
  } finally {
    await fs.rm(tempDir, { recursive: true, force: true });
  }
}

export async function convertStatement(buffer, password = "") {
  const { pageCount, text } = await extractTextFromPdf(buffer, password);
  const rows = parseTransactionsFromLayoutText(text).slice(0, 5000);

  return {
    pageCount,
    rows
  };
}
