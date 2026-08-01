using System.Collections.Generic;

namespace LedgerLens.Core;

/// <summary>
/// Polar configuration. Fill these in after running `scripts/polar/create-product.mjs`.
/// Only a license key + these public identifiers ever touch the network — statement data
/// never does.
/// </summary>
public static class PolarConfig
{
    public const string OrganizationId = "36a24ca3-4af7-4c52-8fac-7243fb07019a";

    // Hosted checkout links, one per plan.
    public const string CheckoutMonthlyUrl = "https://buy.polar.sh/polar_cl_2aWIgE5WYJaaY1kmhD7i0tQx3i4661C0AgpAU2jnjBq";
    public const string CheckoutYearlyUrl = "https://buy.polar.sh/polar_cl_Yd9JYxJra1oQdNzoHYG4rFpGLnX5VlVgmc0xb1PUo8x";
    public const string CheckoutLifetimeUrl = "https://buy.polar.sh/polar_cl_kJrdPRW9FF64ttGwYz0wqYd0diZfAew6McP3y1EmzNY";
    public const string CheckoutFirmUrl = "https://buy.polar.sh/polar_cl_bd6Ly3fkUldjOW6zB7BccMUs2tUbuliNq3nST2wCUGl";

    /// <summary>Polar API base. Use "https://sandbox-api.polar.sh" while testing.</summary>
    public const string ApiBase = "https://api.polar.sh";
}

/// <summary>A purchase option shown in the upgrade dialog.</summary>
public sealed record ProPlan(string Title, string Price, string Cadence, string Tagline, string CheckoutUrl, bool Featured, bool Business = false)
{
    public static IReadOnlyList<ProPlan> All { get; } = new[]
    {
        new ProPlan("Monthly",  "$7",  "/mo",  "Cancel anytime",          PolarConfig.CheckoutMonthlyUrl,  false),
        new ProPlan("Yearly",   "$59", "/yr",  "Save ~30% vs monthly",    PolarConfig.CheckoutYearlyUrl,   false),
        new ProPlan("Lifetime", "$99", "once", "Pay once, own forever",   PolarConfig.CheckoutLifetimeUrl, true),
        new ProPlan("Firm",     "$29", "/mo",  "For firms · up to 25 seats", PolarConfig.CheckoutFirmUrl,  false, Business: true),
    };
}
