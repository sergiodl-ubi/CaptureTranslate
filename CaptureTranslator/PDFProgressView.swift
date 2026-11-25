import AppKit
import SwiftUI

struct PDFProgressView: View {
    @ObservedObject var session: PDFProgressSession

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label(session.sourceURL.lastPathComponent, systemImage: "doc.richtext")
                .font(.headline)
                .lineLimit(1)

            Text(session.status)

            if session.totalPages > 0 {
                ProgressView(value: Double(session.completedPages), total: Double(session.totalPages))
            } else if case .working = session.state {
                ProgressView()
            }

            switch session.state {
            case .working:
                Text("Pages are processed sequentially to limit memory use.")
                    .font(.caption).foregroundStyle(.secondary)
            case .finished(let url):
                HStack {
                    Text(url.lastPathComponent).font(.caption).lineLimit(1)
                    Spacer()
                    Button("Reveal in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                }
            case .failed(let message):
                Text(message).foregroundStyle(.red).textSelection(.enabled)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
