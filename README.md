# LedgerLens

LedgerLens is a micro SaaS MVP for converting bank statement PDFs into spreadsheet-ready rows.

## What is included

- Marketing landing page
- Dedicated pricing page
- Upload flow for PDF statements
- Optional password input for protected PDFs
- Server-side PDF text extraction
- Client-side CSV and XLSX download
- Shared trial/tier state across web and mobile
- Supabase Postgres storage for users, workspace members, and usage counters

## Suggested pricing

- Personal: INR 1,499/month or INR 14,999/year
- Professional: INR 1,999/month or INR 19,999/year

## Run locally

```bash
npm install
```

Create `.env.local` with:

```bash
DATABASE_URL=your_supabase_postgres_url
RAZORPAY_KEY_ID=your_razorpay_key
RAZORPAY_KEY_SECRET=your_razorpay_secret
```

If you want to import existing JSON demo data into Postgres:

```bash
npm run db:migrate
```

Then run:

```bash
npm run dev
```

## Notes

The parser in this MVP is heuristic. It is a strong first step for text-based PDFs, but production quality will need:

- statement-specific parsing templates
- better OCR for scans
- confidence scoring and row review
- accounting exports like QBO or OFX
- deeper payment, auth, and usage metering hardening
