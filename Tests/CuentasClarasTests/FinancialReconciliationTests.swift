import Foundation
import XCTest
@testable import CuentasClaras

final class FinancialReconciliationTests: XCTestCase {
    let reconciler = FinancialReconciliationEngine()

    func testReconciliationSucceedsWithValidBalance() {
        let statement = ParsedStatement(
            statementNumber: "SEC-001",
            periodStart: Date(),
            periodEnd: Date(),
            issueDate: Date(),
            sourceFileName: "test.pdf",
            openingBalance: 1_000_000,
            totalDebits: 120_000,
            totalCredits: 315_000,
            accountingBalance: 1_195_000,
            availableBalance: 1_195_000,
            totalFees: 0,
            transactions: [],
            warnings: [],
            importFingerprint: "abc123"
        )

        let result = reconciler.reconcile(statement)
        XCTAssertTrue(result.isValid)
        XCTAssertGreaterThan(result.confidence, 0.95)
    }

    func testReconciliationFailsWithMismatchedBalance() {
        let statement = ParsedStatement(
            statementNumber: "SEC-001",
            periodStart: Date(),
            periodEnd: Date(),
            issueDate: Date(),
            sourceFileName: "test.pdf",
            openingBalance: 1_000_000,
            totalDebits: 120_000,
            totalCredits: 315_000,
            accountingBalance: 999_999,
            availableBalance: 999_999,
            totalFees: 0,
            transactions: [],
            warnings: [],
            importFingerprint: "abc123"
        )

        let result = reconciler.reconcile(statement)
        XCTAssertFalse(result.isValid)
        XCTAssertGreaterThan(result.issues.count, 0)
    }
}
