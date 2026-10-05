import SwiftUI

public struct ImportStatementViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    @Published var previewData: ParsedStatement?
    @Published var importComplete = false
    @Published var importResult: String?

    public init() {}

    public func processURL(_ url: URL) {
        isLoading = true
        Task {
            do {
                let extractor = PDFTextExtractor()
                let text = try extractor.extractText(from: url)
                let parser = SecurityStatementParserV2()
                let parsed = try parser.parse(text, sourceFileName: url.lastPathComponent)

                await MainActor.run {
                    self.previewData = parsed
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}
