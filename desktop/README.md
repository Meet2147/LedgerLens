# LedgerLens Desktop

Native desktop apps that turn PDF bank statements into spreadsheet-ready rows —
**100% on-device**. Unlike the web/mobile apps (which upload PDFs to `ledger.dashovia.com`),
the desktop apps parse everything locally. **Statement contents are never uploaded** and no
account or internet connection is required to convert. The only network call the apps ever
make is a one-time license-key check with Polar when a user activates Pro — statement data is
never part of it. For financial documents, that "your statements never leave your computer"
guarantee is the core selling point.

```
desktop/
├── macos/      SwiftUI app (native, Xcode)          → LedgerLensDesktop.xcodeproj
└── windows/    WinUI 3 / .NET app (native, VS 2022)  → LedgerLens.sln
```

## What it does

1. Add one or more PDF statements (drag-and-drop or file picker).
2. Optionally supply a password for locked PDFs.
3. **Convert** — the app extracts text locally and parses transactions.
4. Review the transactions and **export to CSV or XLSX**.

## Shared architecture

Both apps are the same pipeline in two native stacks:

| Stage | macOS (Swift) | Windows (C#) |
|-------|---------------|--------------|
| PDF text extraction | PDFKit (`page.string`) | PdfPig (word boxes → lines) |
| Transaction parsing | `StatementParser` + `ICICIStatementParser` | same, ported line-for-line |
| Template auto-select | `StatementParsing.parseBest` | `StatementParsing.ParseBest` |
| CSV / XLSX export | dependency-free `SpreadsheetExporter` | `System.IO.Compression` XLSX |

### Parser templates

The original LedgerLens parser (`lib/statement-parser.js`) only handles one bank layout
(two slash-dates + four money columns per line). Real statements vary, so the desktop apps
add a **template system** that auto-selects the best parser:

- **`StatementParser`** — a faithful port of the web/server parser, verified **byte-for-byte**
  against the original JavaScript.
- **`ICICIStatementParser`** — handles ICICI Bank "OpTransactionHistory" statements
  (dot-dates, multi-line UPI remarks, collapsed withdrawal/deposit columns). Withdrawal vs
  deposit is inferred from balance movement. Verified against a real 67-transaction statement
  with **every balance reconciling** (each balance = previous ± amount).

Adding support for another bank = adding one more template implementing the same shape.

Exports match the web product's columns exactly (`date, description, debit, credit, balance`,
plus `sourceFile` for multi-file batches), so desktop output is interchangeable with the
hosted product's.

See each platform's `README.md` for build and run instructions.
