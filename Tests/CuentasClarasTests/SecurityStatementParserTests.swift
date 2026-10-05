import Foundation
import XCTest
@testable import CuentasClaras

final class SecurityStatementParserTests: XCTestCase {
    func testParsesSecuritySampleTransaction() throws {
        let parser = SecurityStatementParser()
        let sample = """
        CARTOLA BANCO SECURITY
        SALDO INICIAL 1.000.000
        0000309768 7.980 COMPRA MERCADO URBANO TO 01/09 4.087.477
        1015910136 TRANSFERENCIA DESDE CHILE DE PERSONA 03/09 72.999 2.695.705
        """

        let parsed = try parser.parse(sample, sourceFileName: "sample.pdf")
        XCTAssertGreaterThanOrEqual(parsed.transactions.count, 2)
    }

    func testRecognizesDebitAndCreditClassification() throws {
        let parser = SecurityStatementParser()
        let sample = """
        CARTOLA BANCO SECURITY
        SALDO INICIAL 1.000.000
        0000309768 7.980 COMPRA MERCADO URBANO TO 01/09 4.087.477
        1015910136 TRANSFERENCIA DESDE CHILE DE PERSONA 03/09 72.999 2.695.705
        """

        let parsed = try parser.parse(sample, sourceFileName: "sample.pdf")
        XCTAssertTrue(parsed.transactions.allSatisfy { $0.resultingBalance > 0 })
    }

    func testAccountingValidation() throws {
        let validator = SecurityStatementValidator()
        let statement = ParsedStatement(
            statementNumber: "A-001",
            periodStart: Date(),
            periodEnd: Date(),
            issueDate: Date(),
            sourceFileName: "sample.pdf",
            openingBalance: 1_000_000,
            totalDebits: 200_000,
            totalCredits: 500_000,
            accountingBalance: 1_300_000,
            availableBalance: 1_300_000,
            totalFees: 0,
            transactions: [],
            warnings: [],
            importFingerprint: "abc123"
        )

        XCTAssertTrue(validator.isValid(statement))
    }
}
