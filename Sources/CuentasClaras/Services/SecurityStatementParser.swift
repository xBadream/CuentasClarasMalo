import Foundation

public enum SecurityStatementParserError: Error {
    case invalidFormat
    case missingStatementNumber
}

public final class SecurityStatementParser {
    public init() {}

    public func parse(_ text: String, sourceFileName: String) throws -> ParsedStatement {
        let cleanText = normalize(text)
        let lines = cleanText.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !lines.isEmpty else { throw SecurityStatementParserError.invalidFormat }

        let statementNumber = extractStatementNumber(from: lines) ?? "SEC-UNKNOWN"
        let periodStart = extractDate(from: lines, prefix: "Periodo") ?? Date()
        let periodEnd = extractDate(from: lines, prefix: "Hasta") ?? Date()
        let issueDate = extractIssueDate(from: lines) ?? Date()
        let openingBalance = extractOpeningBalance(from: lines) ?? 0
        let transactions = parseTransactions(from: lines)
        let totalDebits = transactions.compactMap { $0.debitAmount }.reduce(0, +)
        let totalCredits = transactions.compactMap { $0.creditAmount }.reduce(0, +)
        let accountingBalance = openingBalance + totalCredits - totalDebits
        let availableBalance = accountingBalance
        let totalFees: Decimal = 0
        let warnings: [String] = transactions.filter { $0.requiresReview }.map { $0.transactionDescription }

        let fingerprint = FinancialHashing.forBankStatement(fileName: sourceFileName, issueDate: issueDate, statementNumber: statementNumber)

        return ParsedStatement(
            statementNumber: statementNumber,
            periodStart: periodStart,
            periodEnd: periodEnd,
            issueDate: issueDate,
            sourceFileName: sourceFileName,
            openingBalance: openingBalance,
            totalDebits: totalDebits,
            totalCredits: totalCredits,
            accountingBalance: accountingBalance,
            availableBalance: availableBalance,
            totalFees: totalFees,
            transactions: transactions,
            warnings: warnings,
            importFingerprint: fingerprint
        )
    }

    private func normalize(_ text: String) -> String {
        text.replacingOccurrences(of: "\r", with: "\n")
    }

    private func extractStatementNumber(from lines: [String]) -> String? {
        for line in lines {
            if line.contains("CARTOLA") || line.contains("ESTADO") || line.contains("CUENTA") {
                return line
            }
        }
        return nil
    }

    private func extractDate(from lines: [String], prefix: String) -> Date? {
        for line in lines {
            let lowered = line.lowercased()
            if lowered.contains(prefix.lowercased()) {
                let match = extractFirstDate(in: line)
                if let date = match { return date }
            }
        }
        return nil
    }

    private func extractIssueDate(from lines: [String]) -> Date? {
        for line in lines {
            if let date = extractFirstDate(in: line) {
                return date
            }
        }
        return nil
    }

    private func extractOpeningBalance(from lines: [String]) -> Decimal? {
        for line in lines {
            if line.lowercased().contains("saldo inicial") || line.lowercased().contains("saldoinicial") {
                if let value = extractDecimal(from: line) {
                    return value
                }
            }
        }
        return 0
    }

    private func parseTransactions(from lines: [String]) -> [ParsedTransaction] {
        var parsed: [ParsedTransaction] = []
        for (index, line) in lines.enumerated() {
            guard !line.contains("SALDO") && !line.contains("TOTAL") else { continue }
            guard let match = parseTransactionLine(line) else { continue }
            let fingerprint = FinancialHashing.forTransaction(
                documentNumber: match.documentNumber,
                amount: match.debitAmount ?? match.creditAmount ?? 0,
                date: match.date,
                description: match.transactionDescription
            )
            parsed.append(ParsedTransaction(
                date: match.date,
                documentNumber: match.documentNumber,
                transactionDescription: match.transactionDescription,
                debitAmount: match.debitAmount,
                creditAmount: match.creditAmount,
                resultingBalance: match.resultingBalance,
                parserConfidence: match.parserConfidence,
                sourcePage: 1,
                sourceRawText: line,
                requiresReview: match.requiresReview,
                categoryName: nil,
                importFingerprint: fingerprint
            ))
        }
        return parsed
    }

    private func parseTransactionLine(_ line: String) -> (date: Date, documentNumber: String, transactionDescription: String, debitAmount: Decimal?, creditAmount: Decimal?, resultingBalance: Decimal, parserConfidence: Double, requiresReview: Bool)? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let tokens = trimmed.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard tokens.count >= 3 else { return nil }

        let documentNumber = tokens[0]
        let dateValue = dateFromToken(tokens: tokens) ?? Date()
        let amount = extractAmount(from: tokens)
        let balance = extractBalance(from: tokens) ?? 0
        let description = descriptionFromTokens(tokens: tokens)

        let parsedAmount = amount
        let credit: Decimal?
        let debit: Decimal?

        if let rawAmount = parsedAmount {
            if rawAmount >= 0 {
                if balance >= 0 {
                    credit = rawAmount
                    debit = nil
                } else {
                    debit = rawAmount
                    credit = nil
                }
            } else {
                debit = rawAmount.magnitude
                credit = nil
            }
        } else {
            credit = nil
            debit = nil
        }

        let confidence = 0.98
        let requiresReview = false

        return (
            dateValue,
            documentNumber,
            description,
            debit,
            credit,
            balance,
            confidence,
            requiresReview
        )
    }

    private func descriptionFromTokens(tokens: [String]) -> String {
        let dateIndices = tokens.indices.filter { isDateToken(tokens[$0]) }
        let start = 1
        let end = dateIndices.first ?? tokens.count - 1
        let substring = Array(tokens[start..<min(end, tokens.count)])
        return substring.joined(separator: " ")
    }

    private func dateFromToken(tokens: [String]) -> Date? {
        for token in tokens {
            if isDateToken(token) {
                return parseDate(token)
            }
        }
        return nil
    }

    private func extractAmount(from tokens: [String]) -> Decimal? {
        for token in tokens {
            if token.contains(".") && token.filter({ $0 == "." }).count <= 2 {
                if let decimal = Decimal(string: token.replacingOccurrences(of: ".", with: "")) {
                    if decimal > 0 && !token.contains("/") {
                        return decimal / 1000
                    }
                }
            }
        }
        return nil
    }

    private func extractBalance(from tokens: [String]) -> Decimal? {
        for token in tokens.reversed() {
            if token.contains(".") && token.filter({ $0 == "." }).count <= 2 {
                if let value = Decimal(string: token.replacingOccurrences(of: ".", with: "")) {
                    return value / 1000
                }
            }
        }
        return nil
    }

    private func extractDecimal(from line: String) -> Decimal? {
        let pattern = #"(\d{1,3}(\.\d{3})*|\d+)(,\d+)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }
        let raw = (line as NSString).substring(with: match.range)
        let sanitized = raw.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        return Decimal(string: sanitized)
    }

    private func isDateToken(_ value: String) -> Bool {
        let pattern = "^\\d{2}/\\d{2}$"
        return value.range(of: pattern, options: .regularExpression) != nil
    }

    private func parseDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_CL")
        formatter.dateFormat = "dd/MM"
        return formatter.date(from: value)
    }
}
