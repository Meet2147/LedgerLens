# LedgerLens for macOS (SwiftUI)

A native, fully local, sandboxed macOS app. Neumorphic UI, light/dark adaptive.

## Requirements

- macOS 13.0 or later
- Xcode 15 or later (built and tested with Xcode 26)

## Build & run

```bash
open LedgerLensDesktop.xcodeproj
```

Then press **⌘R**. To sign for distribution, select the target → *Signing & Capabilities*
and pick your team (the project defaults to team `C9NLF34677`; change it to yours).

Command line (unsigned local build):

```bash
xcodebuild -project LedgerLensDesktop.xcodeproj -scheme LedgerLensDesktop \
  -configuration Release -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO build
```

## Structure

```
LedgerLensDesktop/
├── LedgerLensDesktopApp.swift      App entry, menu commands
├── Core/
│   ├── StatementParser.swift       Original-format parser (verified == the web parser)
│   ├── ICICIStatementParser.swift  ICICI OpTransactionHistory template + StatementParsing dispatcher
│   ├── PDFTextExtractor.swift       Local text extraction via PDFKit
│   ├── StatementConverter.swift     Orchestration + filename stem normalization
│   ├── ZipArchive.swift             Minimal dependency-free ZIP writer (for XLSX)
│   └── SpreadsheetExporter.swift    CSV + XLSX (OOXML) generation
├── Models/                          TransactionRow, ConversionResult
├── ViewModels/ConverterModel.swift  ObservableObject: files, password, convert, export
├── Views/                           ContentView, InputPanel, ResultsPanel (custom neumorphic table)
├── Theme/BrandPalette.swift         Neumorphic design tokens + view modifiers
└── LedgerLensDesktop.entitlements   App sandbox; user-selected files; NO network
```

## Privacy

The entitlements request the App Sandbox, read-write access to **user-selected files only**,
and outgoing network (`network.client`) used **solely to validate a Polar license key** on
Pro activation. Statement contents are always processed locally and are never sent anywhere.

## Notes

- PDF text is extracted with PDFKit's `page.string`, then parsed by the same logic as the
  web app. Scanned/image-only PDFs (no embedded text) won't yield rows — OCR is future work.
- `ContentView` has an optional `LEDGERLENS_AUTOLOAD_PDF` env-var hook used for automated
  screenshots/testing; it does nothing in normal use.
