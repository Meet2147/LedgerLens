using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using LedgerLens.Models;

namespace LedgerLens.Core;

/// <summary>
/// C# port of <c>lib/statement-parser.js</c> (<c>parseTransactionsFromLayoutText</c> and its
/// helpers). Regexes, ignore rules, and control flow mirror the web/server parser exactly —
/// the same logic verified byte-for-byte in the macOS app — so all platforms emit identical
/// rows for the same layout text.
/// </summary>
public static class StatementParser
{
    private const string DatePattern = @"\d{2}/\d{2}/\d{4}";
    private const string MoneyToken = @"(?:-|[\d,]+\.\d{2}(?:CR|DR)?)";

    private static readonly Regex DateRegex = new(DatePattern, RegexOptions.Compiled);
    private static readonly Regex LeadingNumericRegex = new(@"^\d[\d,.\sA-Z()/-]+$", RegexOptions.Compiled);

    private static readonly Regex TransactionLineRegex = new(
        $@"^({DatePattern})\s+({DatePattern})\s+(.+?)\s+({MoneyToken})\s+({MoneyToken})\s+({MoneyToken})\s+({MoneyToken})\s*$",
        RegexOptions.Compiled);

    private static readonly Regex WhitespaceRegex = new(@"\s+", RegexOptions.Compiled);

    /// <summary>Parses transaction rows from layout-preserving text, capped at 5000 rows.</summary>
    public static List<TransactionRow> Parse(string text)
    {
        return ParseTransactions(text).Take(5000).ToList();
    }

    private static string NormalizeWhitespace(string value) =>
        WhitespaceRegex.Replace(value, " ").Trim();

    private static string CleanMoney(string value)
    {
        var normalized = NormalizeWhitespace(value);
        if (string.IsNullOrEmpty(normalized) || normalized == "-") return "";
        if (normalized.EndsWith("DR", StringComparison.Ordinal)) return "-" + normalized[..^2];
        if (normalized.EndsWith("CR", StringComparison.Ordinal)) return normalized[..^2];
        return normalized;
    }

    private static bool IsIgnorableLine(string line)
    {
        if (string.IsNullOrEmpty(line)
            || line == "\f"
            || line.StartsWith("Page no.", StringComparison.Ordinal)
            || line.StartsWith("Statement Summary", StringComparison.Ordinal)
            || line.StartsWith("Please do not share your ATM", StringComparison.Ordinal)
            || line.StartsWith("If your account is operated", StringComparison.Ordinal)
            || line.StartsWith("This is a computer generated statement", StringComparison.Ordinal)
            || line == "Balance"
            || line == "Welcome:"
            || line.StartsWith("Account Summary", StringComparison.Ordinal)
            || line.StartsWith("STATEMENT OF ACCOUNT", StringComparison.Ordinal)
            || line.StartsWith("Brought Forward", StringComparison.Ordinal)
            || line.StartsWith("Total Debits", StringComparison.Ordinal)
            || line.StartsWith("Total Credits", StringComparison.Ordinal)
            || line.StartsWith("Closing Balance", StringComparison.Ordinal)
            || line.StartsWith("anyone via email", StringComparison.Ordinal)
            || line.StartsWith("Bank never asks for such information", StringComparison.Ordinal))
        {
            return true;
        }

        return !DateRegex.IsMatch(line) && LeadingNumericRegex.IsMatch(line);
    }

    private sealed class Pending
    {
        public string Date = "";
        public string ValueDate = "";
        public List<string> DescriptionParts = new();
        public string Debit = "";
        public string Credit = "";
        public string Balance = "";
    }

    private static List<TransactionRow> ParseTransactions(string text)
    {
        var lines = text
            .Replace('\f', '\n')
            .Split('\n')
            .Select(line => line.Replace("\0", ""))   // strip null chars (mirrors the JS null-strip)
            .Select(line => line.TrimEnd())
            .ToList();

        var rows = new List<TransactionRow>();
        Pending? pending = null;
        var carryoverDescriptionParts = new List<string>();
        var awaitingNextRowAfterPageBreak = false;

        void FlushPending()
        {
            if (pending == null) return;
            rows.Add(new TransactionRow
            {
                Id = $"row-{rows.Count + 1}",
                Date = pending.Date,
                ValueDate = pending.ValueDate,
                Description = NormalizeWhitespace(string.Join(" ", pending.DescriptionParts)),
                Debit = pending.Debit,
                Credit = pending.Credit,
                Balance = pending.Balance
            });
            pending = null;
        }

        for (var index = 0; index < lines.Count; index++)
        {
            var line = lines[index].Trim();

            if (line.StartsWith("Page no.", StringComparison.Ordinal))
            {
                FlushPending();
                awaitingNextRowAfterPageBreak = true;
                carryoverDescriptionParts = new List<string>();
                continue;
            }

            if (IsIgnorableLine(line)) continue;

            var match = TransactionLineRegex.Match(line);
            if (match.Success)
            {
                FlushPending();
                pending = new Pending
                {
                    Date = match.Groups[1].Value,
                    ValueDate = match.Groups[2].Value,
                    DescriptionParts = new List<string>(carryoverDescriptionParts) { match.Groups[3].Value },
                    Debit = CleanMoney(match.Groups[5].Value),
                    Credit = CleanMoney(match.Groups[6].Value),
                    Balance = CleanMoney(match.Groups[7].Value)
                };
                carryoverDescriptionParts = new List<string>();
                awaitingNextRowAfterPageBreak = false;
                continue;
            }

            if (awaitingNextRowAfterPageBreak && pending == null)
            {
                carryoverDescriptionParts.Add(line);
                continue;
            }

            if (pending == null) continue;

            if (DateRegex.IsMatch(line))
            {
                FlushPending();
                continue;
            }

            var nextMeaningfulLine = "";
            for (var cursor = index + 1; cursor < lines.Count; cursor++)
            {
                var candidate = lines[cursor].Trim();
                if (string.IsNullOrEmpty(candidate) || IsIgnorableLine(candidate)) continue;
                nextMeaningfulLine = candidate;
                break;
            }

            if (!string.IsNullOrEmpty(nextMeaningfulLine) && TransactionLineRegex.IsMatch(nextMeaningfulLine))
            {
                carryoverDescriptionParts = new List<string> { line };
                FlushPending();
                awaitingNextRowAfterPageBreak = false;
                continue;
            }

            pending.DescriptionParts.Add(line);
        }

        FlushPending();
        return rows;
    }
}
