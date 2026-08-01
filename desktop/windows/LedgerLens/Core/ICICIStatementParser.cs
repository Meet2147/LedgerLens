using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text.RegularExpressions;
using LedgerLens.Models;

namespace LedgerLens.Core;

/// <summary>
/// Parser template for ICICI Bank "Statement of Transactions" / OpTransactionHistory PDFs.
/// Direct port of the macOS app's <c>ICICIStatementParser</c>, verified against a real
/// 67-transaction statement (every balance = previous ± amount).
///
/// Structure:
///   &lt;S.No&gt; &lt;DD.MM.YYYY&gt; &lt;payee prefix&gt;   ← transaction start
///   UPI/....../....                                       ← 0..n remark lines
///   45.00 32363.05                                        ← &lt;amount&gt; &lt;balance&gt;
///
/// Withdrawal vs deposit isn't encoded in the collapsed text, so it's inferred from balance
/// movement.
/// </summary>
public static class ICICIStatementParser
{
    private const string Money = @"\d[\d,]*\.\d{2}";

    private static readonly Regex StartRegex = new(
        @"^(\d{1,6})\s+(\d{2}\.\d{2}\.\d{4})\s+(.+)$", RegexOptions.Compiled);

    private static readonly Regex AmountTailRegex = new(
        $@"^(.*?)((?:{Money}\s+)*{Money})\s*$", RegexOptions.Compiled);

    private static readonly Regex WhitespaceRegex = new(@"\s+", RegexOptions.Compiled);

    private sealed class Draft
    {
        public string Date = "";
        public List<string> Remarks = new();
        public double Amount;
        public double Balance;
        public string AmountText = "";
        public string BalanceText = "";
    }

    public static List<TransactionRow> Parse(string text)
    {
        var lines = text
            .Replace('\f', '\n')
            .Split('\n')
            .Select(l => l.Trim())
            .ToList();

        var drafts = new List<Draft>();
        Draft? current = null;

        void Flush()
        {
            if (current != null && !string.IsNullOrEmpty(current.AmountText))
            {
                drafts.Add(current);
            }
            current = null;
        }

        foreach (var raw in lines)
        {
            var line = raw.Trim();
            if (line.Length == 0) continue;

            var start = StartRegex.Match(line);
            if (start.Success)
            {
                Flush();
                current = new Draft
                {
                    Date = NormalizeDate(start.Groups[2].Value),
                    Remarks = new List<string> { start.Groups[3].Value }
                };
                continue;
            }

            // Everything before the first start line is statement preamble — skip it.
            if (current == null) continue;

            if (IsNoiseLine(line)) continue;

            var tail = AmountTailRegex.Match(line);
            if (tail.Success)
            {
                var leading = tail.Groups[1].Value.Trim();
                var numbers = tail.Groups[2].Value
                    .Split(new[] { ' ', '\t' }, StringSplitOptions.RemoveEmptyEntries);

                if (numbers.Length >= 2)
                {
                    if (leading.Length > 0 && !IsNoiseLine(leading))
                    {
                        current.Remarks.Add(leading);
                    }

                    var balanceText = numbers[^1];
                    // 3 tokens => explicit withdrawal, deposit, balance; otherwise a single
                    // amount whose direction is resolved later from balance movement.
                    var amountText = numbers.Length >= 3 ? numbers[0] : numbers[^2];
                    current.AmountText = amountText;
                    current.BalanceText = balanceText;
                    current.Amount = ParseMoney(amountText);
                    current.Balance = ParseMoney(balanceText);
                    Flush();
                    continue;
                }
                // A single trailing money token isn't an amount line — fall through as remark.
            }

            current.Remarks.Add(line);
        }

        Flush();
        return BuildRows(drafts);
    }

    private static List<TransactionRow> BuildRows(List<Draft> drafts)
    {
        var rows = new List<TransactionRow>();
        double? previousBalance = null;

        for (var index = 0; index < drafts.Count; index++)
        {
            var draft = drafts[index];
            bool isDeposit;
            if (previousBalance is double prev)
            {
                // Balance up => money in (deposit/credit); down => money out (withdrawal/debit).
                isDeposit = draft.Balance > prev + 0.001;
            }
            else
            {
                // First row's direction can't be derived; default to a withdrawal, the common case.
                isDeposit = false;
            }

            rows.Add(new TransactionRow
            {
                Id = $"row-{index + 1}",
                Date = draft.Date,
                ValueDate = draft.Date,
                Description = NormalizeWhitespace(string.Join(" ", draft.Remarks)),
                Debit = isDeposit ? "" : draft.AmountText,
                Credit = isDeposit ? draft.AmountText : "",
                Balance = draft.BalanceText
            });

            previousBalance = draft.Balance;
        }

        return rows.Take(5000).ToList();
    }

    private static string NormalizeDate(string value) => value.Replace('.', '/');

    private static double ParseMoney(string value) =>
        double.TryParse(value.Replace(",", ""), NumberStyles.Any, CultureInfo.InvariantCulture, out var d) ? d : 0;

    private static string NormalizeWhitespace(string value) =>
        WhitespaceRegex.Replace(value, " ").Trim();

    private static bool IsNoiseLine(string line) =>
        line.StartsWith("www.icici", StringComparison.Ordinal)
        || line.StartsWith("Please call", StringComparison.Ordinal)
        || line.StartsWith("Never share", StringComparison.Ordinal)
        || line.StartsWith("S No.", StringComparison.Ordinal)
        || line.StartsWith("Date Cheque", StringComparison.Ordinal)
        || line.StartsWith("Transaction Remarks", StringComparison.Ordinal)
        || line == "Withdrawal"
        || line == "Deposit"
        || line == "Balance"
        || line == "Amount (INR)"
        || line == "(INR)"
        || line.StartsWith("Sincerly", StringComparison.Ordinal)
        || line.StartsWith("Team ICICI", StringComparison.Ordinal)
        || line.StartsWith("This is a system generated", StringComparison.Ordinal)
        || line.StartsWith("Legends for", StringComparison.Ordinal)
        || line.StartsWith("Statement of Transactions", StringComparison.Ordinal);
}

/// <summary>
/// Chooses the best template for a statement by trying each and keeping whichever detects the
/// most rows. The templates key off mutually exclusive date formats (slash vs dot dates), so
/// the matching one wins and the other returns nothing.
/// </summary>
public static class StatementParsing
{
    public static List<TransactionRow> ParseBest(string text)
    {
        var original = StatementParser.Parse(text);
        var icici = ICICIStatementParser.Parse(text);
        return icici.Count > original.Count ? icici : original;
    }
}
