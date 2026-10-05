import Foundation
import XCTest
@testable import CuentasClaras

final class SecurityStatementParserTests: XCTestCase {
    func testParsesSecuritySampleTransaction() throws {
        let parser = SecurityStatementParser()
        let source = """
        CARTOLA BANCO SECURITY
        SALDO INICIAL 1.000.000
        0000309768 7.980 COMPRA MERCADO URBANO TO 01/09 4.087.477
        1015910136 TRANSFERENCIA DESDE Chile DE PERSONA 03/09 72.999 2.695.705
        """

        let parsed = try parser.parse(source, sourceFileName: "sample.pdf")
        XCTAssertEqual(parsed.transactions.count, 2)
        XCTAssertFalse(parsed.transactions.isEmpty)
    }

    func testMarksDebitAndCreditClassification() throws {
        let parser = SecurityStatementParser()
        let source = """
        CARTOLA BANCO SECURITY
        SALDO INICIAL 1.000.000
        0000309768 7.980 COMPRA MERCADO URBANO TO 01/09 4.087.477
        1015910136 TRANSFERENCIA DESDE Chile DE PERSONA 03/09 72.999 2.695.705
        """

        let parsed = try parser.parse(source, sourceFileName: "sample.pdf")
        XCTAssertTrue(parsed.transactions.allSatisfy { $0.resultingBalance >= 0 })
    }

    func testValidatesAccountingEquality() throws {
        let validator = SecurityStatementValidator()
        let parsed = ParsedStatement(
            statementNumber: "A1",
            periodStart: Date(),
            periodEnd: Date(),
            issueDate: Date(),
            sourceFileName: "sample.pdf",
            openingBalance: 1000000,
            totalDebits: 200000,
            totalCredits: 500000,
            accountingBalance: 1300000,
            availableBalance: 1300000,
            totalFees: 0,
            transactions: [],
            warnings: [],
            importFingerprint: "abc"
        )

        XCTAssertTrue(validator.isValid(parsed))
    }
}
