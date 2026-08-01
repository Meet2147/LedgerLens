import SwiftUI

/// Detail area: a toolbar with stats + export actions, and a custom neumorphic table — or an
/// empty / progress state before conversion.
struct ResultsPanel: View {
    @EnvironmentObject private var model: ConverterModel

    var body: some View {
        VStack(spacing: 0) {
            if let result = model.result {
                Toolbar(result: result)
                SoftTable(result: result)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            } else {
                EmptyState(isConverting: model.isConverting)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BrandPalette.base)
        .fileExporter(
            isPresented: $model.showExporter,
            document: model.exportDocument,
            contentType: model.exportContentType,
            defaultFilename: model.exportFilename,
            onCompletion: model.handleExport
        )
    }
}

// MARK: - Column layout shared by header and rows

private enum Col {
    static let date: CGFloat = 96
    static let debit: CGFloat = 104
    static let credit: CGFloat = 104
    static let balance: CGFloat = 118
    static let source: CGFloat = 140
}

// MARK: - Toolbar

private struct Toolbar: View {
    @EnvironmentObject private var model: ConverterModel
    let result: ConversionResult

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Converted transactions")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(BrandPalette.textPrimary)
                HStack(spacing: 9) {
                    StatPill(value: "\(result.rows.count)", label: result.rows.count == 1 ? "row" : "rows")
                    StatPill(value: "\(result.pageCount)", label: "pages")
                    StatPill(value: "\(result.sourceFiles.count)", label: result.sourceFiles.count == 1 ? "file" : "files")
                }
            }

            Spacer()

            HStack(spacing: 10) {
                Button(action: { model.exportCSV() }) {
                    Label("CSV", systemImage: "tablecells")
                }
                .buttonStyle(NeuButtonStyle(radius: 11, tint: BrandPalette.textSecondary))

                Button(action: { model.exportXLSX() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Export XLSX")
                    }
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(BrandPalette.brandGradient)
                            .shadow(color: BrandPalette.accent.opacity(0.45), radius: 6, x: 3, y: 3)
                            .shadow(color: BrandPalette.lightShadow.opacity(0.8), radius: 5, x: -3, y: -3)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 26)
        .padding(.top, 40)
        .padding(.bottom, 18)
    }
}

private struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                .foregroundStyle(BrandPalette.accent)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(BrandPalette.textSecondary)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .neuRaised(20)
    }
}

// MARK: - Custom neumorphic table

private struct SoftTable: View {
    let result: ConversionResult

    var body: some View {
        VStack(spacing: 0) {
            headerRow
                .padding(.horizontal, 18)
                .padding(.vertical, 12)

            Rectangle()
                .fill(BrandPalette.darkShadow.opacity(0.25))
                .frame(height: 1)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(result.rows.enumerated()), id: \.element.id) { index, row in
                        RowView(row: row, isBatch: result.isBatch, even: index % 2 == 0)
                        if index < result.rows.count - 1 {
                            Rectangle()
                                .fill(BrandPalette.darkShadow.opacity(0.12))
                                .frame(height: 1)
                                .padding(.horizontal, 18)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .neuInset(18)
    }

    private var headerRow: some View {
        HStack(spacing: 12) {
            headerCell("DATE", width: Col.date, align: .leading)
            if result.isBatch { headerCell("SOURCE", width: Col.source, align: .leading) }
            headerCell("DESCRIPTION", width: nil, align: .leading)
            headerCell("DEBIT", width: Col.debit, align: .trailing)
            headerCell("CREDIT", width: Col.credit, align: .trailing)
            headerCell("BALANCE", width: Col.balance, align: .trailing)
        }
    }

    private func headerCell(_ text: String, width: CGFloat?, align: Alignment) -> some View {
        Text(text)
            .font(.system(size: 10.5, weight: .bold))
            .tracking(0.6)
            .foregroundStyle(BrandPalette.textFaint)
            .frame(width: width, alignment: align)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: align)
    }
}

private struct RowView: View {
    let row: TransactionRow
    let isBatch: Bool
    let even: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(row.date)
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(BrandPalette.textSecondary)
                .frame(width: Col.date, alignment: .leading)

            if isBatch {
                Text(row.sourceFile ?? "")
                    .font(.system(size: 11.5))
                    .foregroundStyle(BrandPalette.textFaint)
                    .lineLimit(1).truncationMode(.middle)
                    .frame(width: Col.source, alignment: .leading)
            }

            Text(row.description)
                .font(.system(size: 12.5))
                .foregroundStyle(BrandPalette.textPrimary)
                .lineLimit(1).truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .help(row.description)

            money(row.debit, tone: BrandPalette.debit, width: Col.debit)
            money(row.credit, tone: BrandPalette.credit, width: Col.credit)
            money(row.balance, tone: BrandPalette.textPrimary, width: Col.balance, bold: true)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
        .background(even ? Color.clear : BrandPalette.lightShadow.opacity(0.18))
    }

    private func money(_ text: String, tone: Color, width: CGFloat, bold: Bool = false) -> some View {
        Text(text.isEmpty ? "—" : text)
            .font(.system(size: 12.5, weight: bold ? .semibold : .regular).monospacedDigit())
            .foregroundStyle(text.isEmpty ? BrandPalette.textFaint : tone)
            .frame(width: width, alignment: .trailing)
    }
}

// MARK: - Empty / progress state

private struct EmptyState: View {
    let isConverting: Bool

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            ZStack {
                Circle()
                    .fill(BrandPalette.base)
                    .frame(width: 96, height: 96)
                    .neuRaised(48)
                Image(systemName: isConverting ? "hourglass" : "tablecells")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(BrandPalette.accent)
            }
            if isConverting {
                Text("Reading and parsing locally…")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(BrandPalette.textSecondary)
            } else {
                Text("Your transactions will appear here")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(BrandPalette.textPrimary)
                Text("Add one or more PDF bank statements on the left,\nthen press Convert.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(BrandPalette.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
