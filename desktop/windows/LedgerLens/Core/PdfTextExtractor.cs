using System;
using System.Collections.Generic;
using System.Linq;
using UglyToad.PdfPig;
using UglyToad.PdfPig.Content;
using UglyToad.PdfPig.Exceptions;

namespace LedgerLens.Core;

/// <summary>
/// On-device PDF text extraction using PdfPig — the Windows counterpart to the macOS app's
/// PDFKit extractor. Reconstructs layout-preserving lines from word bounding boxes: group
/// words into rows by vertical position, sort each row left-to-right, and join with spaces.
/// The resulting text feeds <see cref="StatementParsing"/> unchanged.
///
/// Everything runs locally — the PDF bytes never leave the machine.
/// </summary>
public static class PdfTextExtractor
{
    public sealed class ExtractionException : Exception
    {
        public ExtractionException(string message) : base(message) { }
    }

    public sealed class Extraction
    {
        public int PageCount { get; init; }
        public string Text { get; init; } = "";
    }

    public static Extraction Extract(string filePath, string password)
    {
        var options = new ParsingOptions
        {
            // Try the supplied password plus the common empty password.
            Passwords = new List<string> { password ?? "", "" }
        };

        PdfDocument document;
        try
        {
            document = PdfDocument.Open(filePath, options);
        }
        catch (PdfDocumentEncryptedException)
        {
            throw new ExtractionException(
                string.IsNullOrEmpty(password)
                    ? "This PDF is password protected. Enter its password and try again."
                    : "The PDF password is incorrect. Please re-enter it and try again.");
        }

        using (document)
        {
            var pageTexts = new List<string>();
            foreach (var page in document.GetPages())
            {
                pageTexts.Add(LayoutText(page));
            }

            // Join pages with a form feed, matching the parser's page-boundary handling.
            return new Extraction
            {
                PageCount = document.NumberOfPages,
                Text = string.Join("\f", pageTexts)
            };
        }
    }

    /// <summary>
    /// Rebuilds column-preserving text for a page from word bounding boxes: group words into
    /// lines by vertical position (PDF origin is bottom-left, so higher Y == earlier line),
    /// then order each line left-to-right.
    /// </summary>
    private static string LayoutText(Page page)
    {
        var words = page.GetWords()
            .Where(w => !string.IsNullOrWhiteSpace(w.Text))
            .ToList();
        if (words.Count == 0) return "";

        var heights = words.Select(w => Math.Abs(w.BoundingBox.Height)).OrderBy(h => h).ToList();
        var medianHeight = heights[heights.Count / 2];
        var tolerance = Math.Max(medianHeight * 0.5, 1.0);

        var sorted = words.OrderByDescending(w => w.BoundingBox.Centroid.Y).ToList();

        var lines = new List<List<Word>>();
        var currentLine = new List<Word>();
        double baseline = sorted[0].BoundingBox.Centroid.Y;

        foreach (var word in sorted)
        {
            var y = word.BoundingBox.Centroid.Y;
            if (currentLine.Count == 0)
            {
                currentLine.Add(word);
                baseline = y;
            }
            else if (Math.Abs(y - baseline) <= tolerance)
            {
                currentLine.Add(word);
                baseline = (baseline * (currentLine.Count - 1) + y) / currentLine.Count;
            }
            else
            {
                lines.Add(currentLine);
                currentLine = new List<Word> { word };
                baseline = y;
            }
        }
        if (currentLine.Count > 0) lines.Add(currentLine);

        var rendered = lines.Select(line =>
            string.Join(" ", line.OrderBy(w => w.BoundingBox.Left).Select(w => w.Text)));

        return string.Join("\n", rendered);
    }
}
