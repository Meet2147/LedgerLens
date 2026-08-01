import Foundation

/// Central place for your Polar configuration. Fill these in after running
/// `scripts/polar/create-product.mjs` (it prints the IDs and all three checkout links).
///
/// Only a license key + these public identifiers ever touch the network — statement data
/// never does. See `PolarClient` for the (public, unauthenticated) validation call.
enum PolarConfig {
    /// Your Polar organization id (UUID). From the Polar dashboard or the create-product script.
    static let organizationId = "36a24ca3-4af7-4c52-8fac-7243fb07019a"

    /// Hosted checkout links, one per plan (Polar → Products → Checkout Link).
    static let checkoutMonthlyURL = URL(string: "https://buy.polar.sh/polar_cl_2aWIgE5WYJaaY1kmhD7i0tQx3i4661C0AgpAU2jnjBq")!
    static let checkoutYearlyURL = URL(string: "https://buy.polar.sh/polar_cl_Yd9JYxJra1oQdNzoHYG4rFpGLnX5VlVgmc0xb1PUo8x")!
    static let checkoutLifetimeURL = URL(string: "https://buy.polar.sh/polar_cl_kJrdPRW9FF64ttGwYz0wqYd0diZfAew6McP3y1EmzNY")!
    static let checkoutFirmURL = URL(string: "https://buy.polar.sh/polar_cl_bd6Ly3fkUldjOW6zB7BccMUs2tUbuliNq3nST2wCUGl")!

    /// Polar API base. Use "https://sandbox-api.polar.sh" while testing.
    static let apiBase = URL(string: "https://api.polar.sh")!
}

/// The purchase options shown in Settings. `firm` is the team/business tier for accounting
/// firms processing many clients' statements.
enum ProPlan: CaseIterable, Identifiable {
    case monthly, yearly, lifetime, firm

    var id: Self { self }

    /// Personal plans vs the business tier (shown under separate headings).
    static var personalPlans: [ProPlan] { [.monthly, .yearly, .lifetime] }
    static var businessPlans: [ProPlan] { [.firm] }

    var title: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .lifetime: return "Lifetime"
        case .firm: return "Firm"
        }
    }

    var price: String {
        switch self {
        case .monthly: return "$7"
        case .yearly: return "$59"
        case .lifetime: return "$99"
        case .firm: return "$29"
        }
    }

    var cadence: String {
        switch self {
        case .monthly: return "/mo"
        case .yearly: return "/yr"
        case .lifetime: return "once"
        case .firm: return "/mo"
        }
    }

    var tagline: String {
        switch self {
        case .monthly: return "Cancel anytime"
        case .yearly: return "Save ~30% vs monthly"
        case .lifetime: return "Pay once, own forever"
        case .firm: return "For firms · up to 25 seats"
        }
    }

    var isFeatured: Bool { self == .lifetime }

    var checkoutURL: URL {
        switch self {
        case .monthly: return PolarConfig.checkoutMonthlyURL
        case .yearly: return PolarConfig.checkoutYearlyURL
        case .lifetime: return PolarConfig.checkoutLifetimeURL
        case .firm: return PolarConfig.checkoutFirmURL
        }
    }
}
