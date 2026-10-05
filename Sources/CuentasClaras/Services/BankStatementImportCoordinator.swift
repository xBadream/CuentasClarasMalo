import Foundation
#if canImport(SwiftData)
import SwiftData
#endif

public final class BankStatementImportCoordinator {
    private let parser: SecurityStatementParser
    private let validator: SecurityStatementValidator
    private let mapper: ParsedStatementMapper
    private let importer: SwiftDataStatementImporter

    public init(
        parser: SecurityStatementParser = SecurityStatementParser(),
        validator: SecurityStatementValidator = SecurityStatementValidator(),
        mapper: ParsedStatementMapper = ParsedStatementMapper(),
        importer: SwiftDataStatementImporter
    ) {
        self.parser = parser
        self.validator = validator
        self.mapper = mapper
        self.importer = importer
    }

    public func importPDF(from url: URL, account: BankAccount? = nil) throws -> BankStatement {
        let textExtractor = PDFTextExtractor()
        let rawText = try textExtractor.extractText(from: url)
        let parsed = try parser.parse(rawText, sourceFileName: url.lastPathComponent)

        guard validator.isValid(parsed) else {
            throw StatementImportError.invalidStatement
        }

        let statement = mapper.map(parsed, account: account)
        try importer.importStatement(statement)
        return statement
    }
}
