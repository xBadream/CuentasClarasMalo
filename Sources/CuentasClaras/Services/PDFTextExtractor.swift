import Foundation

public final class PDFTextExtractor {
    public init() {}

    public func extractText(from pdfData: Data) -> String {
        return String(data: pdfData, encoding: .utf8) ?? PDFTextExtractor.fallbackText(from: pdfData)
    }

    public func extractText(from url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        return extractText(from: data)
    }

    private static func fallbackText(from data: Data) -> String {
        let text = String(decoding: data, as: UTF8.self)
        if text.isEmpty {
            return "" 
        }
        return text
    }
}
