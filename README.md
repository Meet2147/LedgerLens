# LedgerLens

LedgerLens is a micro SaaS MVP for converting bank statement PDFs into spreadsheet-ready rows.

## What is included

- Marketing landing page
- Dedicated pricing page
- Upload flow for PDF statements
- Optional password input for protected PDFs
- Server-side PDF text extraction
- Client-side CSV and XLSX download

## Suggested pricing

- Personal: INR 1,499/month or INR 14,999/year
- Professional: INR 1,999/month or INR 19,999/year

## Run locally

```bash
npm install
npm run dev
```

## Notes

The parser in this MVP is heuristic. It is a strong first step for text-based PDFs, but production quality will need:

- statement-specific parsing templates
- better OCR for scans
- confidence scoring and row review
- accounting exports like QBO or OFX
- payments, auth, and usage metering
