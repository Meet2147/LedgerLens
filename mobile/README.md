# LedgerLens Mobile

This folder contains the native mobile scaffolds for LedgerLens:

- `LedgerLensMobile/` — iOS SwiftUI app with a real `.xcodeproj`
- `android/` — Android Jetpack Compose scaffold

Both clients are designed to use the same LedgerLens account identity as the web app.

## Shared product rules

- No pricing screen inside the mobile app
- Login is required and matches the same email identity as the web app
- Trial access is shared across web and mobile:
  - 7 days
  - 5 PDFs total
  - 50 pages total

## Backend endpoints used

- `POST /api/mobile/login`
- `GET /api/account/summary`
- `POST /api/convert`
