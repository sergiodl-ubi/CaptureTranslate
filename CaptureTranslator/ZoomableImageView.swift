import AppKit
import SwiftUI

struct ZoomableImageView: NSViewRepresentable {
    let image: NSImage
    @Binding var zoom: Double
    let fitRequest: Int

    func makeCoordinator() -> Coordinator { Coordinator(zoom: $zoom) }

    func makeNSView(context: Context) -> CommandZoomScrollView {
        let scroll = CommandZoomScrollView()
        scroll.drawsBackground = true
        scroll.backgroundColor = .windowBackgroundColor
        scroll.hasHorizontalScroller = true
        scroll.hasVerticalScroller = true
        scroll.allowsMagnification = true
        scroll.minMagnification = 0.05
        scroll.maxMagnification = 8
        scroll.zoomDidChange = { context.coordinator.setZoom($0) }

        let imageView = NSImageView(image: image)
        imageView.imageScaling = .scaleNone
        imageView.imageAlignment = .alignCenter
        imageView.frame = NSRect(origin: .zero, size: image.size)
        scroll.documentView = imageView
        context.coordinator.imageView = imageView
        context.coordinator.scrollView = scroll
        return scroll
    }

    func updateNSView(_ scroll: CommandZoomScrollView, context: Context) {
        if abs(scroll.magnification - zoom) > 0.001 {
            scroll.setMagnification(zoom, centeredAt: centerPoint(in: scroll))
        }
        if context.coordinator.lastFitRequest != fitRequest {
            context.coordinator.lastFitRequest = fitRequest
            DispatchQueue.main.async { context.coordinator.fit() }
        }
    }

    private func centerPoint(in scroll: NSScrollView) -> NSPoint {
        NSPoint(x: scroll.documentVisibleRect.midX, y: scroll.documentVisibleRect.midY)
    }

    final class Coordinator {
        var zoom: Binding<Double>
        weak var imageView: NSImageView?
        weak var scrollView: NSScrollView?
        var lastFitRequest = -1

        init(zoom: Binding<Double>) { self.zoom = zoom }

        func setZoom(_ value: Double) {
            DispatchQueue.main.async { self.zoom.wrappedValue = value }
        }

        func fit() {
            guard let scrollView, let imageView else { return }
            let available = scrollView.contentSize
            let size = imageView.image?.size ?? imageView.frame.size
            guard size.width > 0, size.height > 0 else { return }
            let fitted = min(available.width / size.width, available.height / size.height, 1.0)
            scrollView.magnification = fitted
            zoom.wrappedValue = fitted
        }
    }
}

final class CommandZoomScrollView: NSScrollView {
    var zoomDidChange: ((Double) -> Void)?

    override func scrollWheel(with event: NSEvent) {
        guard event.modifierFlags.contains(.command) else {
            super.scrollWheel(with: event)
            return
        }
        let factor = exp(-event.scrollingDeltaY * 0.012)
        let next = min(max(magnification * factor, minMagnification), maxMagnification)
        let point = documentVisibleRect.center
        setMagnification(next, centeredAt: point)
        zoomDidChange?(next)
    }

    override func magnify(with event: NSEvent) {
        super.magnify(with: event)
        zoomDidChange?(magnification)
    }
}

private extension NSRect {
    var center: NSPoint { NSPoint(x: midX, y: midY) }
}
