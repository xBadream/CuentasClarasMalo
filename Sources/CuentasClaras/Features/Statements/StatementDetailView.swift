import SwiftUI

public struct StatementDetailView: View {
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Resumen financiero")
                    .font(.title2.weight(.semibold))
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                    GridRow {
                        Text("Saldo inicial")
                        Text("$ 1.000.000")
                    }
                    GridRow {
                        Text("Abonos")
                        Text("$ 315.000")
                    }
                    GridRow {
                        Text("Cargos")
                        Text("$ 130.000")
                    }
                    GridRow {
                        Text("Saldo final")
                        Text("$ 1.185.000")
                    }
                }

                CreditLineCard(approved: 600000, used: 170000, available: 430000)

                Text("Advertencias")
                    .font(.headline)
                Text("Sin advertencias críticas.")
                    .foregroundStyle(.secondary)

                NavigationLink(destination: TransactionDetailView()) {
                    Label("Ver detalle de transacciones", systemImage: "list.bullet")
                }
            }
            .padding()
        }
        .navigationTitle("Detalle de cartola")
    }
}
