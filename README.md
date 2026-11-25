# CaptureTranslator

A privacy-oriented macOS 14+ menu-bar prototype that sends cropped screenshots and rendered PDF pages to a local Ollama vision model.

## Current features

- Global **⌘⌥⇧4** shortcut using macOS's interactive `screencapture` selector.
- Captures stored temporarily under `~/.capturetranslator/captures` and removed when their result window closes.
- Side-by-side image and editable translation window.
- Fit, zoom buttons, trackpad pinch, and **⌘ + scroll** zoom.
- Target-language changes automatically cancel the obsolete request and start a new one.
- Configurable Ollama URL, model, default source/target languages, and PDF rendering density.
- Finder Sync command for PDFs: **Translate this document**.
- Sequential PDF page translation through ImageMagick, producing a selectable text PDF named:

  `Original.translated_ja_en.pdf`

## Prerequisites

1. macOS 14 or newer and Xcode 15 or newer.
2. Ollama running locally with the model installed:

   ```bash
   ollama pull translategemma:12b
   ```

3. XcodeGen:

   ```bash
   brew install xcodegen
   ```

4. For PDF translation, ImageMagick and Ghostscript:

   ```bash
   brew install imagemagick ghostscript
   ```

## Generate and run the project

```bash
cd CaptureTranslator
make open
```

In Xcode:

1. Select the **CaptureTranslator** project.
2. Assign your Development Team to both targets.
3. Replace the example bundle identifiers if Xcode reports a conflict.
4. Build and run the `CaptureTranslator` scheme.
5. Approve screen-capture access if macOS requests it.
6. Enable **CaptureTranslatorFinderExtension** under **System Settings → General → Login Items & Extensions → Finder**.

The application is an agent app, so it appears in the menu bar rather than the Dock.

## Prototype limitations

- Finder Sync only receives callbacks for monitored folders. This prototype monitors the user's home directory, which covers ordinary Documents, Desktop, and Downloads locations. External volumes are not included.
- The output PDF contains selectable translated text in source-page order; it does not reconstruct the source layout.
- Language detection uses the first rendered page. If detection does not yield a two-letter code, the filename uses `und`.
- Changing the target language in Settings affects new captures and PDF jobs, not already-open capture windows.
- ImageMagick installations can have restrictive PDF security policies. Homebrew's ImageMagick plus Ghostscript normally works, but a custom policy may need adjustment.
- The prototype is intentionally not sandboxed because it launches `screencapture`/`magick` and writes beside Finder-selected PDFs. Hardened distribution would need security-scoped bookmarks or a privileged helper design.

## Privacy

The client only calls the configured Ollama URL. Its default is `http://127.0.0.1:11434`. It uses an ephemeral URL session and does not include analytics. PDF page images are kept in a per-job temporary folder under `~/.capturetranslator/jobs` and deleted after the job completes or fails.
