import Foundation
#if canImport(PDFKit)
import PDFKit
#endif

public final class PDFTextExtractor {
    public init() {}

    public func extractText(from data: Data) -> String {
        #if canImport(PDFKit)
        if let document = PDFDocument(data: data) {
            var text = ""
            for pageIndex in 0..<document.pageCount {
                if let page = document.page(at: pageIndex), let content = page.string {
                    text += "\n" + content
                }
            }
            if !text.isEmpty { return text }
        }
        #endif

        return String(decoding: data, as: UTF8.self)
    }

    public func extractText(from url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        return extractText(from: data)
    }
}
