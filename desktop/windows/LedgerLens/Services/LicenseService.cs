using System;
using System.Diagnostics;
using System.Threading.Tasks;
using LedgerLens.Core;
using Microsoft.Win32;

namespace LedgerLens.Services;

/// <summary>
/// Tracks a usage-based free trial (first N statements free) and Pro entitlement, persisted
/// under HKCU\Software\LedgerLens (works for unpackaged apps). Statement processing is always
/// local regardless of license state.
/// </summary>
public sealed class LicenseService
{
    private const string RegPath = @"Software\LedgerLens";
    public const int FreeStatements = 5;

    public bool IsPro { get; private set; }
    public int StatementsUsed { get; private set; }
    public string LicenseKey { get; private set; } = "";

    public LicenseService()
    {
        using var key = Registry.CurrentUser.CreateSubKey(RegPath);
        IsPro = (key.GetValue("IsPro") as string) == "1";
        LicenseKey = key.GetValue("LicenseKey") as string ?? "";
        StatementsUsed = int.TryParse(key.GetValue("StatementsUsed") as string, out var n) ? n : 0;
    }

    public int StatementsRemaining => Math.Max(0, FreeStatements - StatementsUsed);
    public bool IsTrialActive => StatementsRemaining > 0;
    public bool CanConvert => IsPro || StatementsRemaining > 0;

    public string StatusText =>
        IsPro ? "Pro"
        : StatementsRemaining > 0 ? $"{StatementsRemaining} of {FreeStatements} free left"
        : "Free statements used";

    public string PillText =>
        IsPro ? "PRO"
        : StatementsRemaining > 0 ? $"FREE · {StatementsRemaining} LEFT"
        : "UPGRADE";

    /// <summary>Counts converted statements against the free allowance (no-op once Pro).</summary>
    public void RegisterConversion(int statements)
    {
        if (IsPro) return;
        StatementsUsed += Math.Max(0, statements);
        using var key = Registry.CurrentUser.CreateSubKey(RegPath);
        key.SetValue("StatementsUsed", StatementsUsed.ToString());
    }

    public void OpenCheckout(string url)
    {
        Process.Start(new ProcessStartInfo(url) { UseShellExecute = true });
    }

    /// <summary>Validates a key with Polar; on success, unlocks Pro and persists it.</summary>
    public async Task<(bool Ok, string? Message)> ActivateAsync(string licenseKey)
    {
        var (valid, message) = await PolarClient.ValidateAsync(licenseKey);
        if (valid)
        {
            IsPro = true;
            LicenseKey = licenseKey.Trim();
            using var key = Registry.CurrentUser.CreateSubKey(RegPath);
            key.SetValue("IsPro", "1");
            key.SetValue("LicenseKey", LicenseKey);
        }
        return (valid, message);
    }
}
