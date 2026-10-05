import Foundation
#if canImport(SwiftData)
import SwiftData
#endif

public final class SwiftDataStatementImporter {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    public func importStatement(_ statement: BankStatement) throws {
        let predicate = #Predicate<BankStatement> { $0.importFingerprint == statement.importFingerprint }
        let descriptor = FetchDescriptor(predicate: predicate)
        let existing = try modelContext.fetch(descriptor)
        guard existing.isEmpty else { throw StatementImportError.duplicatedStatement }

        modelContext.insert(statement)
        try modelContext.save()
    }
}
