import Foundation
import XCTest
@testable import CuentasClaras

final class SecurityBankParsingTests: XCTestCase {
    let parser = SecurityStatementParserV2()

    func testParsesSecuritySampleLine1() throws {
        let sample = """
        CARTOLA BANCO SECURITY - SALDOS Y MOVIMIENTOS
        Cuenta: 0001234567 (Corriente)
        Periodo: 01/09 al 30/09/2026
        Saldo inicial: 1.000.000
        0000309768 7.980 COMPRA MERCADO URBANO TO 01/09 4.087.477
        """

        let parsed = try parser.parse(sample, sourceFileName: "security-sample.pdf")
        XCTAssertEqual(parsed.statementNumber, "CARTOLA BANCO SECURITY - SALDOS Y MOVIMIENTOS")
        XCTAssertEqual(parsed.openingBalance, Decimal(1_000_000))
    }

    func testParsesSecuritySampleLine2() throws {
        let sample = """
        CARTOLA BANCO SECURITY
        Saldo inicial: 4.000.000
        1015910136 TRANSFERENCIA DESDE Chile DE PERSONA 03/09 72.999 2.695.705
        """

        let parsed = try parser.parse(sample, sourceFileName: "security-sample.pdf")
        XCTAssertGreaterThanOrEqual(parsed.transactions.count, 1)
    }

    func testClassifiesTransactionsAsDebitOrCredit() throws {
        let sample = """
        CARTOLA BANCO SECURITY
        Saldo inicial: 1.000.000
        0000309768 7.980 COMPRA MERCADO TO 01/09 950.020
        1015910136 TRANSFERENCIA DESDE CHILE 03/09 72.999 1.022.000
        """

        let parsed = try parser.parse(sample, sourceFileName: "test.pdf")
        let debits = parsed.transactions.filter { $0.debitAmount != nil }.count
        let credits = parsed.transactions.filter { $0.creditAmount != nil }.count
        XCTAssertGreaterThan(debits + credits, 0)
    }

    func testValidatesAccountingEquality() throws {
        let validator = SecurityStatementValidator()
        let statement = ParsedStatement(
            statementNumber: "SEC-001",
            periodStart: Date(),
            periodEnd: Date(),
            issueDate: Date(),
            sourceFileName: "test.pdf",
            openingBalance: 1_000_000,
            totalDebits: 49_980,
            totalCredits: 72_999,
            accountingBalance: 1_023_019,
            availableBalance: 1_023_019,
            totalFees: 0,
            transactions: [],
            warnings: [],
            importFingerprint: "abc123"
        )

        XCTAssertTrue(validator.isValid(statement))
    }

    func testDetectsDuplicates() throws {
        let fingerprint = FinancialHashing.statementFingerprint(
            fileName: "security-sample.pdf",
            issueDate: Date(),
            statementNumber: "SEC-001"
        )
        let fingerprint2 = FinancialHashing.statementFingerprint(
            fileName: "security-sample.pdf",
            issueDate: Date(),
            statementNumber: "SEC-001"
        )
        XCTAssertEqual(fingerprint, fingerprint2)
    }

    func testExtractsTransactionFingerprints() throws {
        let fp1 = FinancialHashing.transactionFingerprint(
            documentNumber: "0000309768",
            date: Date(),
            description: "COMPRA MERCADO URBANO TO",
            amount: Decimal(7980)
        )
        let fp2 = FinancialHashing.transactionFingerprint(
            documentNumber: "0000309768",
            date: Date(),
            description: "COMPRA MERCADO URBANO TO",
            amount: Decimal(7980)
        )
        XCTAssertEqual(fp1, fp2)
    }
}
