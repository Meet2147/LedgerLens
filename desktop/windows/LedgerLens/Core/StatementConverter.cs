using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using LedgerLens.Models;

namespace LedgerLens.Core;

/// <summary>
/// Orchestrates local conversion of one or more PDF statements: extract layout text with
/// PdfPig, parse rows with the best-matching template, and assemble a <see cref="ConversionResult"/>.
/// On-device equivalent of the server's <c>/api/convert</c> route.
/// </summary>
public static class StatementConverter
{
    public sealed class ConversionException : Exception
    {
        public ConversionException(string message) : base(message) { }
    }

    public static ConversionResult Convert(IReadOnlyList<string> filePaths, string password)
    {
        var rows = new List<TransactionRow>();
        var totalPages = 0;
        var fileNames = new List<string>();
        var isBatch = filePaths.Count > 1;

        foreach (var path in filePaths)
        {
            var extraction = PdfTextExtractor.Extract(path, password);
            totalPages += extraction.PageCount;
            var name = Path.GetFileName(path);
            fileNames.Add(name);

            foreach (var row in StatementParsing.ParseBest(extraction.Text))
            {
                // Only tag rows with their source file in batch mode.
                row.SourceFile = isBatch ? name : null;
                rows.Add(row);
            }
        }

        // Renumber ids sequentially across the whole (possibly multi-file) result.
        rows = rows.Select((row, index) => new TransactionRow
        {
            Id = $"row-{index + 1}",
            SourceFile = row.SourceFile,
            Date = row.Date,
            ValueDate = row.ValueDate,
            Description = row.Description,
            Debit = row.Debit,
            Credit = row.Credit,
            Balance = row.Balance
        }).ToList();

        if (rows.Count == 0)
        {
            throw new ConversionException(
                "We opened the file but couldn't detect transaction rows yet. " +
                "Try a clearer statement, or add the PDF password if it's protected.");
        }

        var stem = isBatch ? "ledgerlens-batch" : NormalizeFileStem(fileNames.FirstOrDefault() ?? "statement.pdf");

        return new ConversionResult
        {
            FileStem = stem,
            PageCount = totalPages,
            Rows = rows,
            SourceFiles = fileNames
        };
    }

    /// <summary>Port of <c>normalizeFileStem</c> from <c>app/api/convert/route.js</c>.</summary>
    public static string NormalizeFileStem(string filename)
    {
        var stem = Regex.Replace(filename, @"\.pdf$", "", RegexOptions.IgnoreCase);
        stem = Regex.Replace(stem, @"[^a-z0-9-_]+", "-", RegexOptions.IgnoreCase);
        stem = stem.ToLowerInvariant();
        stem = Regex.Replace(stem, @"^-+|-+$", "");
        return stem.Length == 0 ? "statement" : stem;
    }
}
