using System;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace LedgerLens.Core;

/// <summary>
/// Minimal client for Polar's public license-key validation endpoint. This is the only
/// network call the app makes; it sends only the license key + public organization id, never
/// any statement data.
/// </summary>
public static class PolarClient
{
    private static readonly HttpClient Http = new();

    public static async Task<(bool Valid, string? Message)> ValidateAsync(string licenseKey)
    {
        var key = (licenseKey ?? "").Trim();
        if (key.Length == 0) return (false, "Enter your license key.");
        if (PolarConfig.OrganizationId.StartsWith("REPLACE_", StringComparison.Ordinal))
            throw new InvalidOperationException("Polar isn't configured yet. Set OrganizationId in PolarConfig.cs.");

        var url = $"{PolarConfig.ApiBase}/v1/customer-portal/license-keys/validate";
        var payload = JsonSerializer.Serialize(new { key, organization_id = PolarConfig.OrganizationId });
        using var content = new StringContent(payload, Encoding.UTF8, "application/json");

        var response = await Http.PostAsync(url, content);
        var bodyText = await response.Content.ReadAsStringAsync();

        if ((int)response.StatusCode == 200)
        {
            try
            {
                using var doc = JsonDocument.Parse(bodyText);
                if (doc.RootElement.TryGetProperty("status", out var status))
                {
                    var ok = string.Equals(status.GetString(), "granted", StringComparison.OrdinalIgnoreCase);
                    return (ok, ok ? null : $"This license is {status.GetString()}.");
                }
            }
            catch (JsonException) { /* fall through to valid */ }
            return (true, null);
        }

        if ((int)response.StatusCode is 404 or 403)
            return (false, "That license key wasn't recognized.");

        return (false, $"Polar returned {(int)response.StatusCode}.");
    }
}
