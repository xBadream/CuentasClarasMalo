import SwiftUI

public struct ImportStatementView: View {
    @StateObject private var viewModel = ImportStatementViewModel()
    @State private var showingFilePicker = false

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Importar cartola PDF")
                .font(.title2.bold())

            Text("Selecciona un PDF de Banco Security para extraer, validar y guardar movimientos automáticamente.")
                .foregroundStyle(.secondary)

            Button(action: { showingFilePicker = true }) {
                HStack {
                    Image(systemName: "doc.badge.plus")
                    Text("Seleccionar PDF")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            if let error = viewModel.error {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Error", systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                }
                .padding()
                .background(Color(.systemRed).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            }

            if let preview = viewModel.previewData {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Preview de cartola")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        LabeledContent("Período", value: "\(formattedDate(preview.periodStart)) - \(formattedDate(preview.periodEnd))")
                        LabeledContent("Saldo inicial", value: preview.openingBalance.formatted(.currency(code: "CLP")))
                        LabeledContent("Saldo final", value: preview.accountingBalance.formatted(.currency(code: "CLP")))
                        LabeledContent("Movimientos", value: "\(preview.transactions.count)")
                        LabeledContent("Advertencias", value: "\(preview.warnings.count)")
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    if preview.warnings.count > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Advertencias", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            ForEach(preview.warnings.prefix(3), id: \.self) { warning in
                                Text("• \(warning)")
                                    .font(.caption)
                            }
                        }
                        .padding()
                        .background(Color(.systemOrange).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button("Confirmar importación") {
                        viewModel.importComplete = true
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Importar")
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.pdf],
            onCompletion: { result in
                if case .success(let url) = result {
                    viewModel.processURL(url)
                }
            }
        )
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        ImportStatementView()
    }
}
