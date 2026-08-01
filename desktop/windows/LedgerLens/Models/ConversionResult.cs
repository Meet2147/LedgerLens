using System.Collections.Generic;

namespace LedgerLens.Models;

/// <summary>The outcome of converting one or more PDF statements locally.</summary>
public sealed class ConversionResult
{
    public string FileStem { get; init; } = "statement";
    public int PageCount { get; init; }
    public IReadOnlyList<TransactionRow> Rows { get; init; } = new List<TransactionRow>();
    public IReadOnlyList<string> SourceFiles { get; init; } = new List<string>();

    /// <summary>True once more than one statement contributed rows.</summary>
    public bool IsBatch => SourceFiles.Count > 1;
}
