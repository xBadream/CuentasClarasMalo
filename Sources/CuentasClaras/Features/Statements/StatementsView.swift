import SwiftUI

public struct StatementsView: View {
    public init() {}

    public var body: some View {
        List {
            StatementRow(name: "Cartola Banco Security", period: "01/09 - 30/09", amount: "$ 1.285.000")
            StatementRow(name: "Cartola Banco Security", period: "01/08 - 31/08", amount: "$ 1.240.000")
        }
        .navigationTitle("Cartolas")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: ImportStatementView()) {
                    Image(systemName: "square.and.arrow.down")
                }
            }
        }
    }
}

private struct StatementRow: View {
    let name: String
    let period: String
    let amount: String

    var body: some View {
        NavigationLink(destination: StatementDetailView()) {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                Text(period)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(amount)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
            }
            .padding(.vertical, 4)
        }
    }
}
