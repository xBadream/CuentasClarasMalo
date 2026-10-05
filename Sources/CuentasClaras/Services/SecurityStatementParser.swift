import Foundation

public enum SecurityStatementParserError: Error {
    case invalidFormat
    case missingStatementNumber
}

public final class SecurityStatementParser {
    public init() {}

    public func parse(_ text: String, sourceFileName: String) throws -> ParsedStatement {
        let normalized = normalize(text)
        let lines = normalized
            .split(whereSeparator: { $0.isNewline })
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        guard !lines.isEmpty else {
            throw SecurityStatementParserError.invalidFormat
        }

        let issueDate = extractIssueDate(from: lines) ?? Date()
        let statementNumber = extractStatementNumber(from: lines) ?? "SEC-UNKNOWN"
        let periodStart = extractPeriodStart(from: lines) ?? issueDate
        let periodEnd = extractPeriodEnd(from: lines) ?? issueDate
        let openingBalance = extractOpeningBalance(from: lines) ?? Decimal.zero

        var runningBalance = openingBalance
        var parsedTransactions: [ParsedTransaction] = []
        var warnings: [String] = []

        for line in lines {
            guard let candidate = parseTransactionLine(line) else { continue }
            let previousBalance = runningBalance
            let currentBalance = candidate.resultingBalance
            let delta = currentBalance - previousBalance
            let amount = abs(candidate.creditAmount ?? candidate.debitAmount ?? Decimal.zero)

            let effectiveCredit: Decimal?
            let effectiveDebit: Decimal?
            if previousBalance + amount == currentBalance {
                effectiveCredit = amount
                effectiveDebit = nil
            } else if previousBalance - amount == currentBalance {
                effectiveDebit = amount
                effectiveCredit = nil
            } else {
                effectiveCredit = candidate.creditAmount
                effectiveDebit = candidate.debitAmount
            }

            let confidence = (previousBalance + amount == currentBalance || previousBalance - amount == currentBalance) ? 0.98 : 0.72
            let requiresReview = confidence < 1.0 || (candidate.creditAmount == nil && candidate.debitAmount == nil)
            if requiresReview { warnings.append(candidate.transactionDescription) }

            let fingerprint = FinancialHashing.transactionFingerprint(
                documentNumber: candidate.documentNumber,
                date: candidate.date,
                description: candidate.transactionDescription,
                amount: amount
            )

            let transaction = ParsedTransaction(
                date: candidate.date,
                documentNumber: candidate.documentNumber,
                transactionDescription: candidate.transactionDescription,
                debitAmount: effectiveDebit,
                creditAmount: effectiveCredit,
                resultingBalance: currentBalance,
                parserConfidence: confidence,
                sourcePage: 1,
                sourceRawText: line,
                categoryName: nil,
                requiresReview: requiresReview,
                importFingerprint: fingerprint
            )

            parsedTransactions.append(transaction)
            runningBalance = currentBalance
        }

        let totalDebits = parsedTransactions.compactMap { $0.debitAmount }.reduce(Decimal.zero, +)
        let totalCredits = parsedTransactions.compactMap { $0.creditAmount }.reduce(Decimal.zero, +)
        let accountingBalance = openingBalance + totalCredits - totalDebits
        let availableBalance = accountingBalance
        let fingerprint = FinancialHashing.statementFingerprint(fileName: sourceFileName, issueDate: issueDate, statementNumber: statementNumber)

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
            totalFees: Decimal.zero,
            transactions: parsedTransactions,
            warnings: warnings,
            importFingerprint: fingerprint
        )
    }

    private func normalize(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }

    private func extractStatementNumber(from lines: [String]) -> String? {
        for line in lines {
            let lowercase = line.lowercased()
            if lowercase.contains("cartola") || lowercase.contains("cuenta") || lowercase.contains("estado") {
                return line
            }
        }
        return nil
    }

    private func extractIssueDate(from lines: [String]) -> Date? {
        for line in lines {
            if let date = extractDates(in: line).first { return date }
        }
        return nil
    }

    private func extractPeriodStart(from lines: [String]) -> Date? {
        for line in lines {
            if line.lowercased().contains("periodo") || line.lowercased().contains("desde") {
                if let date = extractDates(in: line).first { return date }
            }
        }
        return nil
    }

    private func extractPeriodEnd(from lines: [String]) -> Date? {
        for line in lines {
            if line.lowercased().contains("hasta") || line.lowercased().contains("al") {
                if let date = extractDates(in: line).last { return date }
            }
        }
        return nil
    }

    private func extractOpeningBalance(from lines: [String]) -> Decimal? {
        for line in lines {
            let lowercase = line.lowercased()
            if lowercase.contains("saldo inicial") || lowercase.contains("saldoinicial") {
                return extractAmount(from: line)
            }
        }
        return Decimal.zero
    }

    private func parseTransactionLine(_ line: String) -> (date: Date, documentNumber: String, transactionDescription: String, creditAmount: Decimal?, debitAmount: Decimal?, resultingBalance: Decimal)? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let tokens = trimmed.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard tokens.count >= 3 else { return nil }

        let documentNumber = tokens[0]
        guard documentNumber.range(of: "^[0-9]+$", options: .regularExpression) != nil else { return nil }

        guard let dateToken = tokens.first(where: { $0.range(of: "^\\d{2}/\\d{2}$", options: .regularExpression) != nil }) else {
            return nil
        }

        guard let date = parseDate(from: dateToken) else { return nil }

        let amountBeforeDate = tokens.prefix { $0 != dateToken }
        let amountAfterDate = tokens.drop(while: { $0 != dateToken }).dropFirst()
        let candidateAmount = self.amountToken(in: tokens, around: dateToken)
        let candidateBalance = self.balanceToken(in: tokens)

        let descriptionParts = self.descriptionTokens(in: tokens, dateToken: dateToken)
        let description = descriptionParts.joined(separator: " ")

        let amount = candidateAmount ?? Decimal.zero
        let balance = candidateBalance ?? Decimal.zero

        if description.isEmpty || description == documentNumber {
            return nil
        }

        let transactionAmount: Decimal?
        let credit: Decimal?
        let debit: Decimal?

        if amount > 0 {
            transactionAmount = amount
            credit = amount
            debit = nil
        } else {
            transactionAmount = nil
            credit = nil
            debit = nil
        }

        if transactionAmount == nil {
            return (
                date,
                documentNumber,
                description,
                nil,
                nil,
                balance
            )
        }

        return (
            date,
            documentNumber,
            description,
            credit,
            debit,
            balance
        )
    }

    private func descriptionTokens(in tokens: [String], dateToken: String) -> [String] {
        var parts: [String] = []
        var seenDate = false
        for token in tokens {
            if token == dateToken {
                seenDate = true
                continue
            }
            if seenDate {
                if isNumericAmountToken(token) { continue }
                parts.append(token)
            } else {
                if token == tokens.first { continue }
                if isNumericAmountToken(token) { continue }
                parts.append(token)
            }
        }
        return parts
    }

    private func amountToken(in tokens: [String], around dateToken: String) -> Decimal? {
        let dateIndex = tokens.firstIndex(of: dateToken) ?? 0
        let beforeDate = Array(tokens.prefix(upTo: dateIndex))
        let afterDate = Array(tokens.suffix(from: dateIndex + 1))

        if let amount = extractAmount(from: beforeDate.joined(separator: " ")) {
            return amount
        }
        if let amount = extractAmount(from: afterDate.joined(separator: " ")) {
            return amount
        }
        return nil
    }

    private func balanceToken(in tokens: [String]) -> Decimal? {
        let text = tokens.joined(separator: " ")
        return extractLastAmount(in: text)
    }

    private func extractDates(in line: String) -> [Date] {
        let regex = try? NSRegularExpression(pattern: "\\b\\d{2}/\\d{2}(?:/\\d{4})?\\b")
        guard let matches = regex?.matches(in: line, range: NSRange(line.startIndex..., in: line)) else { return [] }

        var results: [Date] = []
        for match in matches {
            let raw = (line as NSString).substring(with: match.range)
            if let date = parseDate(from: raw) { results.append(date) }
        }
        return results
    }

    private func extractAmount(from text: String) -> Decimal? {
        let pattern = #"\d{1,3}(?:\.\d{3})*(?:,\d+)?|\d+(?:,\d+)?"#
        let regex = try? NSRegularExpression(pattern: pattern)
        guard let matches = regex?.matches(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
        for match in matches.reversed() {
            let raw = (text as NSString).substring(with: match.range)
            let sanitized = raw.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
            if let value = Decimal(string: sanitized), value > 0 {
                return value
            }
        }
        return nil
    }

    private func extractLastAmount(in text: String) -> Decimal? {
        let pattern = #"\d{1,3}(?:\.\d{3})*(?:,\d+)?|\d+(?:,\d+)?"#
        let regex = try? NSRegularExpression(pattern: pattern)
        guard let matches = regex?.matches(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
        for match in matches.reversed() {
            let raw = (text as NSString).substring(with: match.range)
            let sanitized = raw.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
            if let value = Decimal(string: sanitized), value > 0 {
                return value
            }
        }
        return nil
    }

    private func isNumericAmountToken(_ token: String) -> Bool {
        let sanitized = token.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        return Decimal(string: sanitized) != nil
    }

    private func parseDate(from raw: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_CL")
        formatter.timeZone = TimeZone(secondsFromGMT: -3 * 3600)
        let formats = ["dd/MM", "dd/MM/yyyy"]
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: raw) { return date }
        }
        return nil
    }
}
