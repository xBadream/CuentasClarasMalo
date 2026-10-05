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
        let descriptor = FetchDescriptor<BankStatement>(predicate: #Predicate { $0.importFingerprint == statement.importFingerprint })
        let existing = try modelContext.fetch(descriptor)
        guard existing.isEmpty else {
            throw ImportError.duplicateStatement
        }

        modelContext.insert(statement)
        try modelContext.save()
    }

    public enum ImportError: Error {
        case duplicateStatement
        case invalidContext
    }
}
