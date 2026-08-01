import SwiftUI

/// The Settings / Upgrade-to-Pro sheet. Shows usage-trial status, the three plans (each opens
/// its Polar checkout in the browser), and a license-key activation field.
struct SettingsView: View {
    @EnvironmentObject private var license: LicenseStore
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 20) {
                    statusCard
                    appearanceCard
                    if !license.isPro { plansCard }
                    activationCard
                }
                .padding(24)
            }
        }
        .frame(width: 480, height: 660)
        .background(BrandPalette.base)
        .preferredColorScheme(settings.colorScheme)
    }

    private var appearanceCard: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Appearance")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(BrandPalette.textPrimary)
                Text("Match your system or pick a mode")
                    .font(.system(size: 11.5))
                    .foregroundStyle(BrandPalette.textSecondary)
            }
            Spacer()
            Picker("", selection: $settings.appearance) {
                ForEach(AppAppearance.allCases) { mode in
                    Label(mode.label, systemImage: mode.symbol).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 210)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .neuInset(16)
    }

    private var header: some View {
        HStack {
            HStack(spacing: 10) {
                BrandMark(size: 30)
                Text("LedgerLens")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(BrandPalette.textPrimary)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(BrandPalette.textSecondary)
                    .frame(width: 28, height: 28)
                    .neuRaised(14)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    private var statusCard: some View {
        HStack(spacing: 14) {
            Image(systemName: license.isPro ? "checkmark.seal.fill" : "gift.fill")
                .font(.system(size: 26))
                .foregroundStyle(license.isPro ? BrandPalette.credit : BrandPalette.accent)
            VStack(alignment: .leading, spacing: 3) {
                Text(license.isPro ? "LedgerLens Pro" : license.statusText)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(BrandPalette.textPrimary)
                Text(license.isPro
                     ? "Thanks for supporting LedgerLens."
                     : "Your first \(license.freeStatements) statements are on us.")
                    .font(.system(size: 12))
                    .foregroundStyle(BrandPalette.textSecondary)
            }
            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .neuInset(16)
    }

    private var plansCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Go Pro")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(BrandPalette.textPrimary)
                Text("Unlimited conversions · batch PDFs · CSV + XLSX · 100% on-device")
                    .font(.system(size: 12))
                    .foregroundStyle(BrandPalette.textSecondary)
            }

            ForEach(ProPlan.personalPlans) { plan in
                planRow(plan)
            }

            Divider().padding(.vertical, 2)

            Text("FOR FIRMS & TEAMS")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(BrandPalette.textFaint)
            ForEach(ProPlan.businessPlans) { plan in
                planRow(plan)
            }

            Text("Any plan unlocks Pro. After checkout you'll get a license key — paste it below.")
                .font(.system(size: 11))
                .foregroundStyle(BrandPalette.textFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .neuRaised(18)
    }

    private func planRow(_ plan: ProPlan) -> some View {
        Button(action: { license.openCheckout(plan.checkoutURL) }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(BrandPalette.textPrimary)
                        if plan.isFeatured {
                            Text("BEST VALUE")
                                .font(.system(size: 8.5, weight: .heavy))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(BrandPalette.accent))
                        }
                    }
                    Text(plan.tagline)
                        .font(.system(size: 11))
                        .foregroundStyle(BrandPalette.textSecondary)
                }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(plan.price)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(BrandPalette.accent)
                    Text(plan.cadence)
                        .font(.system(size: 11))
                        .foregroundStyle(BrandPalette.textSecondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BrandPalette.textFaint)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .strokeBorder(plan.isFeatured ? BrandPalette.accent.opacity(0.6) : Color.clear, lineWidth: 1.5)
            )
            .neuInset(13)
        }
        .buttonStyle(.plain)
    }

    private var activationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(license.isPro ? "LICENSE" : "ALREADY PURCHASED?")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(BrandPalette.textFaint)

            HStack(spacing: 10) {
                TextField("Paste your license key", text: $license.licenseKeyInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(BrandPalette.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .neuInset(10)
                    .disabled(license.isPro)

                Button(action: { license.activate() }) {
                    Group {
                        if license.isActivating {
                            ProgressView().controlSize(.small)
                        } else {
                            Text(license.isPro ? "Active" : "Activate").fontWeight(.semibold)
                        }
                    }
                    .font(.system(size: 12))
                    .frame(width: 70, height: 38)
                }
                .buttonStyle(NeuButtonStyle(radius: 10, tint: BrandPalette.accent))
                .disabled(license.isPro || license.isActivating)
            }

            if let error = license.activationError {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(BrandPalette.debit)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .neuInset(16)
    }
}
