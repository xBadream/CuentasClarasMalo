import Foundation
import CryptoKit

public enum FinancialHashing {
    public static func sha256(_ value: String) -> String {
        let data = Data(value.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    public static func forBankStatement(fileName: String, issueDate: Date, statementNumber: String) -> String {
        let payload = "\(fileName)|\(issueDate.timeIntervalSince1970)|\(statementNumber)"
        return sha256(payload)
    }

    public static func forTransaction(documentNumber: String, amount: Decimal, date: Date, description: String) -> String {
        let normalized = "\(documentNumber)|\(NSDecimalNumber(decimal: amount).stringValue)|\(date.timeIntervalSince1970)|\(description)"
        return sha256(normalized)
    }
}
