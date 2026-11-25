import CoreGraphics
import CoreText
import Foundation

enum TextPDFBuilder {
    static func write(pages: [String], sourceName: String, to output: URL) throws {
        var mediaBox = CGRect(x: 0, y: 0, width: 595, height: 842)
        guard let consumer = CGDataConsumer(url: output as CFURL),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }

        let bodyFont = CTFontCreateWithName("Helvetica" as CFString, 11.5, nil)
        let headingFont = CTFontCreateWithName("Helvetica-Bold" as CFString, 16, nil)
        let fontKey = NSAttributedString.Key(rawValue: kCTFontAttributeName as String)
        let fullText = NSMutableAttributedString()

        fullText.append(NSAttributedString(
            string: "Translation of \(sourceName)\n\n",
            attributes: [fontKey: headingFont]
        ))
        for (index, page) in pages.enumerated() {
            fullText.append(NSAttributedString(
                string: "Page \(index + 1)\n",
                attributes: [fontKey: headingFont]
            ))
            fullText.append(NSAttributedString(
                string: page + "\n\n",
                attributes: [fontKey: bodyFont]
            ))
        }

        let framesetter = CTFramesetterCreateWithAttributedString(fullText)
        var location = 0
        var outputPage = 1
        while location < fullText.length {
            context.beginPDFPage(nil)
            let frameRect = CGRect(x: 52, y: 58, width: mediaBox.width - 104, height: mediaBox.height - 116)
            let path = CGPath(rect: frameRect, transform: nil)
            let frame = CTFramesetterCreateFrame(
                framesetter,
                CFRange(location: location, length: 0),
                path,
                nil
            )
            CTFrameDraw(frame, context)

            context.saveGState()
            context.setFillColor(gray: 0.4, alpha: 1)
            let footer = "CaptureTranslator • \(outputPage)"
            let line = CTLineCreateWithAttributedString(NSAttributedString(
                string: footer,
                attributes: [fontKey: bodyFont]
            ))
            context.textPosition = CGPoint(x: 52, y: 30)
            CTLineDraw(line, context)
            context.restoreGState()

            let visible = CTFrameGetVisibleStringRange(frame)
            guard visible.length > 0 else { break }
            location += visible.length
            outputPage += 1
            context.endPDFPage()
        }
        context.closePDF()
    }
}
