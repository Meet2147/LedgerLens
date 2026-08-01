namespace LedgerLens.Models;

/// <summary>
/// One parsed statement line. Field names and semantics match the macOS app and the
/// web/server model so exports are interchangeable across platforms.
/// </summary>
public sealed class TransactionRow
{
    public string Id { get; init; } = "";

    /// <summary>Populated only for multi-file (batch) conversions.</summary>
    public string? SourceFile { get; set; }

    public string Date { get; init; } = "";
    public string ValueDate { get; init; } = "";
    public string Description { get; init; } = "";
    public string Debit { get; init; } = "";
    public string Credit { get; init; } = "";
    public string Balance { get; init; } = "";

    // Display helpers for the UI (empty money renders as an em dash).
    public string DebitDisplay => string.IsNullOrEmpty(Debit) ? "—" : Debit;
    public string CreditDisplay => string.IsNullOrEmpty(Credit) ? "—" : Credit;
    public string BalanceDisplay => string.IsNullOrEmpty(Balance) ? "—" : Balance;
}
