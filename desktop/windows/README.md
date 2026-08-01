# LedgerLens for Windows (WinUI 3 / .NET)

A native, fully local Windows app. WinUI 3 with an adaptive neumorphic-inspired UI.

## Requirements

- Windows 10 (1809 / build 17763) or later, or Windows 11
- Visual Studio 2022 with these workloads/components:
  - **.NET Desktop Development**
  - **Windows App SDK** (Windows App SDK C# templates)
  - .NET 8 SDK
- The app is **unpackaged** (`<WindowsPackageType>None</WindowsPackageType>`), so it builds to
  a plain `.exe` — no MSIX or developer-mode packaging needed to run/debug.

## Build & run

```powershell
cd desktop\windows
dotnet restore            # pulls Microsoft.WindowsAppSDK + UglyToad.PdfPig
```

Then open `LedgerLens.sln` in Visual Studio, pick your platform (**x64** or **ARM64**), and
press **F5**. Or from the CLI:

```powershell
dotnet run --project LedgerLens\LedgerLens.csproj -f net8.0-windows10.0.19041.0
```

> NuGet package versions in `LedgerLens.csproj` (Windows App SDK, PdfPig) are pinned to known
> releases; if `restore` reports a newer/only-available version, let it update them.

## Structure

```
LedgerLens/
├── App.xaml(.cs)                    App shell + adaptive theme brushes (Light/Dark)
├── MainWindow.xaml(.cs)             UI, pickers, drag-drop, export handlers
├── Core/
│   ├── StatementParser.cs           Original-format parser (line-for-line port of the web parser)
│   ├── ICICIStatementParser.cs      ICICI template + StatementParsing dispatcher
│   ├── PdfTextExtractor.cs          Local extraction via PdfPig (word boxes → lines)
│   ├── StatementConverter.cs        Orchestration + filename stem normalization
│   └── SpreadsheetExporter.cs       CSV + XLSX via System.IO.Compression (no spreadsheet deps)
├── Models/                          TransactionRow, ConversionResult
├── ViewModels/ConverterViewModel.cs INotifyPropertyChanged: files, password, convert, export
├── Converters/Converters.cs         BoolToVisibility
└── app.manifest                     Per-monitor DPI awareness
```

## How local extraction works

PdfPig opens the PDF and returns per-word bounding boxes. `PdfTextExtractor` groups words into
lines by vertical position and orders each line left-to-right, reproducing the layout-preserving
text the parsers expect. Passwords are passed to `PdfPig.PdfDocument.Open`; encrypted PDFs with
a missing/incorrect password surface a friendly message.

## Status

The parsing/extraction/export **core is a faithful port of the macOS/web logic**, which was
verified byte-for-byte against the original JavaScript parser and against a real
67-transaction ICICI statement. Because there is no .NET toolchain on the machine this was
authored on, the C# was not compiled here — **build once in Visual Studio on Windows** and run
against a couple of real statements to confirm PdfPig's line reconstruction matches your bank's
layout. If a particular bank's text comes out differently, the fix is a new parser template in
`Core/` (same shape as `ICICIStatementParser`).

## Privacy

All processing is local (PdfPig runs in-process). The app makes no network calls — statements
never leave the PC.
