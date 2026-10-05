import SwiftUI

public struct ImportStatementView: View {
    @State private var showPreview = false

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Importar cartola PDF")
                .font(.title2.bold())

            Text("Selecciona un PDF de Banco Security para extraer, validar y guardar movimientos.")
                .foregroundStyle(.secondary)

            Button(action: { showPreview = true }) {
                Label("Seleccionar PDF", systemImage: "doc.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            if showPreview {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Preview detectado")
                        .font(.headline)
                    Text("0000309768 7.980 COMPRA MERCADO URBANO TO 01/09 4.087.477")
                    Text("1015910136 TRANSFERENCIA DESDE CHILE DE PERSONA 03/09 72.999 2.695.705")
                    Button("Confirmar importación") { showPreview = false }
                        .buttonStyle(.bordered)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding()
        .navigationTitle("Importar")
    }
}
