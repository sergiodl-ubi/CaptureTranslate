# CaptureTranslator

CaptureTranslator is a privacy-oriented macOS 14+ menu-bar application that uses a local Ollama vision model to translate cropped screenshots and PDF documents.

## Features

- Global **⌘⌥⇧4** shortcut using macOS's native interactive capture selector.
- Side-by-side screenshot and editable translation view.
- Fit, button zoom, trackpad pinch, and **⌘ + scroll** zoom.
- Automatic retranslation when the target language changes.
- Configurable Ollama endpoint, model, source/target languages, and PDF rendering density.
- Configurable Finder folders with enable/disable checkboxes and add/remove controls.
- Finder contextual command for PDFs: **Translate this document**.
- Sequential PDF translation with selectable text output named like `Original.translated_ja_en.pdf`.

No screenshot, PDF page, or translation is sent to a cloud service unless the configured Ollama endpoint itself points to a remote server.

## Requirements

- macOS 14 or newer.
- Xcode 15 or newer.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) 2.47 or newer.
- Ollama with a vision-capable translation model.
- ImageMagick and Ghostscript for PDF rendering.

Install the command-line dependencies with Homebrew:

```bash
brew install xcodegen imagemagick ghostscript
brew upgrade xcodegen
ollama pull translategemma:12b
```

## Project identity and signing

The main app and Finder Sync extension communicate through an App Group. Before generating the Xcode project, review these two values near the top of `project.yml`:

```yaml
CAPTURE_TRANSLATOR_BUNDLE_PREFIX: com.ubi-lab
CAPTURE_TRANSLATOR_APP_GROUP: group.com.ubi-lab.CaptureTranslator
```

Lab members who sign with the same development team can use the lab's registered values. Someone signing with another Apple development team should replace both with identifiers unique to that team, for example:

```yaml
CAPTURE_TRANSLATOR_BUNDLE_PREFIX: com.example.sergio
CAPTURE_TRANSLATOR_APP_GROUP: group.com.example.sergio.CaptureTranslator
```

The resulting bundle identifiers are:

```text
<prefix>.CaptureTranslator
<prefix>.CaptureTranslator.FinderExtension
```

The App Group must be available to the selected development team. With automatic signing, Xcode may offer to register it or repair the signing configuration. If it does not, create the App Group in the Apple Developer account and enable it for both targets under **Signing & Capabilities**.

Do not give the main app the App Sandbox capability. It launches the system screenshot tool and the locally installed ImageMagick executable. The Finder extension is sandboxed independently.

## Generate the Xcode project

From the source directory:

```bash
make open
```

This runs `xcodegen generate` and opens `CaptureTranslator.xcodeproj`.

In Xcode:

1. Select the **CaptureTranslator** project.
2. Select the **CaptureTranslator** target and choose your Development Team.
3. Select **CaptureTranslatorFinderExtension** and choose the same Development Team.
4. Confirm that both targets show the same App Group under **Signing & Capabilities**.
5. Build the `CaptureTranslator` scheme.

The extension is embedded and signed as part of the main application. Command-line registration with `pluginkit` is not required.

## Install and enable the Finder extension

For reliable Finder extension discovery, install the built application rather than leaving it in Xcode's DerivedData folder:

1. In Xcode's Products group, Control-click `CaptureTranslator.app` and choose **Show in Finder**.
2. Drag `CaptureTranslator.app` into `/Applications`.
3. Launch the application once from `/Applications`.
4. Open CaptureTranslator's menu-bar menu and choose **Manage Finder Extension…**.
5. Enable CaptureTranslator in the Finder extensions interface.

Alternatively, open **System Settings → General → Login Items & Extensions → Finder** and enable CaptureTranslator there.

macOS requires this explicit user approval. The application cannot silently enable its own Finder extension.

## Configure Finder folders

Open **CaptureTranslator → Settings… → Finder**.

- Use **+** to select one or more folders.
- Use each checkbox to enable or temporarily disable monitoring.
- Select entries and use **−** to remove them.
- Missing folders are marked with a warning icon.

The default first-run folder is the current user's Downloads folder. Changes are sent to the running Finder extension immediately. The contextual command appears for PDF files inside enabled folders and their descendants.

Folder paths and enabled states are stored in the shared App Group preferences. The Finder extension does not read PDF contents; it only passes the selected path to the main application. PDF conversion and translation occur in the main application.

## First run

1. Start Ollama:

   ```bash
   ollama serve
   ```

2. Launch CaptureTranslator from `/Applications`.
3. Approve screen-capture access if macOS requests it.
4. Enable the Finder extension.
5. Confirm or add monitored folders in **Settings → Finder**.

CaptureTranslator appears in the menu bar rather than the Dock.

## Development notes

- The extension loads monitored folders at startup and listens for shared configuration changes through a Darwin notification.
- The main application intentionally remains outside App Sandbox for local executable and adjacent-output-file access.
- The Finder extension contains only the App Sandbox and App Group entitlements; it has no broad home-directory exception.
- The generated `.xcodeproj` is intentionally excluded from source control. Regenerate it after changing `project.yml`.

## Limitations

- The translated PDF contains selectable translated text in source-page order; it does not reconstruct the source layout.
- Language detection uses the first rendered page. If detection fails, the output filename uses `und`.
- Target-language changes in Settings affect new captures and PDF jobs, not already-open capture windows.
- Some ImageMagick installations use restrictive PDF security policies. Homebrew's ImageMagick plus Ghostscript normally works, but a custom policy may need adjustment.
- If a configured folder is moved or renamed, remove its stale entry and add the folder again.

## Privacy and temporary files

The default endpoint is `http://127.0.0.1:11434`. CaptureTranslator uses an ephemeral URL session and contains no analytics.

Screenshot captures are stored temporarily under `~/.capturetranslator/captures` and removed when their result window closes. PDF page images are kept in a per-job directory under `~/.capturetranslator/jobs` and removed when the job completes or fails.

## Troubleshooting extension discovery

Normal installation does not require command-line registration. If the extension does not appear:

1. Confirm the app is in `/Applications` and has been launched once.
2. Confirm both targets use the same Development Team and App Group.
3. Confirm the built extension exists at `CaptureTranslator.app/Contents/PlugIns/CaptureTranslatorFinderExtension.appex`.
4. Clean the build folder, rebuild, replace the installed application, and launch it again.
5. Use **Manage Finder Extension…** to reopen the system interface.

The extension only supplies a menu for PDFs inside enabled folders. Test with a PDF directly inside the default Downloads folder before investigating registration.
