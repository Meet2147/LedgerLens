# LedgerLensMobile

SwiftUI starter for the LedgerLens iOS app.

## Current scope

- Email login against the existing LedgerLens web user base
- Shared trial/tier/account state from the web backend
- Mobile palette aligned with the web app
- Home, converter, and account tabs
- Converter UI scaffold ready to connect to the same `/api/convert` backend

## Backend assumption

Set the app's `baseURL` to the deployed LedgerLens web app domain, for example:

`https://ledger.dashovia.com`

The mobile app calls:

- `POST /api/mobile/login`
- `GET /api/account/summary`
- `POST /api/convert`

For MVP, the mobile app identifies the user by email using the `x-ledgerlens-email` header so it
matches the same account record used by the web app.
