import SwiftUI

public struct ImportStatementView: View {
    @State private var isImporting = false

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Importar cartola PDF")
                .font(.title2.weight(.semibold))
            Text("Selecciona un PDF de Banco Security para extraer, validar y persistir movimientos.")
                .foregroundStyle(.secondary)

            Button(action: { isImporting = true }) {
                Label("Seleccionar PDF", systemImage: "doc.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            if isImporting {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview del contenido detectado")
                        .font(.headline)
                    Text("0000309768 7.980 COMPRA MERCADO URBANO TO 01/09 4.087.477")
                    Text("1015910136 TRANSFERENCIA DESDE Chile DE PERSONA 03/09 72.999 2.695.705")
                    Button("Confirmar importación") {
                        isImporting = false
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .navigationTitle("Importar")
    }
}
