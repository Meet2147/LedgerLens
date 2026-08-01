# LedgerLens desktop scripts

## `polar/create-product.mjs` — create the Pro plans on Polar

Creates four plans — **Monthly $7/mo**, **Yearly $59/yr**, **Lifetime $99**, **Firm $29/mo
(25 seats)** — License Keys benefits (5 seats personal, 25 firm), and a checkout link per
plan, then prints the IDs + checkout URLs to paste into `PolarConfig.swift` / `PolarConfig.cs`.
The script is **idempotent** (reuses products/benefits by name), so it's safe to re-run. Uses
an Organization Access Token — the org is inferred, so don't set `organization_id`.

```bash
# production
POLAR_ACCESS_TOKEN=polar_oat_xxx node scripts/polar/create-product.mjs
# sandbox (test first!)
POLAR_SERVER=sandbox POLAR_ACCESS_TOKEN=polar_oat_xxx node scripts/polar/create-product.mjs
```

Get the token from **Polar → Settings → Developers**. Node 18+.

After it runs, paste the printed `organizationId` and `checkoutURL` into:
- macOS: `desktop/macos/LedgerLensDesktop/Core/PolarConfig.swift`
- Windows: `desktop/windows/LedgerLens/Core/PolarConfig.cs`

The app validates entered license keys against Polar's public validation endpoint; no secret
token ships in the app.

## `macos/sign_and_notarize.sh` — Developer-ID sign, notarize, staple, package

For selling **outside** the Mac App Store. One-time credential setup:

```bash
xcrun notarytool store-credentials "ledgerlens-notary" \
  --apple-id "you@example.com" --team-id "C9NLF34677" \
  --password "app-specific-password"
```

Then:

```bash
DEVELOPER_ID="Developer ID Application: Your Name (C9NLF34677)" \
  ./scripts/macos/sign_and_notarize.sh
```

Produces a signed + notarized + stapled `LedgerLensDesktop.dmg` that opens with no Gatekeeper
warning. You need a **Developer ID Application** certificate (Apple Developer Program, $99/yr)
in your login keychain.

> Windows signing: sign the built `.exe` with `signtool sign /fd SHA256 /tr <timestamp-url>
> /td SHA256 /a LedgerLens.exe` using an OV/EV code-signing certificate. EV certs avoid
> SmartScreen warnings immediately; OV certs build reputation over time.
