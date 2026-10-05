import Foundation

public enum TransactionDirection {
    case debit
    case credit
}

public enum StatementImportStatus {
    case pending
    case imported
    case duplicate
    case invalid
}

public struct ParsedTransaction: Equatable {
    public let date: Date
    public let documentNumber: String
    public let transactionDescription: String
    public let debitAmount: Decimal?
    public let creditAmount: Decimal?
    public let resultingBalance: Decimal
    public let parserConfidence: Double
    public let sourcePage: Int
    public let sourceRawText: String
    public let requiresReview: Bool
    public let categoryName: String?
    public let importFingerprint: String

    public static func == (lhs: ParsedTransaction, rhs: ParsedTransaction) -> Bool {
        lhs.importFingerprint == rhs.importFingerprint
    }
}

public struct ParsedStatement: Equatable {
    public let statementNumber: String
    public let periodStart: Date
    public let periodEnd: Date
    public let issueDate: Date
    public let sourceFileName: String
    public let openingBalance: Decimal
    public let totalDebits: Decimal
    public let totalCredits: Decimal
    public let accountingBalance: Decimal
    public let availableBalance: Decimal
    public let totalFees: Decimal
    public let transactions: [ParsedTransaction]
    public let warnings: [String]
    public let importFingerprint: String
}
